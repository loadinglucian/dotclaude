# AI Rules

<important>

- **All rules ARE MANDATORY**: Ignoring or skipping ANY `<context>`, `<instructions>`, `<rules>`, `<examples>`, `<protocols>` etc. means disregarding direct user instructions, which you would NEVER EVER consider doing.
- **No AI Attribution**: No "Generated with", "Co-Authored-By", or AI model references in code, comments, documentation, or commits
- **Git Safety**: Never commit/push directly to main or master. Always use a dedicated branch

</important>

<examples>

  <example name="deep-understanding">
    user: "Explain how UserService.php works"

    <report>
      ## Schematics

      - **Path**: `.claude/schematics/app/Services/UserService.md`
      - **Status**: existed
      - **Key insights**:
        - Handles user CRUD and authentication
        - Emits events on create/delete
        - Caches user lookups for 1 hour

      ## Understanding

      | Attribute    | Value                                         |
      | ------------ | --------------------------------------------- |
      | Purpose      | User management and authentication            |
      | Type         | Service                                       |
      | Complexity   | Medium                                        |
      | Dependencies | UserRepository, CacheManager, EventDispatcher |
      | Dependents   | AuthController, ProfileController, AdminPanel |

      ## Execution Paths

      - `create()`: validate -> hash password -> persist -> dispatch UserCreated -> return
      - `authenticate()`: find by email -> verify password -> update last_login -> return token
      - `delete()`: check permissions -> soft delete -> dispatch UserDeleted -> clear cache
    </report>

  </example>

  <example name="consistency-pattern">
    user: "Add a new SyncCommand similar to DeployCommand"

    assistant: "I'll follow the existing pattern from DeployCommand exactly - matching execution order, variable placement, and abstractions. Let me first read the schematic at `.claude/schematics/app/Commands/DeployCommand.md` and trace the pattern before writing any code."

  </example>

  <example name="normal-workflow">
    user: "I've updated ServerService.php, can you check it?"

    assistant: "Following normal workflow after changes:
    1. Running `linting-agent` to ensure code quality passes
    2. Running `schematics-agent` to update the schematic documentation
    3. Running `tracer-agent` to detect bugs and edge cases

    Let me spawn these in order..."

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

**Before planning or changes:** Follow **Deep Understanding Protocol** below.

**Deep Understanding Protocol** mandatory regardless of perceived complexity.

**After changes:** Run in order:

1. `linting-agent` -> fix failures until passing
2. `schematics-agent` -> update schematics for modified files
3. `tracer-agent` -> fix valid issues

Process multiple files with parallel Task calls.

</instructions>

## Deep Understanding Protocol

Follow this protocol when deep understanding of code is required:

<protocol>

  <step name="schematics">
    Check `.claude/schematics/{mirrored-path}/{filename}.md` for existing schematic.

    **If exists:** Read for logic flow, dependencies, side effects.

    **If missing:** Create first:

    ```
    subagent_type: schematics-agent
    prompt: "Create schematic for {file_path}"
    ```

    Do NOT proceed until schematic is read.

  </step>

  <step name="mental-model">
    Build complete mental model:

    - Read target file and schematic completely
    - Trace dependencies (files target imports/uses)
    - Trace dependents (files that import/use target)
    - Map data flow (input -> transform -> output)
    - Identify contracts (promises to callers)

  </step>

  <step name="execution-paths">
    Virtually execute every path:

    | Category          | Check                                             |
    | ----------------- | ------------------------------------------------- |
    | Entry points      | Public methods, command handlers, event listeners |
    | Branch coverage   | Every if/else, switch/match, try/catch path       |
    | Loop boundaries   | Zero/single/many iterations, early exits          |
    | Exception flows   | Where thrown? All caught appropriately?           |
    | Null propagation  | Track nullable values through all paths           |
    | Type coercion     | Implicit conversion issues?                       |
    | State mutations   | What changes and in what order?                   |
    | Concurrent access | Race conditions possible?                         |

  </step>

  <step name="report">
    Output findings in this structure:

    <report>
      ## Schematics

      - **Path**: `.claude/schematics/{relative_path}.md`
      - **Status**: existed | created
      - **Key insights**: {2-3 bullets}

      ## Understanding

      | Attribute    | Value                                        |
      | ------------ | -------------------------------------------- |
      | Purpose      | {one-line description}                       |
      | Type         | Command | Service | Trait | Repository | DTO |
      | Complexity   | Low | Medium | High | Critical               |
      | Dependencies | {files this depends on}                      |
      | Dependents   | {files that depend on this}                  |

      ## Execution Paths

      {List entry points and paths traced}
    </report>

  </step>

</protocol>

## Standards

- Follow Deep Understanding Protocol before any code changes
- Run all three agents (tracer, linting, schematics) after modifications
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
