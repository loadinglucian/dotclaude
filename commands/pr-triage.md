---
description: Triage PR comments by technical validity
allowed-tools: Bash(gh:*), Task, AskUserQuestion
model: inherit
---

# PR Comment Triage

Analyzes all changed files in a PR, then validates each comment with full cross-file context.

## Examples

### Example: Current PR

**user:** "/pr-triage"

**assistant:** "I'll analyze all changed files, then validate each comment with full context."

### Example: Specific PR

**user:** "/pr-triage 123"

**assistant:** "I'll fetch PR #123, analyze all changed files, then assess each comment."

### Example: With Repo

**user:** "/pr-triage owner/repo#456"

**assistant:** "I'll analyze PR #456 in owner/repo with full cross-file context."

## Comment Philosophy

> **IMPORTANT**
>
> All comments expressing concerns, flagging issues, or suggesting changes are **substantive by default**. Evaluate based on technical merit only:
>
> - Ignore minimizing language ("minor thing", "not a big deal", "just a nit")
> - Ignore hedging ("maybe consider", "might want to")
> - Ignore politeness framing ("feel free to ignore")
>
> If a reviewer took time to write a comment, it warrants analysis.

## Protocol

### Step 1: Fetch

Gather PR metadata, changed files, and all comments:

```bash
# Get PR number and repo info
gh pr view --json number,headRefName
gh repo view --json nameWithOwner

# Get all changed files
gh pr diff --name-only

# Fetch both comment types
gh api /repos/{owner}/{repo}/issues/{number}/comments    # PR-level
gh api /repos/{owner}/{repo}/pulls/{number}/comments     # Review comments (inline)

# Fetch CI check status
gh pr checks {number} --json name,state,conclusion,link,workflow,bucket
```

Extract from each comment:

| Field                     | Source                         |
| ------------------------- | ------------------------------ |
| `id`                      | Comment ID for replies         |
| `body`                    | The comment text               |
| `user.login`              | Author username                |
| `path`                    | File path (review comments)    |
| `line` or `original_line` | Line number (review comments)  |
| `diff_hunk`               | Code context (review comments) |
| CI checks                 | `gh pr checks` output          |
| Failed checks             | Filtered by `bucket: "fail"`   |

### Step 2: Deep Analysis

Analyze ALL changed files for comprehensive understanding.

**IMPORTANT:** Use a SINGLE message with MULTIPLE Task tool calls to analyze all files concurrently.

For each changed file, use the Task tool with `subagent_type: "general-purpose"`:

```
Build deep understanding of this file:

**File:** {file_path}

Execute these steps:
1. Read and understand the file thoroughly
2. Build mental model (dependencies, data flow, contracts)
3. Trace all execution paths
4. Output an Understanding Report

Focus on building comprehensive understanding for later comment validation.
```

**In the SAME message**, also spawn a CI analysis agent:

Use the Task tool with `subagent_type: "ci-agent"`:

```
Analyze CI status for this PR:

**PR:** {owner}/{repo}#{pr_number}
**Branch:** {head_ref}

Fetch workflow status and analyze any failures.
Focus on: test failures, lint errors, type errors, build failures.
```

After all agents complete, compile a unified understanding of the PR changes and CI status.

### Step 3: Filter

Skip non-substantive comments:

| Skip If           | Examples                        |
| ----------------- | ------------------------------- |
| Resolved threads  | Already addressed               |
| Pure praise       | "LGTM", "Nice work", ":shipit:" |
| CI status updates | Build passed/failed             |

### Step 4: Assess

For each substantive comment, assess validity using the accumulated understanding:

| Check             | Validation                                         |
| ----------------- | -------------------------------------------------- |
| Correctness       | Is the reviewer's assessment technically accurate? |
| Cross-file impact | Does comment account for related changes in PR?    |
| Project alignment | Does suggestion match CLAUDE.md and patterns?      |
| CI correlation    | Does comment align with or contradict CI findings? |

**CI-Informed Assessment:**

When CI data is available, factor it into verdicts:

| Scenario                                | Effect on Verdict                           |
| --------------------------------------- | ------------------------------------------- |
| Comment about failure + CI confirms     | Strengthen → VALID - Implement (CI-confirmed) |
| Comment claims bug + CI tests pass      | Note discrepancy, investigate further       |
| Comment about type error + CI lint fail | Strong VALID with CI evidence               |
| Comment claims broken + CI fully green  | May weaken → investigate if INVALID         |

Determine verdict for each:

| Verdict                  | Meaning                              | Action   |
| ------------------------ | ------------------------------------ | -------- |
| **VALID - Implement**    | Technically correct, should be fixed | Required |
| **VALID - Consider**     | Has merit but optional               | Optional |
| **PARTIALLY VALID**      | Some aspects correct, others not     | Partial  |
| **INVALID - Reject**     | Technically incorrect or false alarm | None     |
| **INVALID - Subjective** | Personal preference, not standard    | None     |

### Step 5: Report

Output findings using Triage Report format below.

### Step 6: Reply Prompt

After displaying the report, ask the user:

"Would you like to reply to these comments on GitHub?"

- **Yes** → Reply to all analyzed comments
- **Yes, only [specific comments]** → User can specify which
- **No** → End without replying

If No, end the command.

### Step 7: Reply Post

Spawn `pr-comment` agents **IN PARALLEL** for all comments (or user-specified subset).

**IMPORTANT:** Use a SINGLE message with MULTIPLE Task tool calls.

For each comment to reply to, use the Task tool with `subagent_type: "pr-comment"`:

```
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
```

After all agents complete, report total replies posted.

## Triage Report

```
# PR Comment Assessment

## Summary

| Metric            | Count |
| ----------------- | ----- |
| Files analyzed    | {X}   |
| Total comments    | {X}   |
| Valid (implement) | {X}   |
| Valid (consider)  | {X}   |
| Partially valid   | {X}   |
| Invalid           | {X}   |
| CI-correlated     | {X}   |

## CI Status

| Check | Status | Details |
|-------|--------|---------|
| {name} | {pass/fail/pending} | {failure reason or "—"} |

{If CI failures exist, note: "X comments correlated with CI findings"}

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
- **Cross-file context:** {relevant changes in other files, if any}
- **CI correlation:** {relevant CI check status, if any}

---

If no actionable comments found, report: "No actionable comments found."
```

## Reply Tone

The `pr-comment` agent handles tone transformation. Expect replies to be **light-hearted and collaborative**, never dismissive or critical.

| Verdict                  | Tone Approach                                                                       |
| ------------------------ | ----------------------------------------------------------------------------------- |
| **VALID - Implement**    | Grateful: "Great catch! You're absolutely right..."                                 |
| **VALID - Consider**     | Appreciative: "Thanks for flagging this! Good point worth considering..."           |
| **PARTIALLY VALID**      | Balanced: "You raise a fair point! Part of this checks out..."                      |
| **INVALID - Reject**     | Friendly: "Thanks for looking at this! After tracing through, it looks like..."     |
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

- Analyze ALL changed files before assessing any comments
- Evaluate comments with cross-file awareness
- Preserve exact file:line references from GitHub API
- Run analysis agents in parallel for efficiency
- Cite specific CLAUDE.md rules when applicable

## Constraints

- Skip resolved threads
- Skip pure praise ("LGTM", "Nice work")
- Do not implement fixes—triage only
- One report per invocation
- Maximum 20 files per PR (prompt user to narrow scope if more)
