---
description: Advanced reasoning protocol for deep code comprehension
allowed-tools: Task, Read, Glob, Grep
model: inherit
---

<examples>
  <example name="analyze-file">
    user: "/deep-impact app/Services/PaymentService.php"
    assistant: "Building deep understanding of PaymentService following the protocol."
  </example>
  <example name="new-feature">
    user: "/deep-impact create a webhook system that notifies external services"
    assistant: "I'll follow the Deep Impact protocol to understand relevant code before planning."
  </example>
  <example name="modification">
    user: "/deep-impact add OAuth support to the auth module"
    assistant: "Applying deep analysis to auth module before planning OAuth changes."
  </example>
</examples>

# Deep Impact Protocol

Instructs AI agents to achieve rigorous code comprehension before planning or implementation. This protocol produces the mental model needed for confident action on complex code.

**Use when:**

- **Analyzing existing code** — Understand files before modification
- **Planning new features** — Identify integration points and contracts
- **Complex changes** — Build mental model before confident action

**Key distinction from Explore agents:**

- Explore agents → find files, surface patterns, answer questions
- Deep Impact → build complete mental models for confident action

<protocol>

  <important>

    This protocol complements the Explorer agents and should be followed AFTER exploration.

    It should be followed ESPECIALLY after reading actual source code files.

    Even more importantly, follow this protocol even if there are NO schematic files.

    You can run this protocol at ANY TIME, even during Plan mode:

    - consider schematics like plans, they're not part of the project per se;
    - Deep Understanding helps build superior action plans

  </important>

  <step name="schematics">
    **MANDATORY FIRST STEP** — Check `.claude/schematics/{mirrored-path}/{file}.md` for existing schematic.

    **If exists:** Read it completely for logic flow, dependencies, side effects.

    **If missing:** Spawn schematics-agent to create it first:

    ```
    subagent_type: schematics-agent
    prompt: "Create schematic for {file_path}"
    ```

    **GATE:** Do NOT proceed to Step 2 until you have read a schematic. Your report must reference the schematic path and status (existed/created).

  </step>

  <step name="mental-model">
    Build complete mental model:

    - Read target file and schematic completely
    - Trace dependencies (files target imports/uses)
    - Trace dependents (files that import/use target)
    - Map data flow (input → transform → output)
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

- Always check for existing schematic BEFORE reading source code
- Reference schematic path and status in every report
- Trace ALL execution paths, not just the happy path
- Identify contracts (implicit promises to callers)
- Map state mutations in order of occurrence

## Constraints

- Never proceed past schematics step without reading one
- Never skip execution path analysis for "simple" code
- Never assume understanding without virtual execution
- Report must include Schematics section with path and status
