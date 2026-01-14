# AI Rules

> **IMPORTANT**
>
> - **All rules ARE MANDATORY**: Never ignore or skip ANY rules, context, instructions, or examples.
> - **No AI Attribution**: No "Generated with", "Co-Authored-By", or AI model references in code, comments, documentation, or commits.
> - **Git Safety**: Never commit/push directly to main or master. Always use a dedicated branch.

## Examples

### Example: Before Modifying

**user:** "Add a new SyncCommand similar to DeployCommand"

**assistant:** "Reading DeployCommand.php to understand the pattern...

```
## Understanding
| Attribute    | Value                              |
| ------------ | ---------------------------------- |
| Purpose      | Deploy application to server       |
| Type         | Command                            |
| Complexity   | Medium                             |
| Dependencies | SshTrait, ServerRepository         |
| Dependents   | None (CLI entry point)             |

## Execution Paths
- `execute()`: validate args -> connect SSH -> run deploy script -> report status

## Key Patterns
- Uses SshTrait for remote operations
- Follows execute->validate->run pattern
```

Now I can plan the SyncCommand."

### Example: After Modifying

**user:** "I've updated ServerService.php, can you check it?"

**assistant:** "Spawning linting-agent to verify code style and static analysis..."

## Context

### Code Philosophy

- **Minimalism:** Write minimum code necessary. Eliminate single-use methods. Cache computed values.
- **Organization:** Group related functions into comment-separated sections. Order alphabetically after grouping.
- **Consistency:** Same style throughout. Code should appear written by single person.

### Consistency Patterns

Look for and match existing patterns (command, service, trait, playbook):

1. **Match execution order** - Operations, variable retrieval, and logic blocks in same sequence
2. **Match variable placement** - Fetch values at the same relative point in the flow
3. **No undocumented deviations** - Don't introduce "improvements" that break structural alignment
4. **Same abstractions** - If reference uses array, use array; if reference uses early return, use early return

**Consistency means structure, not just features.** To match a pattern, replicate HOW it works, not just WHAT it does.

## Instructions

### References

- Check deps (eg. `composer.json`, `package.json`, etc.) for installed packages
- Plan with features from installed major versions ONLY

### Test Separately

- Don't run, create, or update tests UNLESS explicitly instructed
- Tests have enough complexity that they deserve dedicated attention and consideration

### Normal Workflow

**Scope:** `*.php`, `*.sh`, `*.js`, `*.ts` - not docs/config/lock files

#### Before Modifying Code

1. Explore to identify relevant files
2. Read and understand the target code thoroughly
3. Trace dependencies and data flow
4. Output a report block with your understanding

**No report = not ready to code or write plan.**

#### After Modifying Code

Spawn `linting-agent` via Task tool to auto-detect and run project linters.

## Standards

- Build thorough understanding before writing plans or code changes
- Spawn linting-agent after modifications
- Match existing patterns exactly - structure, not just features
- Maintain single-author consistency across all code
- Use project dependencies only - no undocumented external tools

## Constraints

- Never commit directly to main/master branches
- Never include AI attribution in any output
- Never run tests unless explicitly instructed
- Never deviate from established patterns without documentation
- Never skip protocol steps - they are mandatory checkpoints
- Scope limited to code files (eg. `*.php`, `*.sh`, `*.js`, `*.ts`, etc.)
