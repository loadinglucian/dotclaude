---
description: Triage PR comments by technical validity
allowed-tools: Bash(gh:*), Task, AskUserQuestion
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

  <step name="reply-prompt">
    After displaying the report, ask the user:

    "Would you like to reply to these comments on GitHub?"

    - **Yes** → Reply to all analyzed comments
    - **Yes, only [specific comments]** → User can specify which (e.g., "only the VALID ones", "just comment #3")
    - **No** → End without replying

    If No, end the command.
  </step>

  <step name="reply-post">
    Spawn `pr-comment` agents **IN PARALLEL** for all comments (or user-specified subset).

    **IMPORTANT:** Use a SINGLE message with MULTIPLE Task tool calls.

    For each comment to reply to, use the Task tool with `subagent_type: "pr-comment"`:

    ````
    Post a reply to this PR comment:

    **PR:** {owner}/{repo}#{pr_number}
    **Comment ID:** {comment_id}
    **Type:** {review_comment | issue_comment}
    **Original author:** @{username}

    **Our verdict:** {verdict}
    **Our assessment:** {summary}

    Reply with a friendly message that communicates our assessment.
    If VALID: thank them for the catch.
    If INVALID: kindly explain why the concern doesn't apply.
    ````

    After all agents complete, report total replies posted.
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

## Reply Tone

The `pr-comment` agent handles tone transformation. Expect replies to be **light-hearted and collaborative**, never dismissive or critical.

| Verdict | Tone Approach |
|---------|---------------|
| **VALID - Implement** | Grateful: "Great catch! You're absolutely right..." |
| **VALID - Consider** | Appreciative: "Thanks for flagging this! Good point worth considering..." |
| **PARTIALLY VALID** | Balanced: "You raise a fair point! Part of this checks out..." |
| **INVALID - Reject** | Friendly: "Thanks for looking at this! After tracing through, it looks like..." |
| **INVALID - Subjective** | Respectful: "Appreciate the suggestion! This one comes down to style preference..." |

**Key principles:**
- Always thank the reviewer for their time
- Use "we" language when discussing fixes
- Frame disagreements as discoveries, not corrections
- Keep it brief—save detailed explanations for follow-up if asked

### Example Replies

**VALID - Implement:**
> Great catch! You're right—the null check is missing here. We'll get this fixed.

**INVALID - Reject:**
> Thanks for looking at this! After tracing through the code, it turns out the validation happens upstream in `UserService.php:45`, so we're covered here. Good instinct though!

**INVALID - Subjective:**
> Appreciate the suggestion! This one's more of a style call—we've been following the existing pattern in the codebase, but totally see where you're coming from.

## Standards

- Evaluate ALL substantive comments (ignore minimizing language)
- Preserve exact file:line references from GitHub API
- Run trace-agents in parallel for efficiency
- Cite specific CLAUDE.md rules when applicable

## Constraints

- Skip resolved threads
- Skip pure praise ("LGTM", "Nice work")
- Do not implement fixes—triage only
- One report per invocation
