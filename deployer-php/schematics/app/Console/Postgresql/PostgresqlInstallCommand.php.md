# Schematic: PostgresqlInstallCommand.php

> Auto-generated schematic. Last updated: 2025-12-19

## Overview

`PostgresqlInstallCommand` installs PostgreSQL server on a selected server via the `postgresql-install.sh` playbook. It handles server selection, credential output preferences (display or save to file), playbook execution, and secure credential storage with proper file permissions.

## Logic Flow

### Entry Points

| Method | Purpose |
|--------|---------|
| `configure()` | Defines CLI options: `--server`, `--display-credentials`, `--save-credentials` |
| `execute()` | Main execution: server selection, credential preference, playbook execution, output |

### Execution Flow

```
1. Display heading "Install PostgreSQL"

2. Select server via selectServerDeets() [ServersTrait]
   |- Validates server exists
   |- Retrieves server info (distro, permissions)
   +- Returns ServerDTO with info or FAILURE

3. Validate credential output options (mutually exclusive)
   |- Both provided -> Error, return FAILURE
   |- Neither provided -> Interactive prompt for choice
   |   |- 'display' -> Set displayCredentials = true
   |   +- 'save' -> Prompt for file path
   +- One provided -> Use that option

4. Execute postgresql-install playbook via executePlaybook() [PlaybooksTrait]
   |- SSH executes playbook on remote server
   +- Returns parsed YAML or FAILURE

5. Handle installation result
   |- Fresh install -> Validate and output credentials
   |   |- Missing credentials -> Error, return FAILURE
   |   |- displayCredentials -> Display on screen
   |   +- saveCredentialsPath -> Try save to file
   |       |- Success -> Show confirmation
   |       +- Failure -> Catch exception, warn user, fallback to display
   +- Already installed (already_installed: true) -> Show info message, skip credentials

6. Show command replay with appropriate options

7. Return SUCCESS
```

### Decision Points

| Line | Condition | True Branch | False Branch |
|------|-----------|-------------|--------------|
| 54 | `is_int($server) \|\| null === $server->info` | Return FAILURE | Continue |
| 67 | Both `--display-credentials` and `--save-credentials` | Error, return FAILURE | Continue |
| 73 | Neither credential option provided | Show interactive prompt | Use CLI option |
| 105 | `is_int($result)` (playbook failed) | Return FAILURE | Continue |
| 113 | `!($result['already_installed'])` | Output credentials | Show info message (line 151) |
| 117 | Postgres or deployer pass is null/empty | Error, return FAILURE | Output credentials |
| 132 | `$displayCredentials` is true | Display on screen | Try save to file |
| 144 | `saveCredentialsToFile()` throws RuntimeException | Fallback to display | (success path) |

### Exit Conditions

| Condition | Return Code | Location |
|-----------|-------------|----------|
| Server selection failed | `FAILURE` | Line 55 |
| Both credential options used | `FAILURE` | Line 70 |
| Playbook execution failed | `FAILURE` | Line 106 |
| Credentials not returned | `FAILURE` | Line 120 |
| Success | `SUCCESS` | Line 170 |

## Interaction Diagram

```mermaid
flowchart TD
    subgraph Command["PostgresqlInstallCommand"]
        CONF["configure()"]
        EXEC["execute()"]
        DISP["displayCredentialsOnScreen()"]
        SAVE["saveCredentialsToFile()"]
        NOW["now()"]
    end

    subgraph Traits["Traits"]
        ST["ServersTrait"]
        PT["PlaybooksTrait"]
    end

    subgraph Services["Services (via BaseCommand)"]
        IO["IoService"]
        SSH["SshService"]
        FS["FilesystemService"]
    end

    subgraph Remote["Remote Server"]
        PLAY["postgresql-install.sh"]
        PGSQL["PostgreSQL Server"]
    end

    subgraph Output["Output"]
        CONSOLE["Console Display"]
        FILE["Credentials File"]
    end

    EXEC --> ST
    ST -->|"selectServerDeets()"| IO
    ST -->|"server-info.sh"| SSH

    EXEC --> PT
    PT -->|"executePlaybook()"| SSH
    SSH --> PLAY
    PLAY -->|"install"| PGSQL
    PLAY -->|"YAML response"| PT

    EXEC --> DISP
    DISP --> CONSOLE

    EXEC --> SAVE
    SAVE --> FS
    SAVE --> NOW
    FS --> FILE
    SAVE -.->|"on failure"| DISP
```

## Sequence Diagram

```mermaid
sequenceDiagram
    participant User
    participant Cmd as PostgresqlInstallCommand
    participant ST as ServersTrait
    participant PT as PlaybooksTrait
    participant SSH as SshService
    participant FS as FilesystemService
    participant Remote as Remote Server

    User->>Cmd: postgresql:install
    Cmd->>ST: selectServerDeets()
    ST->>SSH: server-info.sh
    SSH->>Remote: Execute playbook
    Remote-->>SSH: Server info YAML
    SSH-->>ST: Parsed info
    ST-->>Cmd: ServerDTO with info

    Cmd->>User: Credential output preference?
    User-->>Cmd: display/save choice

    Cmd->>PT: executePlaybook(postgresql-install)
    PT->>SSH: Execute with spinner
    SSH->>Remote: Run postgresql-install.sh
    Remote-->>SSH: Credentials YAML
    SSH-->>PT: Parsed result
    PT-->>Cmd: {postgres_pass, deployer_pass, ...}

    alt Display on screen
        Cmd->>User: Show credentials
        Cmd->>User: Warning to save them
    else Save to file
        Cmd->>FS: appendFile(credentials)
        alt File operation succeeds
            Cmd->>FS: chmod(0600)
            Cmd->>User: Confirmation message
        else File operation fails (RuntimeException)
            Cmd->>User: Error message
            Cmd->>User: Info about fallback
            Cmd->>User: Show credentials on screen
        end
    end

    Cmd->>User: Command replay
```

