# Schematic: mysql-install.sh

> Auto-generated schematic. Last updated: 2025-12-18

## Overview

This playbook installs MySQL server on Ubuntu/Debian systems, secures the installation, and creates a `deployer` user and database with generated credentials. It implements conflict detection with MariaDB and idempotent installation checks.

## Logic Flow

### Entry Points

| Function | Purpose |
|----------|---------|
| `main()` | Primary entry point, orchestrates entire installation |

### Execution Flow

1. **Environment Validation** (lines 23-26)
   - Validates required `DEPLOYER_OUTPUT_FILE`, `DEPLOYER_DISTRO`, `DEPLOYER_PERMS`
   - Exits with error if any required variable is missing

2. **Conflict Detection** (line 246)
   - `check_mariadb_conflict()` runs FIRST before any installation
   - Checks if MariaDB service is running via `systemctl is-active --quiet mariadb`
   - Checks if MariaDB packages installed via `dpkg -l mariadb-server`
   - Exits with error if either condition is true (port 3306 conflict)

3. **Idempotency Check** (lines 249-261)
   - Checks if MySQL is already running (`mysql` or `mysqld` service)
   - If already installed: writes `already_installed: true` to output and exits successfully

4. **Credential Generation** (lines 264-265)
   - Generates `ROOT_PASS` and `DEPLOYER_PASS` using `openssl rand -base64 24`

5. **Package Installation** (line 268)
   - `install_packages()` installs `mysql-server` and `mysql-client`
   - Enables and starts the `mysql` systemd service
   - Waits up to 30 seconds for MySQL to accept connections via `mysqladmin ping`

6. **Security Hardening** (line 269)
   - `secure_installation()` sets root password with `mysql_native_password` auth
   - Removes anonymous users, remote root login, test database
   - Exports `MYSQL_PWD` for subsequent commands (avoids password in process list)

7. **User Creation** (line 270)
   - `create_deployer_user()` checks if user exists first (idempotent)
   - Creates `deployer@localhost` with `mysql_native_password` authentication

8. **Database Creation** (line 271)
   - `create_deployer_database()` checks if database exists first (idempotent)
   - Creates `deployer` database with `utf8mb4_unicode_ci` collation
   - Grants all privileges to deployer user

9. **Log Rotation** (line 272)
   - `config_logrotate()` creates `/etc/logrotate.d/mysql-deployer` config
   - Configures daily rotation, 5 files, 30 day max age, copytruncate

10. **Output Generation** (lines 275-284)
    - Writes YAML to `DEPLOYER_OUTPUT_FILE` with credentials

### Decision Points

| Line | Condition | True Branch | False Branch |
|------|-----------|-------------|--------------|
| 46 | MariaDB service running | Exit with conflict error | Continue |
| 54 | MariaDB packages installed | Exit with conflict error | Continue |
| 249 | MySQL already running | Write `already_installed` and exit | Proceed with install |
| 84 | MySQL service not enabled | Enable it | Skip enable |
| 91 | MySQL service not active | Start it | Skip start |
| 162 | Deployer user exists | Skip user creation | Create user |
| 190 | Deployer database exists | Skip DB creation (ensure grants) | Create database |

### Exit Conditions

| Exit Code | Condition | Location |
|-----------|-----------|----------|
| 0 | MySQL already installed | line 260 |
| 0 | Fresh install successful | implicit after main() |
| 1 | Missing required environment variable | lines 23-25 |
| 1 | MariaDB conflict detected | lines 50, 58 |
| 1 | Package installation failed | line 80 |
| 1 | Service enable/start failed | lines 87, 94 |
| 1 | Connection timeout (30s) | line 105 |
| 1 | Root password set failed | line 130 |
| 1 | Deployer user creation failed | line 174 |
| 1 | Database creation failed | line 201 |
| 1 | Privilege grant failed | line 206 |
| 1 | Logrotate config write failed | line 236 |
| 1 | Output file write failed | lines 257, 283 |

## Interaction Diagram

