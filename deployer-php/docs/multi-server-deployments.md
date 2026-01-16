# Multi-Server Deployments

Architectural exploration for adding multi-server deployment support to DeployerPHP.

## Design Decisions

1. **Same code on all servers** - One repo, one branch, deploy everywhere
2. **Parallel execution with atomic switchover** - Build on all servers, only switch symlinks after ALL builds succeed
3. **Keep successful builds until all succeed** - No partial rollbacks during build phase
4. **Shared state is user's responsibility** - We deploy PHP projects; sessions, uploads, database are external concerns

## Current Architecture Constraints

### Data Model is Single-Server

```php
// Current SiteDTO - hardcoded to one server
public readonly string $server;  // "production", not ["web1", "web2"]
```

The entire flow assumes this:

- `SiteRepository::findByDomain()` returns one site with one server
- `SiteDeployCommand` resolves that single server via `ServerRepository`
- Playbook execution targets one host

### SSH Execution is Blocking

`SshService::executeCommand()` blocks until the remote command completes (default 300s timeout). No async/parallel execution capability exists currently.

---

## Two-Phase Commit Pattern

```
Phase 1: BUILD (parallel, can fail)
┌─────────────┬─────────────┬─────────────┐
│   web1      │   web2      │   web3      │
├─────────────┼─────────────┼─────────────┤
│ git clone   │ git clone   │ git clone   │
│ composer    │ composer    │ composer    │
│ npm build   │ npm build   │ npm build   │
│ ✅ ready    │ ✅ ready    │ ✅ ready    │
└─────────────┴─────────────┴─────────────┘
        │             │             │
        └─────────────┼─────────────┘
                      ▼
              All succeeded?
                      │
         ┌────────────┴────────────┐
         ▼                         ▼
        YES                        NO
         │                         │
         ▼                         ▼
Phase 2: SWITCH              Keep old release
(sequential is fine)         Report which failed
┌─────────────┐              Builds stay for retry
│ ln -sfn web1│
│ ln -sfn web2│
│ ln -sfn web3│
└─────────────┘
```

The build phase is where failures happen (network issues, composer conflicts, npm errors). The switch phase is just a symlink—atomic at the filesystem level, takes milliseconds.

---

## Playbook Restructuring

Split the current single playbook into two phases:

```bash
# playbooks/site/deploy-build.sh (Phase 1)
# - Clone/pull to releases/{{timestamp}}
# - composer install
# - npm run build
# - Run hooks
# - Exit 0 if ready, non-zero if failed
# Does NOT switch symlink

# playbooks/site/deploy-switch.sh (Phase 2)
# - ln -sfn releases/{{timestamp}} current
# - Reload PHP-FPM (optional)
# - Cleanup old releases
# Fast, idempotent, almost never fails
```

---

## Implementation Approach

### Parallel Execution via Process Forking

```php
// Conceptual flow in SiteDeployMultiCommand
$releaseId = date('YmdHis');
$results = [];

// Phase 1: Fork build processes
$pids = [];
foreach ($servers as $server) {
    $pid = pcntl_fork();
    if ($pid === 0) {
        // Child process - run build
        $result = $this->ssh->executePlaybook($server, 'deploy-build', [
            'release_id' => $releaseId,
            'domain' => $site->domain,
        ]);
        exit($result['exit_code']);
    }
    $pids[$server->name] = $pid;
}

// Wait for all children
foreach ($pids as $serverName => $pid) {
    pcntl_waitpid($pid, $status);
    $results[$serverName] = pcntl_wexitstatus($status);
}

// Phase 2: Switch only if all succeeded
if (array_sum($results) === 0) {
    foreach ($servers as $server) {
        $this->ssh->executePlaybook($server, 'deploy-switch', [
            'release_id' => $releaseId,
        ]);
    }
}
```

### Output Handling for Parallel Builds

With parallel execution, output from multiple servers interleaves chaotically.

**Recommended approach:** Buffer per-server, display after completion.

```php
$outputs = [];
foreach ($servers as $server) {
    $outputs[$server->name] = $this->executeWithCapture($server, ...);
}
// Display sequentially after all complete
```

### Shared Release ID

All servers must use the same release directory name. Generate on the deployer machine, pass to all servers:

```php
$releaseId = date('YmdHis');  // e.g., "20250115143022"

// All servers get:
// /var/www/example.com/releases/20250115143022/
```

---

## Data Model Changes

Minimal changes needed:

```php
// SiteDTO - add optional servers array
public readonly string $server;       // Keep for backward compat
public readonly ?array $servers;      // ["web1", "web2"] for multi-server

// Helper method
public function getTargetServers(): array
{
    return $this->servers ?? [$this->server];
}
```

```php
// SiteBuilder addition
public function servers(array $servers): self
{
    $this->servers = $servers;
    return $this;
}
```

---

## Gotchas & Mitigations

### Release Directory Must Pre-exist for Switch

If Phase 1 fails on web2, that server won't have the release directory. Track build state for retry:

```php
$buildState = [
    'release_id' => '20250115143022',
    'servers' => [
        'web1' => 'built',
        'web2' => 'failed',
        'web3' => 'built',
    ],
];
```

### Clock Skew Between Servers

Generate release ID on the **deployer machine**, pass it to all servers. Don't rely on server-side timestamps.

### pcntl Not Available Everywhere

`pcntl_fork` requires the pcntl extension and doesn't work on Windows.

- Check for extension: `if (!function_exists('pcntl_fork'))`
- Fall back to sequential execution with warning
- Or use Symfony Process component for cross-platform subprocess handling

### Memory Usage with Many Servers

Each forked process duplicates memory. Limit concurrent forks (e.g., max 5 at a time) or use a worker pool pattern.

---

## Command Interface

```bash
# Single server (existing behavior)
deployer site:deploy example.com

# Multi-server (new command or flag)
deployer site:deploy example.com --servers=web1,web2,web3

# With server group (future enhancement)
deployer site:deploy example.com --group=production
```

Non-interactive replay:

```bash
deployer site:deploy example.com \
    --repo=git@github.com:user/repo.git \
    --branch=main \
    --servers=web1,web2,web3 \
    --yes
```

---

## Implementation Phases

| Phase | Scope | Risk | Description |
|-------|-------|------|-------------|
| 1 | Playbook split | Low | Separate build/switch playbooks |
| 2 | Schema | Low | Add `SiteDTO.servers` field |
| 3 | Sequential multi-server | Medium | New command with two-phase pattern |
| 4 | Parallel execution | Medium | Add pcntl_fork support |
| 5 | Output polish | Low | Buffered per-server display |

Phase 3 (sequential) already provides the atomic two-phase pattern—just slower. Parallelism in Phase 4 is an optimization.

---

## Future Considerations

- **Server groups**: Named collections of servers (e.g., "production", "staging")
- **Deployment strategies**: Canary releases, rolling updates
- **Health checks**: Verify application health before switching
- **Deployment history**: Track which servers have which releases