## Dependencies

### Direct Imports

| File/Class | Usage |
|------------|-------|
| `Deployer\Contracts\BaseCommand` | Parent class with services and output helpers |
| `Deployer\Traits\PlaybooksTrait` | Provides `executePlaybook()` for remote execution |
| `Deployer\Traits\ServersTrait` | Provides `selectServerDeets()` for server selection |
| `Symfony\Component\Console\Attribute\AsCommand` | Command attribute registration |
| `Symfony\Component\Console\Command\Command` | Return constants (SUCCESS, FAILURE) |
| `Symfony\Component\Console\Input\InputInterface` | CLI input handling |
| `Symfony\Component\Console\Input\InputOption` | Option type definitions |
| `Symfony\Component\Console\Output\OutputInterface` | Console output |

### Coupled Files

| File | Coupling Type | Description |
|------|---------------|-------------|
| `playbooks/postgresql-install.sh` | Playbook | Executed remotely to install PostgreSQL |
| `playbooks/server-info.sh` | Playbook | Called by ServersTrait for server validation |
| `playbooks/helpers.sh` | Playbook | Inlined with all playbooks by PlaybooksTrait |
| `app/Traits/ServersTrait.php` | Trait | Server selection and info retrieval |
| `app/Traits/PlaybooksTrait.php` | Trait | Playbook execution infrastructure |
| `app/Contracts/BaseCommand.php` | Inheritance | Services, output methods, command infrastructure |
| `app/Services/FilesystemService.php` | Service | File write and chmod for credential storage |
| `~/.deployer/inventory.yml` | Data | Server inventory read by ServerRepository |

## Data Flow

### Inputs

| Source | Data | Description |
|--------|------|-------------|
| CLI `--server` | Server name | Selected server for installation |
| CLI `--display-credentials` | Boolean flag | Output credentials to console |
| CLI `--save-credentials` | File path | Save credentials to specified file |
| Interactive prompt | Credential preference | User choice when no CLI option |
| Interactive prompt | File path | Destination when saving to file |
| `postgresql-install.sh` YAML | Credentials | Generated postgres_pass, deployer_pass, etc. |

### Outputs

| Destination | Data | Format |
|-------------|------|--------|
| Console | Credentials display | Formatted text with connection string |
| File | Credentials | ENV format with comments |
| Console | Success/error messages | Via BaseCommand helpers |
| Console | Command replay | Non-interactive equivalent |

### Credential File Format

```env
# PostgreSQL Credentials for {serverName}
# Generated: {timestamp}
# WARNING: Keep this file secure!

## Postgres Credentials (admin access)
POSTGRES_PASSWORD={postgresPass}

## Application Credentials
POSTGRES_DATABASE={deployerDatabase}
POSTGRES_USER={deployerUser}
POSTGRES_USER_PASSWORD={deployerPass}

## Connection String
DATABASE_URL=postgresql://{deployerUser}:{deployerPass}@localhost/{deployerDatabase}
```

### Side Effects

| Effect | Description |
|--------|-------------|
| PostgreSQL installation | Remote server gets PostgreSQL server + client installed |
| PostgreSQL configuration | Postgres password set, deployer user/database created |
| Logging configuration | Log path set to `/var/log/postgresql/postgresql.log` |
| Authentication configuration | `pg_hba.conf` updated for scram-sha-256 auth |
| Logrotate configuration | `/etc/logrotate.d/postgresql-deployer` created |
| File creation | Credentials file created with 0600 permissions (if save option) |
| File append | Credentials appended if file exists |
| Console output | Credentials displayed (if display option or save fallback) |

## CLI Options

| Option | Type | Description |
|--------|------|-------------|
| `--server` | VALUE_REQUIRED | Server name from inventory |
| `--display-credentials` | VALUE_NONE | Show credentials on console |
| `--save-credentials` | VALUE_REQUIRED | Path to save credentials file |

## Helper Methods

### displayCredentialsOnScreen()

Outputs formatted credentials to console including:

- Postgres password (admin access)
- Application credentials (database, username, password)
- PostgreSQL connection string
- Warning to save credentials

### saveCredentialsToFile()

Saves credentials to file with security:

- Creates ENV-format file with comments
- Sets umask(0077) before write
- Uses `$this->fs->appendFile()` (creates or appends)
- Sets chmod 0600 after write
- Reports whether file was created or appended
- Throws `RuntimeException` on filesystem failure

### now()

Returns current timestamp for credential file header: `Y-m-d H:i:s T`

## Notes

- **Mutual Exclusivity**: `--display-credentials` and `--save-credentials` cannot be used together
- **Idempotent**: Playbook detects existing PostgreSQL and returns `already_installed: true` without reinstalling
- **Already Installed Handling**: When PostgreSQL is already installed, displays info message and skips credential output; no credential options added to command replay
- **File Security**: Credentials file uses restrictive 0600 permissions (owner read/write only)
- **Append Behavior**: If credentials file exists, new credentials are appended with blank line separator
- **Graceful Fallback**: If file save fails (RuntimeException), credentials are displayed on screen instead with error message
- **Authentication Method**: Uses scram-sha-256 for password authentication (modern, secure)
- **Connection String Format**: Uses `postgresql://` URI scheme compatible with most PostgreSQL clients

## Recent Changes

- Removed unused `SitesTrait` import and usage
- Added try-catch around `saveCredentialsToFile()` to handle filesystem exceptions gracefully, falling back to `displayCredentialsOnScreen()` on failure
