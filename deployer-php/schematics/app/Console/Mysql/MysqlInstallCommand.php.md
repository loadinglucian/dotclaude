# Schematic: MysqlInstallCommand.php

> Auto-generated schematic. Last updated: 2025-12-19

## Overview

`MysqlInstallCommand` installs MySQL server on a selected server via the `mysql-install.sh` playbook. It handles server selection, credential output preferences (display or save to file), playbook execution, and secure credential storage with proper file permissions.

## Logic Flow

### Entry Points

| Method | Purpose |
|--------|---------|
| `configure()` | Defines CLI options: `--server`, `--display-credentials`, `--save-credentials` |
| `execute()` | Main execution: server selection, credential preference, playbook execution, output |

### Execution Flow

```
1. Display heading "Install MySQL"

2. Select server via selectServerDeets() [ServersTrait]
   ├─ Validates server exists
   ├─ Retrieves server info (distro, permissions)
   └─ Returns ServerDTO with info or FAILURE

3. Validate credential output options (mutually exclusive)
   ├─ Both provided → Error, return FAILURE
   ├─ Neither provided → Interactive prompt for choice
   │   ├─ 'display' → Set displayCredentials = true
   │   └─ 'save' → Prompt for file path
   └─ One provided → Use that option

4. Execute mysql-install playbook via executePlaybook() [PlaybooksTrait]
   ├─ SSH executes playbook on remote server
   └─ Returns parsed YAML or FAILURE

5. Handle installation result
   ├─ Fresh install → Validate and output credentials
   │   ├─ Missing credentials → Error, return FAILURE
   │   ├─ displayCredentials → Display on screen
   │   └─ saveCredentialsPath → Try save to file
   │       ├─ Success → File saved with 0600 permissions
   │       └─ Failure → Catch exception, fallback to display on screen
   └─ Already installed (already_installed: true) → Show info message, skip credentials

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
| 113 | `!($result['already_installed'])` | Output credentials | Show info message |
| 117 | Root or deployer pass is null/empty | Error, return FAILURE | Output credentials |
| 132 | `$displayCredentials` is true | Display on screen | Try save to file |
| 144 | `saveCredentialsToFile()` throws | Fallback to display | File saved successfully |

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
    subgraph Command["MysqlInstallCommand"]
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
        PLAY["mysql-install.sh"]
        MYSQL["MySQL Server"]
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
    PLAY -->|"install"| MYSQL
    PLAY -->|"YAML response"| PT

    EXEC --> DISP
    DISP --> CONSOLE

    EXEC --> SAVE
    SAVE --> FS
    SAVE --> NOW
    FS --> FILE
    SAVE -.->|"exception"| DISP
```

## Sequence Diagram

```mermaid
sequenceDiagram
    participant User
    participant Cmd as MysqlInstallCommand
    participant ST as ServersTrait
    participant PT as PlaybooksTrait
    participant SSH as SshService
    participant FS as FilesystemService
    participant Remote as Remote Server

    User->>Cmd: mysql:install
    Cmd->>ST: selectServerDeets()
    ST->>SSH: server-info.sh
    SSH->>Remote: Execute playbook
    Remote-->>SSH: Server info YAML
    SSH-->>ST: Parsed info
    ST-->>Cmd: ServerDTO with info

    Cmd->>User: Credential output preference?
    User-->>Cmd: display/save choice

    Cmd->>PT: executePlaybook(mysql-install)
    PT->>SSH: Execute with spinner
    SSH->>Remote: Run mysql-install.sh
    Remote-->>SSH: Credentials YAML
    SSH-->>PT: Parsed result
    PT-->>Cmd: {root_pass, deployer_pass, ...}

    alt Display on screen
        Cmd->>User: Show credentials
        Cmd->>User: Warning to save them
    else Save to file
        Cmd->>FS: appendFile(credentials)
        alt File operation succeeds
            Cmd->>FS: chmod(0600)
            Cmd->>User: Confirmation message
        else File operation fails
            FS-->>Cmd: RuntimeException
            Cmd->>User: Error message
            Cmd->>User: Fallback: Show credentials on screen
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
| `playbooks/mysql-install.sh` | Playbook | Executed remotely to install MySQL |
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
| `mysql-install.sh` YAML | Credentials | Generated root_pass, deployer_pass, etc. |

### Outputs

| Destination | Data | Format |
|-------------|------|--------|
| Console | Credentials display | Formatted text with connection string |
| File | Credentials | ENV format with comments |
| Console | Success/error messages | Via BaseCommand helpers |
| Console | Command replay | Non-interactive equivalent |

### Credential File Format

```env
# MySQL Credentials for {serverName}
# Generated: {timestamp}
# WARNING: Keep this file secure!

## Root Credentials (admin access)
MYSQL_ROOT_PASSWORD={rootPass}

## Application Credentials
MYSQL_DATABASE={deployerDatabase}
MYSQL_USER={deployerUser}
MYSQL_PASSWORD={deployerPass}

## Connection String
DATABASE_URL=mysql://{deployerUser}:{deployerPass}@localhost/{deployerDatabase}
```

### Side Effects

| Effect | Description |
|--------|-------------|
| MySQL installation | Remote server gets MySQL server + client installed |
| MySQL configuration | Root password set, deployer user/database created |
| File creation | Credentials file created with 0600 permissions (if save option) |
| File append | Credentials appended if file exists |
| Console output | Credentials displayed (if display option or save fails) |

## CLI Options

| Option | Type | Description |
|--------|------|-------------|
| `--server` | VALUE_REQUIRED | Server name from inventory |
| `--display-credentials` | VALUE_NONE | Show credentials on console |
| `--save-credentials` | VALUE_REQUIRED | Path to save credentials file |

## Helper Methods

### displayCredentialsOnScreen()

Outputs formatted credentials to console including:

- Root password
- Application credentials (database, username, password)
- MySQL connection string
- Warning to save credentials

### saveCredentialsToFile()

Saves credentials to file with security:

- Creates ENV-format file with comments
- Sets umask(0077) before write
- Uses `$this->fs->appendFile()` (creates or appends)
- Sets chmod 0600 after write
- Reports whether file was created or appended
- Throws `RuntimeException` on filesystem errors

### now()

Returns current timestamp for credential file header: `Y-m-d H:i:s T`

## Notes

- **Mutual Exclusivity**: `--display-credentials` and `--save-credentials` cannot be used together
- **Idempotent**: Playbook detects existing MySQL and returns `already_installed: true` without reinstalling
- **Already Installed Handling**: When MySQL is already installed, displays info message and skips credential output; no credential options added to command replay
- **File Security**: Credentials file uses restrictive 0600 permissions (owner read/write only)
- **Append Behavior**: If credentials file exists, new credentials are appended with blank line separator
- **Graceful Fallback**: If `saveCredentialsToFile()` throws a `RuntimeException`, the error is displayed and credentials are shown on screen instead
- **MariaDB Conflict**: The playbook checks for MariaDB conflict before installation (port 3306 shared)
