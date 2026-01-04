# Schematic: php-install.sh

> Auto-generated schematic. Last updated: 2025-12-27

## Recent Changes

- **2025-12-27**: Migrated from Caddy to Nginx - PHP-FPM socket ownership changed from `caddy:caddy` to `www-data:www-data`. Removed Caddy localhost.caddy integration for PHP-FPM status endpoints.

## Overview

Installs a specified PHP version with selected extensions, configures PHP-FPM for Nginx integration (www-data socket ownership), sets up Composer, and optionally sets the installed version as the system default. This playbook is idempotent and part of the server provisioning workflow.

## Logic Flow

### Entry Points

| Function | Purpose |
|----------|---------|
| `main()` | Primary entry point - orchestrates all installation steps |

### Execution Flow

1. **Environment Validation** (lines 15-21)
   - Validates required environment variables:
     - `DEPLOYER_OUTPUT_FILE` - Output YAML path
     - `DEPLOYER_DISTRO` - Distribution (ubuntu/debian)
     - `DEPLOYER_PERMS` - Permission level (root/sudo/none)
     - `DEPLOYER_PHP_VERSION` - PHP version to install (e.g., "8.4")
     - `DEPLOYER_PHP_SET_DEFAULT` - Whether to set as system default ("true"/"false")
     - `DEPLOYER_PHP_EXTENSIONS` - Comma-separated list of extensions
   - Exports `DEPLOYER_PERMS` for helper functions

2. **`install_php_packages()`** (lines 37-54)
   - Parses comma-separated extensions from `DEPLOYER_PHP_EXTENSIONS`
   - Builds package list: `php{VERSION}-{extension}` for each extension
   - Installs packages via `apt_get_with_retry` helper

3. **`configure_php_fpm()`**
   - Modifies `/etc/php/{VERSION}/fpm/pool.d/www.conf`:
     - Sets `listen.owner = www-data`
     - Sets `listen.group = www-data`
     - Sets `listen.mode = 0660`
     - Enables `pm.status_path = /fpm-status`
   - Enables PHP-FPM service via systemctl
   - Restarts PHP-FPM to apply changes

4. **`config_logrotate()`** (lines 138-161)
   - Creates `/etc/logrotate.d/php-fpm-deployer` config
   - Configures daily rotation, 5 rotations, 30-day max age
   - Uses `SIGUSR1` signal for graceful log reopening

5. **`set_as_default()`** (lines 170-183)
   - Conditionally executed if `DEPLOYER_PHP_SET_DEFAULT == 'true'`
   - Updates system alternatives for `php`, `php-config`, `phpize`

6. **`install_composer()`**
   - Checks if Composer is already installed
   - Downloads installer from getcomposer.org
   - Installs to `/usr/local/bin/composer`
   - Cleans up installer script

7. **Output Generation**
   - Writes YAML to `DEPLOYER_OUTPUT_FILE`:

     ```yaml
     status: success
     ```

### Decision Points

| Condition | True Branch | False Branch |
|-----------|-------------|--------------|
| `command -v composer` exists | Skip installation | Install Composer |
| PHP-FPM service not enabled | Enable service | Skip |
| `DEPLOYER_PHP_SET_DEFAULT != 'true'` | Return early | Set alternatives |

### Exit Conditions

| Exit Code | Condition |
|-----------|-----------|
| 1 | Missing required environment variable |
| 1 | PHP package installation failure |
| 1 | PHP-FPM configuration failure (sed commands) |
| 1 | PHP-FPM service enable/restart failure |
| 1 | Logrotate config write failure |
| 1 | Composer download/install failure |
| 1 | Output file write failure |
| 0 | Successful completion |

## Interaction Diagram

```mermaid
flowchart TD
    subgraph "Environment"
        ENV[Environment Variables]
    end

    subgraph "php-install.sh"
        MAIN[main]
        IPP[install_php_packages]
        CFP[configure_php_fpm]
        CLR[config_logrotate]
        SAD[set_as_default]
        IC[install_composer]
        OUT[Write Output YAML]
    end

    subgraph "System Services"
        APT[apt-get]
        SYSTEMCTL[systemctl]
        CURL[curl]
    end

    subgraph "File System"
        POOL[/etc/php/VERSION/fpm/pool.d/www.conf]
        LOGROT[/etc/logrotate.d/php-fpm-deployer]
        COMPOSER[/usr/local/bin/composer]
        OUTFILE[DEPLOYER_OUTPUT_FILE]
    end

    subgraph "External"
        GETCOMPOSER[getcomposer.org]
    end

    ENV --> MAIN
    MAIN --> IPP
    IPP --> APT
    MAIN --> CFP
    CFP --> POOL
    CFP --> SYSTEMCTL
    MAIN --> CLR
    CLR --> LOGROT
    MAIN --> SAD
    SAD --> SYSTEMCTL
    MAIN --> IC
    IC --> CURL
    CURL --> GETCOMPOSER
    IC --> COMPOSER
    MAIN --> OUT
    OUT --> OUTFILE
```

