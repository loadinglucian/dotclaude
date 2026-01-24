---
paths: tests/bats/**, bats.sh
---

# BATS Rules

Functional CLI testing using BATS (Bash Automated Testing System). Tests are divided into two categories: VM tests (using Lima VMs via SSH) and Cloud tests (against real cloud provider APIs).

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
bats.sh                      # Test runner (interactive menu + CI mode)
tests/bats/
├── vm.bats                  # VM/server command tests (Lima required)
├── cloud-aws.bats           # AWS provisioning tests (no VM)
├── cloud-do.bats            # DigitalOcean provisioning tests (no VM)
├── lima/
│   ├── ubuntu24.yaml        # Ubuntu 24.04 VM config
│   ├── debian12.yaml        # Debian 12 Bookworm VM config
│   └── debian13.yaml        # Debian 13 Trixie VM config
├── lib/
│   ├── helpers.bash         # Assertions and test utilities
│   ├── cloud-helpers.bash   # Cloud provider credential checks and cleanup
│   ├── lima-core.bash       # Shared Lima functions (used by bats.sh and lima.bash)
│   ├── lima.bash            # Lima VM lifecycle management (BATS context)
│   └── inventory.bash       # Test inventory manipulation
└── fixtures/
    ├── keys/                # SSH keys for test servers
    └── inventory/           # Test inventory files
```

### Test Categories

| Category | Tests | Requirements | Trigger |
|----------|-------|--------------|---------|
| VM | `vm.bats` | Lima VMs, SSH access | `./bats.sh run vm` |
| Cloud | `cloud-aws.bats`, `cloud-do.bats` | Provider API credentials | `./bats.sh run cloud` |

**VM Tests:**

- Run against Lima VMs simulating real servers
- Test server management commands (add, install, deploy, etc.)
- Require Lima installed locally

**Cloud Tests:**

- Run against real cloud provider APIs (AWS, DigitalOcean)
- Test provisioning, DNS, and key management commands
- No VM required - pure API interaction
- Skip automatically if credentials not available

### Multi-Distro Testing (VM)

VM tests run against all distros sequentially. Each distro has its own VM and SSH port:

| Distro   | Port | VM Instance            |
| -------- | ---- | ---------------------- |
| ubuntu24 | 2222 | deployer-test-ubuntu24 |
| debian12 | 2223 | deployer-test-debian12 |
| debian13 | 2225 | deployer-test-debian13 |

### Commands

```bash
# Interactive mode (shows category menu)
./bats.sh                    # Select: cloud or vm -> select target

# Direct category (prompts for target)
./bats.sh run cloud          # Prompts for provider: all, aws, do
./bats.sh run vm             # Prompts for distro: all, ubuntu24, debian12, debian13

# Direct test file
./bats.sh run cloud-aws      # Run AWS cloud tests directly
./bats.sh run cloud-do       # Run DigitalOcean cloud tests directly

# CI mode (non-interactive, requires CI=true)
CI=true ./bats.sh ci cloud aws      # Run AWS cloud tests
CI=true ./bats.sh ci cloud do       # Run DO cloud tests
CI=true ./bats.sh ci cloud all      # Run all cloud tests
CI=true ./bats.sh ci vm ubuntu24    # Run VM tests on ubuntu24
CI=true ./bats.sh ci vm debian12    # Run VM tests on debian12

# VM management
./bats.sh start [distro]     # Start VMs (all if no distro)
./bats.sh stop [distro]      # Stop VMs
./bats.sh reset [distro]     # Factory reset VMs (delete + recreate)
./bats.sh clean [distro]     # Clean VM state without restart
./bats.sh ssh <distro>       # SSH into a test VM

# Debug mode
BATS_DEBUG=1 ./bats.sh run   # Enable verbose debug output
```

### Available Helpers

**Assertions (helpers.bash):**

- `assert_success_output` - Output contains `✓`
- `assert_error_output` - Output contains `✗`
- `assert_info_output` - Output contains `ℹ`
- `assert_warning_output` - Output contains `!`
- `assert_output_contains "text"` - Output contains string
- `assert_output_not_contains "text"` - Output does NOT contain string
- `assert_command_replay "cmd"` - Output contains command replay
- `assert_success` - Exit status is 0
- `assert_failure` - Exit status is non-zero

**Execution (helpers.bash):**

- `run_deployer cmd --opt` - Run deployer with test inventory
- `run_deployer_success cmd` - Run and assert success
- `run_deployer_failure cmd` - Run and assert failure
- `debug_output` - Print output when BATS_DEBUG=1
- `debug "message"` - Print debug message when BATS_DEBUG=1

**Inventory (inventory.bash):**

- `reset_inventory` - Empty inventory
- `add_test_server [name]` - Add test server to inventory
- `add_test_site "domain"` - Add server + site to inventory
- `inventory_has_server "name"` - Check server exists
- `inventory_has_site "domain"` - Check site exists

**SSH (helpers.bash):**

- `ssh_exec "command"` - Execute on test VM
- `assert_remote_file_exists "/path"` - Check remote file
- `assert_remote_dir_exists "/path"` - Check remote directory
- `assert_remote_file_contains "/path" "text"` - Check file content

**Lima (lima.bash):**

- `lima_clean` - Clean VM state via SSH
- `lima_is_running` - Check if VM is running
- `lima_logs [lines]` - Get VM system logs

**Cloud Credentials (cloud-helpers.bash):**

- `aws_credentials_available` - Check AWS env vars set
- `do_credentials_available` - Check DO API token set
- `cf_credentials_available` - Check Cloudflare API token set
- `aws_provision_config_available` - Check full AWS config for provisioning
- `do_provision_config_available` - Check full DO config for provisioning

**Cloud Cleanup (cloud-helpers.bash):**

- `aws_cleanup_test_key` - Remove AWS test SSH key
- `aws_cleanup_test_server` - Remove AWS test server from inventory
- `do_cleanup_test_key` - Remove DO test SSH key
- `do_cleanup_test_server` - Remove DO test server from inventory
- `do_find_key_id_by_name "name"` - Find DO key ID by name
- `do_extract_key_id_from_output "output"` - Extract key ID from command output

**Shared Cloud Helpers (cloud-helpers.bash):**

- `get_server_ip "server-name"` - Get server IP from inventory
- `cleanup_test_site "domain"` - Remove test site from inventory
- `wait_for_http "domain" ["content"] [timeout] ["ip"]` - Wait for HTTP response

### Adding a New Distro

1. Create `lima/{distro}.yaml` (copy existing, update image URLs and port)
2. Add to `DISTRO_PORTS` and `DISTROS` in `bats.sh`
3. Add to `DISTRO_PORTS` in `lib/helpers.bash`

### Dependencies

```bash
# VM tests require Lima
brew install bats-core lima jq

# Cloud tests only need BATS
brew install bats-core jq
```

## Examples

### Example: VM Test Template

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
    assert_command_replay "command:name"
}
```

### Example: Cloud Test Template

```bash
#!/usr/bin/env bats

load 'lib/helpers'
load 'lib/cloud-helpers'

# ----
# Setup/Teardown
# ----

setup_file() {
    # Skip all tests if credentials not configured
    if ! aws_credentials_available; then
        skip "AWS credentials not configured"
    fi

    # Clean up any leftover test artifacts
    aws_cleanup_test_key
}

setup() {
    # Skip individual test if credentials unavailable
    if ! aws_credentials_available; then
        skip "AWS credentials not configured"
    fi
}

# ----
# aws:key:add
# ----

@test "aws:key:add uploads public key" {
    run_deployer aws:key:add \
        --name="$AWS_TEST_KEY_NAME" \
        --public-key-path="$CLOUD_TEST_KEY_PATH"

    debug_output

    [ "$status" -eq 0 ]
    assert_success_output
    assert_output_contains "Key pair imported successfully"
    assert_command_replay "aws:key:add"
}
```

### Example: Credential Skip Pattern

```bash
@test "aws:provision creates EC2 instance" {
    # Skip if full provisioning config not available
    if ! aws_provision_config_available; then
        skip "AWS provisioning config not complete"
    fi

    run_deployer aws:provision \
        --name="$AWS_TEST_SERVER_NAME" \
        --instance-type="$AWS_TEST_INSTANCE_TYPE" \
        # ... more options

    debug_output

    [ "$status" -eq 0 ]
    assert_success_output
}
```

### Example: Full Lifecycle Test

```bash
@test "aws:provision full lifecycle: provision -> install -> deploy -> verify -> cleanup" {
    if ! aws_provision_config_available; then
        skip "AWS provisioning config not complete"
    fi

    # Provision server
    run_deployer aws:provision --name="$AWS_TEST_SERVER_NAME" ...
    [ "$status" -eq 0 ]

    # Get server IP for later verification
    local server_ip
    server_ip=$(get_server_ip "$AWS_TEST_SERVER_NAME")

    # Install server (PHP, Nginx, etc.)
    run_deployer server:install --server="$AWS_TEST_SERVER_NAME" ...
    [ "$status" -eq 0 ]

    # Create and deploy site
    run_deployer site:create --server="$AWS_TEST_SERVER_NAME" --domain="$AWS_TEST_DOMAIN" ...
    [ "$status" -eq 0 ]

    run_deployer site:deploy --domain="$AWS_TEST_DOMAIN" ...
    [ "$status" -eq 0 ]

    # Verify deployment (bypass DNS using direct IP)
    wait_for_http "$AWS_TEST_DOMAIN" "$CLOUD_TEST_APP_MESSAGE" 180 "$server_ip"

    # Cleanup
    cleanup_test_site "$AWS_TEST_DOMAIN"
    aws_cleanup_test_server
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
- Cloud tests must skip gracefully when credentials unavailable
- Use `setup_file()` for one-time cleanup, `setup()` for per-test credential checks