```mermaid
flowchart TD
    subgraph Command["PHP Command Layer"]
        MIC[MysqlInstallCommand]
        PT[PlaybooksTrait]
    end

    subgraph Playbook["mysql-install.sh"]
        MAIN[main]
        CMC[check_mariadb_conflict]
        IP[install_packages]
        SI[secure_installation]
        CDU[create_deployer_user]
        CDD[create_deployer_database]
        CL[config_logrotate]
    end

    subgraph System["System Services"]
        SYSD[systemctl]
        APT[apt-get]
        MYSQL[MySQL Server]
        LR[logrotate]
    end

    subgraph Output["Output Files"]
        YAML[DEPLOYER_OUTPUT_FILE]
        LRCFG[/etc/logrotate.d/mysql-deployer]
    end

    MIC --> PT
    PT -->|SSH + helpers.sh| MAIN
    MAIN --> CMC
    CMC -->|check| SYSD
    MAIN --> IP
    IP -->|install| APT
    IP -->|enable/start| SYSD
    IP -->|ping| MYSQL
    MAIN --> SI
    SI -->|ALTER USER| MYSQL
    MAIN --> CDU
    CDU -->|CREATE USER| MYSQL
    MAIN --> CDD
    CDD -->|CREATE DATABASE| MYSQL
    MAIN --> CL
    CL -->|write| LRCFG
    MAIN -->|write| YAML
    PT -->|read + parse| YAML
```

## Dependencies

### Direct Imports

| File/Module | Usage |
|-------------|-------|
| `helpers.sh` | Inlined at runtime - provides `run_cmd`, `apt_get_with_retry`, `fail` |

### Coupled Files

| File | Coupling Type | Description |
|------|---------------|-------------|
| `playbooks/mariadb-install.sh` | Conflict | Mutually exclusive - checks for MariaDB before installing |
| `app/Console/Mysql/MysqlInstallCommand.php` | Invoker | PHP command that executes this playbook via SSH |
| `app/Traits/PlaybooksTrait.php` | Runtime | Inlines helpers.sh and manages playbook execution |
| `/etc/logrotate.d/mysql-deployer` | Config | Created by this playbook for log rotation |
| `/var/log/mysql/*.log` | Log | MySQL log files managed by logrotate config |

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
root_pass: <generated 32-char base64>
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
| Package installation | `install_packages()` | Installs mysql-server, mysql-client |
| Service enablement | `install_packages()` | Enables mysql systemd unit |
| Service start | `install_packages()` | Starts mysql service |
| Root password | `secure_installation()` | Sets MySQL root password |
| Security hardening | `secure_installation()` | Removes anonymous users, remote root, test DB |
| User creation | `create_deployer_user()` | Creates deployer MySQL user |
| Database creation | `create_deployer_database()` | Creates deployer database |
| Privilege grant | `create_deployer_database()` | Grants all privileges on deployer DB |
| File creation | `config_logrotate()` | Creates /etc/logrotate.d/mysql-deployer |

## Notes

### Security Considerations

- Passwords passed via heredoc (`<<- EOSQL`) to avoid exposure in process listings
- `MYSQL_PWD` environment variable used for subsequent commands (not visible in `ps`)
- Generated passwords use `openssl rand -base64 24` (32 characters, cryptographically secure)

### Idempotency

The playbook is fully idempotent:

- Conflict check prevents installation if MariaDB is present
- Already-running MySQL results in graceful early exit with `already_installed: true`
- User and database creation check for existence before creating
- Service enable/start only triggered if not already enabled/active

### MariaDB Mirror

This playbook is structurally identical to `mariadb-install.sh`, with:

- Different package names (`mysql-*` vs `mariadb-*`)
- Different service name (`mysql` vs `mariadb`)
- Different client command (`mysql` vs `mariadb`)
- Cross-conflict detection (MySQL checks for MariaDB, MariaDB checks for MySQL)

### Port Conflict

Both MySQL and MariaDB bind to port 3306 by default. The conflict detection ensures only one can be installed per server.