## Dependencies

### Direct Imports

| File/Module | Usage |
|-------------|-------|
| `helpers.sh` | Helper functions (inlined at runtime): `run_cmd`, `apt_get_with_retry` |

### Coupled Files

| File | Coupling Type | Description |
|------|---------------|-------------|
| `/etc/php/{VERSION}/fpm/pool.d/www.conf` | Config | PHP-FPM pool configuration modified for www-data socket access |
| `/etc/logrotate.d/php-fpm-deployer` | Config | Log rotation for PHP-FPM logs |
| `/usr/local/bin/composer` | Binary | Composer installation location |
| `/run/php/php{VERSION}-fpm.sock` | Socket | PHP-FPM Unix socket referenced in Nginx config |
| `playbooks/base-install.sh` | Dependency | Must run first to install Nginx |

### System Dependencies

| Component | Purpose |
|-----------|---------|
| `apt-get` | Package installation |
| `systemctl` | Service management (enable, restart) |
| `update-alternatives` | PHP version default management |
| `curl` | Composer installer download |
| `sed` | PHP-FPM config modification |

## Data Flow

### Inputs

| Source | Data | Purpose |
|--------|------|---------|
| `DEPLOYER_OUTPUT_FILE` | String | Path for output YAML |
| `DEPLOYER_DISTRO` | String | Target distribution (ubuntu/debian) |
| `DEPLOYER_PERMS` | String | Permission mode (root/sudo/none) |
| `DEPLOYER_PHP_VERSION` | String | PHP version (e.g., "8.4") |
| `DEPLOYER_PHP_SET_DEFAULT` | String | "true" or "false" |
| `DEPLOYER_PHP_EXTENSIONS` | String | Comma-separated extensions (e.g., "cli,fpm,mbstring") |

### Outputs

| Destination | Data | Format |
|-------------|------|--------|
| `DEPLOYER_OUTPUT_FILE` | Installation result | YAML: `status: success` |
| stdout | Progress messages | `-> Installing PHP 8.4...` |
| stderr | Error messages | `Error: ...` |

### Side Effects

| Effect | Description |
|--------|-------------|
| Packages installed | PHP packages via apt-get |
| PHP-FPM configured | Socket permissions (www-data:www-data), status page enabled |
| Service enabled | PHP-FPM systemd service |
| Service restarted | PHP-FPM service |
| Logrotate configured | Daily rotation for PHP-FPM logs |
| System default set | PHP alternatives updated (conditional) |
| Composer installed | Global Composer binary (conditional) |

## Notes

### Idempotency

- PHP packages: apt-get handles already-installed packages
- PHP-FPM config: sed commands are idempotent (same result on re-run)
- Logrotate: tee overwrites existing config (idempotent)
- Composer: Checks `command -v composer` before installing
- Service operations: systemctl commands are idempotent

### PHP-FPM Socket Ownership

Socket ownership is set to `www-data:www-data` with mode `0660` to allow Nginx to communicate with PHP-FPM. This is critical for the FastCGI reverse proxy to function.

Note: This changed from `caddy:caddy` in the Nginx migration.

### Extension Handling

Extensions are parsed from a comma-separated string and converted to package names:

- Input: `cli,fpm,mbstring,curl`
- Output: `php8.4-cli php8.4-fpm php8.4-mbstring php8.4-curl`

### Invocation

This playbook is invoked by `ServerInstallCommand::installPhp()` via the `executePlaybook()` method in `PlaybooksTrait`.

```php
$result = $this->executePlaybook(
    $server,
    'php-install',
    "Installing PHP...",
    [
        'DEPLOYER_PHP_VERSION' => $phpVersion,
        'DEPLOYER_PHP_SET_DEFAULT' => $setAsDefault ? 'true' : 'false',
        'DEPLOYER_PHP_EXTENSIONS' => implode(',', $selectedExtensions),
    ],
);
```
