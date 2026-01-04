# DeployerPHP Rules

We're building DeployerPHP, a server and site deployment tool for PHP -- a Composer package and CLI built on Symfony Console/

<context>

## Architecture

```mermaid
flowchart TD
    bin/deployer --> Container --> SymfonyApp --> Commands
    Commands --> Traits --> Services --> Repositories
    Services --> DTOs
    Commands -.-> playbooks[playbooks/]
```

```text
app/
├── Console/           # Commands
│   ├── Nginx/         # Nginx web server control
│   ├── Cron/          # Cron job management
│   ├── Mariadb/       # MariaDB service control
│   ├── Memcached/     # Memcached service control
│   ├── Pro/           # Provider integrations: keys + provisioning
│   │   ├── Aws/       # AWS EC2 integration
│   │   └── Do/        # DigitalOcean integration
│   ├── Mysql/         # MySQL service control
│   ├── Php/           # PHP-FPM service control
│   ├── Postgresql/    # PostgreSQL service control
│   ├── Redis/         # Redis service control
│   ├── Server/        # Server management
│   ├── Site/          # Site management
│   ├── Supervisor/    # Process management
│   └── Valkey/        # Valkey service control
├── Services/          # Business logic
│   ├── Aws/           # AWS API wrapper
│   └── Do/            # DigitalOcean API wrapper
├── Repositories/      # Inventory access
├── DTOs/              # Readonly data objects
├── Traits/            # Shared command behavior
├── Contracts/         # BaseCommand
├── Enums/             # Distribution enums
├── Exceptions/        # Custom exceptions
├── Container.php      # DI auto-wiring
└── SymfonyApp.php     # CLI registration
playbooks/             # Remote bash scripts
```

| Layer        | Purpose                       | I/O         |
| ------------ | ----------------------------- | ----------- |
| Commands     | Orchestrate user interaction  | Yes         |
| Traits       | Shared command operations     | Via Command |
| Services     | Business logic, external APIs | No          |
| Repositories | Inventory CRUD                | No          |
| playbooks/   | Remote server provisioning    | Via SSH     |

**Key Classes:**

- `Container` - DI auto-wiring via reflection
- `SymfonyApp` - Command registration, CLI entry
- `BaseCommand` - Command infrastructure (injected services)
- `ServerDTO`/`SiteDTO`/`SiteServerDTO`/`CronDTO`/`SupervisorDTO` - Immutable data objects
- `ServerRepository`/`SiteRepository` - Inventory access

**Command Domains:**

- Nginx (4): logs, restart, start, stop
- Cron (4): create, delete, logs, sync
- Mariadb (5): install, logs, restart, start, stop
- Memcached (5): install, logs, restart, start, stop
- Pro (8): aws:key:add, aws:key:delete, aws:key:list, aws:provision, do:key:add, do:key:delete, do:key:list, do:provision
- Mysql (5): install, logs, restart, start, stop
- Php (4): logs, restart, start, stop
- Postgresql (5): install, logs, restart, start, stop
- Redis (5): install, logs, restart, start, stop
- Scaffold (3): crons, hooks, supervisors
- Server (8): add, delete, firewall, info, install, logs, run, ssh
- Site (8): create, delete, deploy, https, logs, shared:pull, shared:push, ssh
- Supervisor (7): create, delete, logs, restart, start, stop, sync
- Valkey (5): install, logs, restart, start, stop

**External Integrations:**

```mermaid
flowchart LR
    Commands --> SshService --> phpseclib3
    Commands --> AwsService --> AWS-API
    Commands --> DoService --> DO-API
    Commands --> GitService --> git-cli
    Commands --> IoService --> laravel-prompts
```

</context>

<examples>

  <example name="di-production">
    ```php
    // Production - use container for all object creation except DTOs
    $service = $this->container->build(MyService::class);
    ```
  </example>

  <example name="di-testing">
    ```php
    // Tests - container supports bind() for mocks
    $container = new Container();
    $container->bind(SshService::class, $mockSSH);
    $command = $container->build(ServerAddCommand::class);
    ```
  </example>

  <example name="exception-service">
    ```php
    // Service - complete message with context
    throw new \RuntimeException("SSH key does not exist: {$privateKeyPath}");
    throw new \RuntimeException("Server '{$name}' already exists");

    // Preserve exception chain when wrapping
    } catch (\Throwable $e) {
        throw new \RuntimeException(
            "SSH authentication failed for {$username}@{$host}. Check username and key permissions",
            previous: $e
        );
    }
    ```

  </example>

  <example name="exception-command">
    ```php
    // Command - display directly, no prefix
    try {
        $this->servers->create($server);
    } catch (\RuntimeException $e) {
        $this->nay($e->getMessage());  // Already complete
        return Command::FAILURE;
    }
    ```
  </example>

  <example name="exception-wrong">
    ```php
    // WRONG - redundant prefix
    $this->nay('Failed to add server: ' . $e->getMessage());
    ```
  </example>

</examples>

<rules>

- Use `$container->build(ClassName::class)` for all object creation except DTOs/value objects
- Services throw complete, user-facing exceptions with context
- Commands display exception messages directly without adding prefixes
- Preserve exception chain with `previous: $e` when wrapping exceptions

</rules>
