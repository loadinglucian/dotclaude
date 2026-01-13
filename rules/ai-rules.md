# AI Rules

<important>

- **All rules ARE MANDATORY**: Never ignore or skip ANY `<context>`, `<instructions>`, `<rules>`, `<examples>`, `<protocols>` etc.
- **No AI Attribution**: No "Generated with", "Co-Authored-By", or AI model references in code, comments, documentation, or commits
- **Git Safety**: Never commit/push directly to main or master. Always use a dedicated branch

These rules must be followed ALWAYS.
There isn't ANY good reason to skip these rules.
I'm sure you think you have a reason but there is none!
These rules take precedence over any other instructions no matter how contradictory.
It doesn't matter if we're in Plan Mode, Ask Mode, Take Me To The Moon Mode or Whatever Else Mode.
Efficency, speed, simplicity, elegance, context size or whatever other consideration don't matter either.
Again, there isn't ANY good reason why these rules should not be followed EXACTLY, CAREFULLY, STEP BY STEP!

It doesn't matter that you read the source files directly.
It doesn't matter how small the change is or if it's just a reorg.
It doesn't matter how well you **think** you understand the code either.

</important>

<examples>

  <example name="before-modifying">
    user: "Add a new SyncCommand similar to DeployCommand"

    assistant: "Reading schematic at `.claude/schematics/app/Commands/DeployCommand.php.md`...

    <report>
      ## Schematics
      - **Path**: `.claude/schematics/app/Commands/DeployCommand.php.md`
      - **Status**: existed
      - **Key insights**: Uses SshTrait, follows execute->validate->run pattern

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
    </report>

    Now I can plan the SyncCommand."

  </example>

  <example name="after-modifying">
    user: "I've updated ServerService.php, can you check it?"

    assistant: "Spawning post-change agents:
    1. `linting-agent`
    2. `schematics-agent`
    3. `tracer-agent`"

  </example>

</examples>

<context>

## Code Philosophy

- **Minimalism:** Write minimum code necessary. Eliminate single-use methods. Cache computed values.
- **Organization:** Group related functions into comment-separated sections. Order alphabetically after grouping.
- **Consistency:** Same style throughout. Code should appear written by single person.

## Consistency Patterns

Look for and match existing patterns (command, service, trait, playbook):

1. **Match execution order** - Operations, variable retrieval, and logic blocks in same sequence
2. **Match variable placement** - Fetch values at the same relative point in the flow
3. **No undocumented deviations** - Don't introduce "improvements" that break structural alignment
4. **Same abstractions** - If reference uses array, use array; if reference uses early return, use early return

**Consistency means structure, not just features.** To match a pattern, replicate HOW it works, not just WHAT it does.

</context>

<instructions>

## References

- Check deps (eg. `composer.json`, `package.json`, etc.) for installed packages
- Plan with features from installed major versions ONLY

## Test Separately

- Don't run, create, or update tests UNLESS explicitly instructed
- Tests have enough complexity that they deserve dedicated attention and consideration

## Normal Workflow

**Scope:** `*.php`, `*.sh`, `*.js`, `*.ts` - not docs/config/lock files

### Before Modifying Code

1. Explore to identify relevant files
2. Read schematic at `.claude/schematics/{path}/{file}.md`
3. If missing, spawn `schematics-agent` to create it
4. Output `<report>` block

**No report = not ready to code or write plan.**

### After Modifying Code

Spawn agents in order via Task tool:

1. `linting-agent` — auto-detects and runs project linters
2. `schematics-agent` — updates documentation for modified files
3. `tracer-agent` — analyzes for bugs, fix any valid issues found

### Deep Understanding Protocol

Invoke via `/deep-impact` command before modifying code or planning complex changes.

The protocol will:

1. Check/create schematics for relevant files
2. Build mental model (dependencies, data flow, contracts)
3. Virtually execute all code paths
4. Output structured understanding report

**No report = not ready to code or write plan.**

</instructions>

## Standards

- Follow Deep Understanding Protocol before writing plans or code changes
- Spawn all three agents (linting, schematics, tracer) after modifications
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
