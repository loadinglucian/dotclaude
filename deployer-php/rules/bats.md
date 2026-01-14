---
paths: tests/bats/**
---

# BATS Rules

Functional CLI testing using BATS (Bash Automated Testing System) with Lima VMs simulating real servers via SSH. Tests run against multiple Linux distros automatically.

> **IMPORTANT**
>
> - SUCCESS paths only - no failure-path tests (those belong in PHP unit tests)
> - BATS must only test NON-INTERACTIVE command paths (Laravel Prompts requires TTY)
> - Always provide ALL CLI options to skip prompts

## Context

### Testing Philosophy

BATS tests are a "test drive around the track" - proving the system works end-to-end with valid inputs.

**Success paths only:**

- Test commands complete successfully with valid inputs
- Verify side effects (files created, services running, users exist)
- Empty-state tests are OK (graceful UX when inventory is empty)

**Rationale:**

- Long-running commands (e.g., `server:install`) take 5+ minutes per distro
- Timeout-based tests are inherently flaky
- Integration tests prove the system works; unit tests prove edge cases fail correctly

### Structure

```text
tests/bats/
├── run.sh               # Test runner (run, start, stop, reset, clean, ssh)
├── lima/
│   ├── ubuntu24.yaml    # Ubuntu 24.04 VM config
│   ├── ubuntu25.yaml    # Ubuntu 25.04 VM config
│   ├── debian12.yaml    # Debian 12 Bookworm VM config
│   └── debian13.yaml    # Debian 13 Trixie VM config
├── lib/
│   ├── helpers.bash     # Assertions and test utilities
│   ├── lima-core.bash   # Shared Lima functions (used by run.sh and lima.bash)
│   ├── lima.bash        # Lima VM lifecycle management (BATS context)
│   └── inventory.bash   # Test inventory manipulation
└── server.bats          # Server command tests
```

### Multi-Distro Testing

Tests run against all distros sequentially. Each distro has its own VM and SSH port:

| Distro   | Port | VM Instance            |
| -------- | ---- | ---------------------- |
| ubuntu24 | 2222 | deployer-test-ubuntu24 |
| ubuntu25 | 2224 | deployer-test-ubuntu25 |
| debian12 | 2223 | deployer-test-debian12 |
| debian13 | 2225 | deployer-test-debian13 |

### Commands

```bash
composer bats                    # Run all tests on all distros
composer bats:start              # Start all VMs
composer bats:stop               # Stop all VMs

./tests/bats/run.sh run          # Run all tests on all distros
./tests/bats/run.sh run server   # Run server.bats on all distros
./tests/bats/run.sh start        # Start VMs without running tests
./tests/bats/run.sh stop         # Stop VMs
./tests/bats/run.sh reset        # Factory reset VMs (delete + recreate)
./tests/bats/run.sh clean        # Clean VM state without restart
./tests/bats/run.sh ssh ubuntu24 # SSH into ubuntu24 VM
./tests/bats/run.sh ssh debian12 # SSH into debian12 VM
BATS_DEBUG=1 composer bats       # Enable debug output
```

**VM State Management:**

- `run` - Cleans each VM state before testing (fast, via SSH)
- `reset` - Deletes and recreates VMs from scratch (slow, guaranteed fresh)
- `clean` - Cleans all VM states without stopping them

### Available Helpers

**Assertions:**

- `assert_success_output` - Output contains `✓`
- `assert_error_output` - Output contains `✗`
- `assert_info_output` - Output contains `ℹ`
- `assert_warning_output` - Output contains `!`
- `assert_output_contains "text"` - Output contains string
- `assert_command_replay "cmd"` - Output contains command replay

**Execution:**

- `run_deployer cmd --opt` - Run deployer with test inventory
- `debug_output` - Print output when BATS_DEBUG=1

**Inventory:**

- `reset_inventory` - Empty inventory
- `add_test_server [name]` - Add test server to inventory
- `add_test_site "domain"` - Add server + site to inventory
- `inventory_has_server "name"` - Check server exists
- `inventory_has_site "domain"` - Check site exists

**SSH:**

- `ssh_exec "command"` - Execute on test VM
- `assert_remote_file_exists "/path"` - Check remote file

**Lima:**

- `lima_clean` - Clean VM state via SSH
- `lima_is_running` - Check if VM is running
- `lima_logs [lines]` - Get VM system logs

### Adding a New Distro

1. Create `lima/{distro}.yaml` (copy existing, update image URLs and port)
2. Add to `DISTRO_PORTS` and `DISTROS` in `run.sh`
3. Add to `DISTRO_PORTS` in `lib/helpers.bash`

### Dependencies

```bash
brew install bats-core lima jq
```

## Examples

### Example: Test Template

```bash
#!/usr/bin/env bats

load 'lib/helpers'
load 'lib/lima'
load 'lib/inventory'

# ----

# Setup/Teardown

# ----

setup() {
    reset_inventory
}

# ----

# command:name

# ----

@test "command:name does something" {
    add_test_server

    run_deployer command:name --option=value

    debug_output

    [ "$status" -eq 0 ]
    assert_success_output
    assert_output_contains "Expected text"

}
```

### Example: Test Success

```bash
@test "command succeeds with valid input" {
    add_test_server
    run_deployer command:name --option=value
    debug_output
    [ "$status" -eq 0 ]
    assert_success_output
    assert_command_replay "command:name"
}
```

### Example: Test Empty State

```bash
@test "command shows info when no servers" {
    reset_inventory
    run_deployer command:name --server="nonexistent"
    debug_output
    assert_info_output
    assert_output_contains "No servers found"
}
```

### Example: Test Side Effect

```bash
@test "command creates expected files on remote" {
    add_test_server
    assert_remote_file_exists "/home/deployer/.ssh/id_ed25519"
    assert_remote_dir_exists "/home/deployer/sites"
}
```

## Rules

- Use `--yes` / `-y` to skip confirmations
- Use `--force` / `-f` to skip type-to-confirm prompts
- Input validation and failure-path tests belong in PHP unit tests
- Each distro has isolated VM instance and SSH port
- Interactive-only behavior cannot be tested in BATS
