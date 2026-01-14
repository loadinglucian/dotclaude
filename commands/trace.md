---
description: Trace files for bugs and edge cases
allowed-tools: Task, Read, Glob, Grep
model: haiku
---

<examples>
  <example name="single-file">
    user: "/trace app/Services/PaymentService.php"
    assistant: "I'll launch trace-agent to analyze PaymentService.php for bugs and edge cases."
  </example>
  <example name="directory">
    user: "/trace app/Services/"
    assistant: "I'll find source files in app/Services/ and analyze them in parallel."
  </example>
  <example name="multiple-files">
    user: "/trace src/auth.ts src/session.ts"
    assistant: "I'll analyze both auth.ts and session.ts in parallel for potential issues."
  </example>
</examples>

# Trace Orchestrator

Coordinates parallel trace-agent analysis across multiple files to identify bugs, edge cases, and potential issues.

<protocol>

  <step name="parse">
    Extract files to analyze from `$ARGUMENTS`:

    - **Specific file paths:** Use those files directly
    - **Directory path:** Find relevant source files (exclude tests, vendors, node_modules)
    - **Empty arguments:** Prompt user to specify files or directories

    Validate all file paths exist before proceeding.

  </step>

  <step name="launch">
    Spawn trace-agents in parallel for each file.

    **IMPORTANT:** Use a SINGLE message with MULTIPLE Task tool calls to analyze all files concurrently.

    For each file, use the Task tool with `subagent_type: "trace-agent"`:

    ```
    Analyze {file_path}. Follow your 4-phase execution protocol starting with Phase 1.

    Focus on:
    - Logic errors and edge cases
    - Null/undefined handling
    - Resource leaks
    - Race conditions
    - Security vulnerabilities
    - Error handling gaps
    ```

  </step>

  <step name="collect">
    After all agents complete:

    1. **Collect** all issues from trace-agent reports
    2. **Deduplicate** issues that appear in multiple files (same root cause)
    3. **Prioritize** by severity:

    | Priority | Issues |
    | -------- | ------ |
    | Critical | Security vulnerabilities, data loss, crashes |
    | High | Logic errors, resource leaks, race conditions |
    | Medium | Edge cases, error handling gaps |
    | Low | Code smell, minor improvements |

  </step>

  <step name="validate">
    For high-priority issues (Critical/High), perform quick validation:

    1. Read the referenced code location
    2. Verify the issue is reproducible/valid
    3. Discard false positives

  </step>

  <step name="report">
    Output using Trace Report format below.
  </step>

</protocol>

## Trace Report

<report>

## Trace Results

### Summary

| Metric   | Count |
| -------- | ----- |
| Files    | {X}   |
| Critical | {X}   |
| High     | {X}   |
| Medium   | {X}   |
| Low      | {X}   |

### Issues

| Priority | File   | Line   | Issue         | Suggested Fix |
| -------- | ------ | ------ | ------------- | ------------- |
| {badge}  | {file} | {line} | {description} | {fix}         |

For each issue, include:

- **File:Line** — Exact location
- **Priority** — Severity badge
- **Issue** — Clear description of the problem
- **Fix** — Concrete suggestion to resolve

If no issues found, report: "No issues found in analyzed files."

</report>

## Standards

- All files must exist before launching agents
- Cross-validate high-priority issues before reporting
- Deduplicate issues with same root cause
- Provide copy-paste-ready fix suggestions

## Constraints

- Exclude test files, vendors, node_modules by default unless explicitly requested
- Maximum 10 files per invocation (prompt user to narrow scope if more)
- Do not implement fixes—report only
- Do not scope-creep into related files unless tracing a specific issue
