# Schematic: postgresql-install.sh

> Auto-generated schematic. Last updated: 2025-12-19

## Overview

This playbook installs PostgreSQL server on Ubuntu/Debian systems, configures logging to a predictable path, sets up scram-sha-256 authentication, and creates a `deployer` user and database with generated credentials. It implements idempotent installation checks and integrates with the system logrotate.

## Logic Flow

### Entry Points

| Function | Purpose |
|----------|---------|
| `main()` | Primary entry point, orchestrates entire installation |

### Execution Flow

1. **Environment Validation** (lines 23-26)
   - Validates required `DEPLOYER_OUTPUT_FILE`, `DEPLOYER_DISTRO`, `DEPLOYER_PERMS`
   - Exits with error if any required variable is missing

2. **Idempotency Check** (lines 329-341)
   - Checks if PostgreSQL is already running (`postgresql` service)
   - If already installed: writes `already_installed: true` to output and exits successfully

3. **Credential Generation** (lines 344-345)
   - Generates `POSTGRES_PASS` and `DEPLOYER_PASS` using `openssl rand -base64 24`

4. **Package Installation** (line 348)
   - `install_packages()` installs `postgresql` and `postgresql-client`
   - Enables and starts the `postgresql` systemd service
   - Waits up to 30 seconds for PostgreSQL to accept connections via `pg_isready`

5. **Logging Configuration** (line 349)
   - `configure_logging()` modifies `/etc/postgresql/{version}/main/postgresql.conf`
   - Sets `log_destination = 'stderr'`, `logging_collector = on`
   - Configures `log_directory = '/var/log/postgresql'` and `log_filename = 'postgresql.log'`
   - Disables PostgreSQL internal rotation (`log_rotation_age = 0`) for logrotate integration

6. **Security Configuration** (lines 350-351)
   - `set_postgres_password()` sets the `postgres` user password via `ALTER USER`
   - `configure_auth()` rewrites `/etc/postgresql/{version}/main/pg_hba.conf`
   - Configures peer auth for local postgres user, scram-sha-256 for all others
   - Adds `DEPLOYER-MANAGED` marker for idempotency

7. **User Creation** (line 352)
   - `create_deployer_user()` checks if user exists first (idempotent)
   - Creates `deployer` PostgreSQL user with generated password

8. **Database Creation** (line 353)
   - `create_deployer_database()` checks if database exists first (idempotent)
   - Creates `deployer` database with UTF8 encoding, `en_US.UTF-8` collation
   - Grants all privileges to deployer user

9. **Log Rotation** (line 354)
   - `config_logrotate()` creates `/etc/logrotate.d/postgresql-deployer` config
   - Configures daily rotation, 5 files, 30 day max age, copytruncate

10. **Service Restart** (lines 357-373)
    - Restarts PostgreSQL to apply logging and auth changes
    - Waits up to 30 seconds for service to accept connections

11. **Output Generation** (lines 376-385)
    - Writes YAML to `DEPLOYER_OUTPUT_FILE` with credentials

### Decision Points

| Line | Condition | True Branch | False Branch |
|------|-----------|-------------|--------------|
| 329 | PostgreSQL already running | Write `already_installed` and exit | Proceed with install |
| 59 | Service not enabled | Enable it | Skip enable |
| 66 | Service not active | Start it | Skip start |
| 115, 122, 129, 137, 145 | Config already set | Skip setting | Apply config |
| 204 | Auth already configured | Skip pg_hba.conf rewrite | Configure auth |
| 247 | Deployer user exists | Skip user creation | Create user |
| 272 | Deployer database exists | Ensure ownership, skip creation | Create database |

### Exit Conditions

| Exit Code | Condition | Location |
|-----------|-----------|----------|
| 0 | PostgreSQL already installed | line 340 |
| 0 | Fresh install successful | implicit after main() |
| 1 | Missing required environment variable | lines 23-25 |
| 1 | Package installation failed | line 55 |
| 1 | Service enable/start failed | lines 62, 69 |
| 1 | Connection timeout (30s) | line 80 |
| 1 | PostgreSQL version detection failed | lines 101, 192 |
| 1 | Config file not found | lines 109, 199 |
| 1 | Logging config failed | lines 117-160 |
| 1 | Password set failed | line 177 |
| 1 | Auth config failed | line 231 |
| 1 | User creation failed | line 256 |
| 1 | Database creation failed | line 282 |
| 1 | Privilege grant failed | line 289 |
| 1 | Logrotate config write failed | line 319 |
| 1 | Service restart failed | line 359 |
| 1 | Post-restart connection timeout | line 370 |
| 1 | Output file write failed | lines 337, 383 |

## Interaction Diagram

