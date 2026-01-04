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

## License

MIT
