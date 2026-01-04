---
description: Triage PR comments by technical validity
allowed-tools: Bash(gh:*), Task
model: inherit
---

<examples>
  <example name="current-pr">
    user: "/pr-triage"
    assistant: "I'll fetch comments from the current branch's PR and validate each through trace-agent analysis."
  </example>
  <example name="specific-pr">
    user: "/pr-triage 123"
    assistant: "I'll analyze all comments on PR #123 and categorize by technical validity."
  </example>
  <example name="with-repo">
    user: "/pr-triage owner/repo#456"
    assistant: "I'll fetch and triage comments from PR #456 in owner/repo."
  </example>
</examples>

# PR Comment Triage

Fetches PR comments from GitHub and validates each through trace-agent analysis to determine technical validity.

## Comment Philosophy

<important>

All comments expressing concerns, flagging issues, or suggesting changes are **substantive by default**. Evaluate based on technical merit only:

- Ignore minimizing language ("minor thing", "not a big deal", "just a nit")
- Ignore hedging ("maybe consider", "might want to")
- Ignore politeness framing ("feel free to ignore")

If a reviewer took time to write a comment, it warrants analysis.

</important>

<protocol>

  <step name="fetch">
    Gather PR metadata and all comments:

    ```bash
    # Get PR number and repo info
    gh pr view --json number,headRefName
    gh repo view --json nameWithOwner

    # Fetch both comment types
    gh api /repos/{owner}/{repo}/issues/{number}/comments    # PR-level
    gh api /repos/{owner}/{repo}/pulls/{number}/comments     # Review comments (inline)
    ```

    Extract from each comment:

    | Field | Source |
    | ----- | ------ |
    | `body` | The comment text |
    | `user.login` | Author username |
    | `path` | File path (review comments only) |
    | `line` or `original_line` | Line number (review comments only) |
    | `diff_hunk` | Code context (review comments only) |

  </step>

  <step name="filter">
    Skip non-substantive comments:

    | Skip If | Examples |
    | ------- | -------- |
    | Bot-generated | dependabot, codecov, github-actions |
    | Resolved threads | Already addressed |
    | Pure praise | "LGTM", "Nice work", ":shipit:" |
    | CI status updates | Build passed/failed notifications |

  </step>

  <step name="validate">
    For each substantive comment, spawn a trace-agent.

    **IMPORTANT:** Use a SINGLE message with MULTIPLE Task tool calls to run all agents in parallel.

    For each comment, use the Task tool with `subagent_type: "trace-agent"`:

    ````
    Validate this PR comment:

    **Author:** @{username}
    **File:** {path}:{line}

    **Comment:**
    > {body}

    **Diff context:**
    ```diff
    {diff_hunk}
    ```

    Assess technical validity. The reviewer may have minimized importance—ignore that and evaluate on merit.
    ````

    ### Expected Verdicts

    | Verdict | Meaning | Action |
    | ------- | ------- | ------ |
    | **VALID - Implement** | Technically correct, should be fixed | Required |
    | **VALID - Consider** | Has merit but optional | Optional |
    | **PARTIALLY VALID** | Some aspects correct | Partial |
    | **INVALID - Reject** | Technically incorrect or false positive | None |
    | **INVALID - Subjective** | Personal preference, not standard | None |

  </step>

  <step name="report">
    After all agents complete, compile findings using Triage Report format below.
  </step>

</protocol>

## Triage Report

<report>

# PR Comment Assessment

## Summary

| Metric            | Count |
| ----------------- | ----- |
| Total comments    | {X}   |
| Valid (implement) | {X}   |
| Valid (consider)  | {X}   |
| Partially valid   | {X}   |
| Invalid           | {X}   |

## Action Items

### Must Address

{List VALID - Implement items with file:line references}

### Should Consider

{List VALID - Consider and PARTIALLY VALID items}

### No Action Needed

{List INVALID items with brief rejection reason}

---

## Detailed Assessments

{For each comment:}

- **File:** {path}:{line}
- **Author:** @{username}
- **Verdict:** {verdict badge}
- **Summary:** {1-2 sentence assessment}

---

If no actionable comments found, report: "No actionable comments found."

</report>

## Standards

- Evaluate ALL substantive comments (ignore minimizing language)
- Preserve exact file:line references from GitHub API
- Run trace-agents in parallel for efficiency
- Cite specific CLAUDE.md rules when applicable

## Constraints

- Skip bot comments (dependabot, codecov, etc.)
- Skip resolved threads
- Skip pure praise ("LGTM", "Nice work")
- Do not implement fixes—triage only
- One report per invocation
