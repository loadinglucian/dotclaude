# Schematic: MemcachedStartCommand.php

> Auto-generated schematic. Last updated: 2025-12-19

## Overview

`MemcachedStartCommand` starts the Memcached service on a remote server. It executes the `memcached-service` playbook with `DEPLOYER_ACTION=start`, then verifies the service is running before reporting success.

## Logic Flow

### Entry Points

| Method | Visibility | Description |
|--------|------------|-------------|
| `configure()` | protected | Registers `--server` CLI option |
| `execute()` | protected | Main execution - selects server, starts service |

### Execution Flow

```
1. execute()
   |
   +-- Display heading "Start Memcached Service"
   |
   +-- selectServerDeets() [ServersTrait]
   |   |-- ensureServersAvailable()
   |   |-- Prompt/validate server selection
   |   +-- getServerInfo() -> runs server-info playbook
   |
   +-- Check: is_int($server) || null === $server->info
   |   |-- True: return FAILURE
   |
   +-- executePlaybookSilently(server, 'memcached-service', 'Starting...', {DEPLOYER_ACTION: 'start'})
   |   |-- SSH to server, execute playbook silently
   |   |-- Parse YAML output
   |
   +-- Check: is_int($result)
   |   |-- True: nay("Failed to start Memcached service"), return FAILURE
   |
   +-- yay("Memcached service started")
   |
   +-- commandReplay('memcached:start', ['server' => $server->name])
   |
   +-- return SUCCESS
```

### Decision Points

| Location | Condition | True Branch | False Branch |
|----------|-----------|-------------|--------------|
| Line 52 | `is_int($server) \|\| null === $server->info` | Return FAILURE | Continue |
| Line 69 | `is_int($result)` | Display error, return FAILURE | Continue with success |

### Exit Conditions

| Exit Point | Condition | Return Value |
|------------|-----------|--------------|
| Line 53 | Server selection failed or no info | `Command::FAILURE` |
| Line 72 | Playbook execution failed | `Command::FAILURE` |
| Line 85 | Success | `Command::SUCCESS` |

## Interaction Diagram

```mermaid
flowchart TD
    subgraph Command["MemcachedStartCommand"]
        execute["execute()"]
    end

    subgraph Traits["Traits"]
        ServersTrait["ServersTrait"]
        PlaybooksTrait["PlaybooksTrait"]
    end

    subgraph Playbooks["Remote Execution"]
        MemcachedService["memcached-service.sh"]
    end

    subgraph Remote["Remote Server"]
        Systemctl["systemctl start memcached"]
    end

    execute --> ServersTrait
    execute --> PlaybooksTrait
    PlaybooksTrait -->|DEPLOYER_ACTION=start| MemcachedService
    MemcachedService --> Systemctl
```

## Dependencies

### Direct Imports

| File/Class | Usage |
|------------|-------|
| `Deployer\Contracts\BaseCommand` | Parent class |
| `Deployer\Traits\PlaybooksTrait` | Provides `executePlaybookSilently()` |
| `Deployer\Traits\ServersTrait` | Provides `selectServerDeets()` |
| `Symfony\Component\Console\Attribute\AsCommand` | Command metadata |
| `Symfony\Component\Console\Command\Command` | Constants |
| `Symfony\Component\Console\Input\InputInterface` | CLI input |
| `Symfony\Component\Console\Input\InputOption` | Option constants |
| `Symfony\Component\Console\Output\OutputInterface` | CLI output |

### Coupled Files

| File | Coupling Type | Description |
|------|---------------|-------------|
| `playbooks/memcached-service.sh` | Playbook | Service control script |
| `app/Repositories/ServerRepository.php` | Repository | Server lookup |
| `app/Services/SshService.php` | Service | SSH connection |

## Data Flow

### Inputs

| Source | Data | Processing |
|--------|------|------------|
| CLI `--server` | Server name | Validated against inventory |

### Outputs

| Destination | Data | Format |
|-------------|------|--------|
| Console | Success/failure message | Text via `yay()`/`nay()` |
| Console | Command replay | CLI command string |

### Side Effects

| Effect | Location | Trigger |
|--------|----------|---------|
| Memcached service started | Remote server | Successful execution |

## Notes

### Service Verification

The `memcached-service.sh` playbook includes a 10-second polling loop (`verify_service_active`) that confirms Memcached is running before returning success.

### Pattern Consistency

Matches structure of `MysqlStartCommand`, `MariadbStartCommand`:

1. Select server
2. Execute service playbook with action
3. Handle failure explicitly
4. Show success and command replay
