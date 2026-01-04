# dotclaude

The Claude Code rules, commands, and agents I use.

## Installation

Symlink this repository to your Claude Code configuration directory:

```bash
ln -s /path/to/dotclaude ~/.claude
```

## Structure

```
~/.claude/
├── agents/           # Autonomous subagents (spawned via Task tool)
├── commands/         # User-invocable slash commands
├── rules/            # Context-triggered instructions
├── deployer-php/     # Project-specific config (synced to project .claude/)
│   ├── agents/       # Project-specific agents
│   ├── rules/        # Project-specific rules
│   └── schematics/   # Pre-generated code documentation
├── settings.json     # Claude Code configuration
└── statusline.sh     # Custom status bar script
```

## Agents

Agents are spawned by Claude using the Task tool. They run autonomously and return structured reports.

| Agent | Description |
|-------|-------------|
| `trace-agent` | Deep static analysis—traces execution paths, identifies bugs, validates PR comments |
| `schematics-agent` | Creates/updates code documentation with logic flow, dependencies, and Mermaid diagrams |
| `linting-agent` | Auto-detects and runs project linters (Rector, Pint, PHPStan, ESLint, Prettier, etc.) |

## Commands

Commands are invoked with `/command-name` in the Claude Code CLI.

| Command | Description |
|---------|-------------|
| `/git commit` | Create branch (if on main) and commit all changes with Conventional Commits |
| `/git push` | Push branch and open a draft PR on GitHub |
| `/git sync` | Rebase on upstream, update branches, delete stale branches |
| `/git ship` | Full pipeline: commit → push → merge → sync |
| `/pr-triage` | Fetch PR comments and validate each through trace-agent analysis |
| `/trace <files>` | Orchestrate parallel trace-agent analysis across multiple files |

## Rules

Rules activate based on file patterns. They provide context-specific instructions.

| Rule | Triggers On | Description |
|------|-------------|-------------|
| `ai-rules.md` | Always | Core workflow: Deep Understanding Protocol, post-change verification |
| `php-rules.md` | `**/*.php` | Yoda conditions, strict types, PSR-12, Symfony patterns |
| `js-rules.md` | `package.json` | Package manager detection (bun/pnpm/yarn/npm) |
| `pest-rules.md` | `tests/**/*.php` | Pest PHP testing conventions, AAA pattern, mocking |
| `docs-rules.md` | `docs/**/*.md` | Laravel-style documentation writing |
| `prompting-rules.md` | `.claude/**` | Prompt engineering patterns for writing agents/commands |

## Settings

The `settings.json` configures Claude Code behavior:

- **Model**: Opus
- **Output Style**: Explanatory (educational insights with code)
- **Status Line**: Custom script showing git branch and context usage
- **Permissions**: Auto-allow most tools, ask for destructive git operations, deny access to sensitive files

## Project-Specific Configuration

The `deployer-php/` directory contains Claude Code configuration specific to the [DeployerPHP](https://github.com/loadinglucian/deployer-php) project. This folder is symlinked into the project's `.claude/` directory.

### DeployerPHP Agents

| Agent | Description |
|-------|-------------|
| `docs-agent` | Syncs command documentation with implementation—compares schematics against docs and updates discrepancies |

### DeployerPHP Rules

| Rule | Triggers On | Description |
|------|-------------|-------------|
| `main.md` | Always | Architecture overview, DI patterns, exception handling conventions |
| `command.md` | `app/Console/**/*.php`, `app/Traits/**/*.php` | Symfony Console command patterns, input validation, non-interactive design |
| `playbook.md` | `playbooks/**` | Idempotent bash script conventions, YAML output, helper usage |
| `bats.md` | `tests/bats/**` | BATS functional testing with Lima VMs, multi-distro testing |
| `docs.md` | `docs/**/*.md` | Documentation writing style—no terminal output, scannable prose |

### DeployerPHP Schematics

Pre-generated code documentation for key classes (Container, BaseCommand, Traits, etc.). These schematics provide context for the Deep Understanding Protocol defined in `ai-rules.md`.

### Setup

To use with the DeployerPHP project:

```bash
ln -s ~/.claude/deployer-php /path/to/deployer-php/.claude
```

## License

MIT