```mermaid
flowchart TD
    subgraph Command["PHP Command Layer"]
        PIC[PostgresqlInstallCommand]
        PT[PlaybooksTrait]
    end

    subgraph Playbook["postgresql-install.sh"]
        MAIN[main]
        IP[install_packages]
        CL[configure_logging]
        SPP[set_postgres_password]
        CA[configure_auth]
        CDU[create_deployer_user]
        CDD[create_deployer_database]
        CLR[config_logrotate]
    end

    subgraph System["System Services"]
        SYSD[systemctl]
        APT[apt-get]
        PGSQL[PostgreSQL Server]
        LR[logrotate]
    end

    subgraph Config["Configuration Files"]
        PGCONF[postgresql.conf]
        PGHBA[pg_hba.conf]
    end

    subgraph Output["Output Files"]
        YAML[DEPLOYER_OUTPUT_FILE]
        LRCFG[/etc/logrotate.d/postgresql-deployer]
    end

    PIC --> PT
    PT -->|SSH + helpers.sh| MAIN
    MAIN --> IP
    IP -->|install| APT
    IP -->|enable/start| SYSD
    IP -->|pg_isready| PGSQL
    MAIN --> CL
    CL -->|modify| PGCONF
    MAIN --> SPP
    SPP -->|ALTER USER| PGSQL
    MAIN --> CA
    CA -->|rewrite| PGHBA
    MAIN --> CDU
    CDU -->|CREATE USER| PGSQL
    MAIN --> CDD
    CDD -->|CREATE DATABASE| PGSQL
    MAIN --> CLR
    CLR -->|write| LRCFG
    MAIN -->|restart| SYSD
    MAIN -->|write| YAML
    PT -->|read + parse| YAML
```

## Dependencies

### Direct Imports

| File/Module | Usage |
|-------------|-------|
| `helpers.sh` | Inlined at runtime - provides `run_cmd`, `apt_get_with_retry` |

### Coupled Files

| File | Coupling Type | Description |
|------|---------------|-------------|
| `app/Console/Postgresql/PostgresqlInstallCommand.php` | Invoker | PHP command that executes this playbook via SSH |
| `app/Traits/PlaybooksTrait.php` | Runtime | Inlines helpers.sh and manages playbook execution |
| `/etc/postgresql/{version}/main/postgresql.conf` | Config | Modified for logging configuration |
| `/etc/postgresql/{version}/main/pg_hba.conf` | Config | Rewritten for authentication configuration |
| `/etc/logrotate.d/postgresql-deployer` | Config | Created by this playbook for log rotation |
| `/var/log/postgresql/postgresql.log` | Log | PostgreSQL log file managed by logrotate config |

### Helper Functions Used

| Function | Source | Purpose |
|----------|--------|---------|
| `run_cmd` | helpers.sh | Execute commands with root/sudo based on DEPLOYER_PERMS |
| `apt_get_with_retry` | helpers.sh | Install packages with dpkg lock retry |

## Data Flow

### Inputs

| Variable | Source | Description |
|----------|--------|-------------|
| `DEPLOYER_OUTPUT_FILE` | PlaybooksTrait | Path for YAML output (always provided) |
| `DEPLOYER_DISTRO` | Server info | Distribution: `ubuntu` or `debian` |
| `DEPLOYER_PERMS` | Server info | Permissions: `root`, `sudo`, or `none` |

### Outputs

**Fresh Install:**

```yaml
status: success
postgres_pass: <generated 32-char base64>
deployer_user: deployer
deployer_pass: <generated 32-char base64>
deployer_database: deployer
```

**Already Installed:**

```yaml
status: success
already_installed: true
```

### Side Effects

| Effect | Location | Description |
|--------|----------|-------------|
| Package installation | `install_packages()` | Installs postgresql, postgresql-client |
| Service enablement | `install_packages()` | Enables postgresql systemd unit |
| Service start | `install_packages()` | Starts postgresql service |
| Logging config | `configure_logging()` | Modifies postgresql.conf for predictable log path |
| Log directory | `configure_logging()` | Creates /var/log/postgresql with postgres ownership |
| Postgres password | `set_postgres_password()` | Sets postgres superuser password |
| Auth config | `configure_auth()` | Rewrites pg_hba.conf with scram-sha-256 auth |
| User creation | `create_deployer_user()` | Creates deployer PostgreSQL user |
| Database creation | `create_deployer_database()` | Creates deployer database with UTF8 encoding |
| Privilege grant | `create_deployer_database()` | Grants all privileges on deployer DB |
| File creation | `config_logrotate()` | Creates /etc/logrotate.d/postgresql-deployer |
| Service restart | `main()` | Restarts postgresql to apply configuration |

## Notes

### Security Considerations

- Passwords set via `psql -c "ALTER USER ..."` executed as postgres user via `su -`
- Generated passwords use `openssl rand -base64 24` (32 characters, cryptographically secure)
- Authentication uses scram-sha-256 (PostgreSQL's strongest password auth method)
- Peer authentication preserved for local postgres user (system user mapping)
- pg_hba.conf backup created before modification (`pg_hba.conf.bak`)

### Idempotency

The playbook is fully idempotent:

- Already-running PostgreSQL results in graceful early exit with `already_installed: true`
- User and database creation check for existence before creating
- Service enable/start only triggered if not already enabled/active
- Logging and auth config check for existing values before modifying
- `DEPLOYER-MANAGED` marker in pg_hba.conf prevents duplicate auth configuration

### Logging Integration

Unlike MySQL/MariaDB, PostgreSQL requires explicit configuration for predictable log paths:

- Default PostgreSQL uses version-specific log filenames (e.g., `postgresql-16-main.log`)
- This playbook normalizes to `/var/log/postgresql/postgresql.log`
- Disables PostgreSQL internal rotation in favor of system logrotate
- Uses `copytruncate` strategy since PostgreSQL keeps file handles open

### Version Detection

PostgreSQL config paths are version-specific (`/etc/postgresql/{version}/main/`). The playbook:

- Detects installed version via `find /etc/postgresql/ -mindepth 1 -maxdepth 1 -type d`
- Uses first found version directory (head -1)
- Fails gracefully if version detection fails
