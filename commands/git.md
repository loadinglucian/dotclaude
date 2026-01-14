---
description: Git workflow commands (commit, push, sync, ship)
allowed-tools: Bash(git:*), Bash(gh:*)
model: haiku
---

# Git Workflow Automation

Handles branch management, commits, PRs, and repository sync with Conventional Commits format.

## Examples

### Example: Commit

**user:** "/git commit"

**assistant:** "I'll create a branch if on main, then commit all changes with conventional commit messages."

### Example: Push

**user:** "/git push"

**assistant:** "I'll push the branch and create a PR on GitHub."

### Example: Sync

**user:** "/git sync"

**assistant:** "I'll rebase on upstream, update tracked branches, and delete stale branches."

### Example: Ship

**user:** "/git ship"

**assistant:** "I'll commit, push, create/merge PR, and sync—full end-to-end workflow."

## Dispatch

Parse `$ARGUMENTS` to determine which subcommand to run:

| Argument        | Action                       |
| --------------- | ---------------------------- |
| `commit`        | Jump to "Subcommand: commit" |
| `push`          | Jump to "Subcommand: push"   |
| `sync`          | Jump to "Subcommand: sync"   |
| `ship`          | Jump to "Subcommand: ship"   |
| (empty/unknown) | Output usage help below      |

```
Usage: /git <subcommand>

Subcommands:
  commit  Create branch (if needed) and commits from working tree changes
  push    Push branch and open PR on GitHub
  sync    Rebase sync with remote, update branches, delete gone branches
  ship    Full pipeline: commit → push → merge → sync
```

---

## Subcommand: commit

Create a branch (if on main) and commits based on working tree changes.

### Step 1: Identify

Run `git status` to see:

- Modified files (staged and unstaged)
- Untracked files
- Deleted files

Read relevant files to understand what changed and group them logically.

### Step 2: Branch

If on main branch, create a feature branch.

Use Conventional Commit types as branch prefixes:

| Type      | Use Case                             |
| --------- | ------------------------------------ |
| feat/     | New feature                          |
| fix/      | Bug fix                              |
| docs/     | Documentation only                   |
| style/    | Formatting, no logic change          |
| refactor/ | Code restructure, no behavior change |
| perf/     | Performance improvement              |
| test/     | Adding/updating tests                |
| build/    | Build system, dependencies           |
| ci/       | CI/CD configuration                  |
| chore/    | Maintenance tasks                    |
| revert/   | Reverting previous commit            |

Keep branch name short (≤ 50 chars) yet informative.

Examples:

- `feat/parser-add-php-84-attributes`
- `fix/ci-matrix-php-versions`
- `chore/deps-bump-composer-installers-2-3`

Do not push, pull, or rebase.

### Step 3: Commit

Create commits for ALL changes.

**IMPORTANT:** Nothing should be left uncommitted. Group related changes into cohesive commits (each independently meaningful).

Use Conventional Commits format:

- Keep titles short (≤ 72 chars), imperative, no trailing period
- Body (optional): explain motivation, context
- Use BREAKING CHANGE: for breaking changes

Examples:

- `feat(parser): add support for PHP 8.4 attributes`
- `fix(ci): correct matrix PHP versions in build workflow`
- `chore(deps): bump composer/installers to ^2.3`

### Step 4: Verify

Run `git status` again to confirm:

- Working tree is clean
- No untracked files remain
- No modified files remain

If anything is left uncommitted, create additional commits until working tree is clean.

Do not push, pull, or rebase.

### Step 5: Report

Output using Commit Report format below.

### Commit Report

```
## Commit Complete

| Metric        | Value         |
| ------------- | ------------- |
| Branch        | {branch_name} |
| Commits       | {count}       |
| Files changed | {count}       |

### Commits Created

- `{hash}`: {message}

### Working Tree

{Clean | Issues remaining}
```

---

## Subcommand: push

Push branch and open a PR on GitHub.

### Step 1: Push

Push the current branch to origin with tracking (`-u` flag).

Do not force push.

### Step 2: Check PR

Check for existing pull request:

```bash
gh pr list --head <current-branch> --json number,url
```

### Step 3: Create or Report

**If PR exists:** Output the existing PR URL and confirm pushed changes are added.

**If no PR exists:** Create a pull request:

```bash
gh pr create --title "<title>" --body "<body>"
```

**Title:** Use Conventional Commits format matching branch prefix (≤ 72 chars, imperative, no trailing period).

**Body:** Generate concise summary from commits:

- Brief description of what changed
- Key implementation details (if relevant)

**Base branch:** Target `main` unless branch name suggests otherwise.

### Step 4: Report

Output using Push Report format below.

### Push Report

```
## Push Complete

| Metric         | Value                            |
| -------------- | -------------------------------- |
| Branch         | {branch_name}                    |
| Commits pushed | {count}                          |
| PR Status      | {Created \| Updated \| Existing} |
| PR URL         | {url}                            |
```

---

## Subcommand: sync

Sync with remote using rebase, update all tracked branches, and delete branches with deleted upstreams.

### Step 1: Status

Check current branch and status:

```bash
git status
```

Determine:

- Current branch name
- Whether branch has upstream tracking
- Modified files (staged and unstaged)
- Untracked files

If no upstream tracking branch, skip to Phase 2.

### Step 2: Stash

If there are any modified or untracked files:

```bash
git stash push --include-untracked -m "Auto-stash for sync"
```

Remember stash state for later restoration.

### Step 3: Fetch

Fetch with prune:

```bash
git fetch --prune
```

This fetches latest and removes dead remote-tracking references.

### Step 4: Update Branches

Find all local branches with upstream tracking:

```bash
git branch -vv
```

For each branch (except current) that can be fast-forwarded:

```bash
git fetch origin remote_branch:local_branch
```

Skip branches requiring merge (not fast-forward).

### Step 5: Rebase

Rebase current branch on its upstream:

```bash
git rebase
```

**If conflicts:**

1. Abort: `git rebase --abort`
2. Restore stash if applicable: `git stash pop`
3. Inform user and exit with failure

### Step 6: Restore

If stashed earlier:

```bash
git stash pop
```

**If conflicts:** Inform user stash needs manual resolution and exit.

### Step 7: Switch Main

If not already on main:

```bash
git checkout main
```

(Try `master` if `main` doesn't exist)

### Step 8: Cleanup

Delete all local branches whose upstream is `[gone]`:

```bash
git for-each-ref --format '%(refname:short) %(upstream:track)' refs/heads | while read branch track; do
  if [ "$track" = "[gone]" ]; then
    git branch -D "$branch"
  fi
done
```

Track deleted branches for report.

### Step 9: Report

Output using Sync Report format below.

### Sync Report

```
## Sync Complete

| Metric           | Value            |
| ---------------- | ---------------- |
| Current branch   | {branch_name}    |
| Branches updated | {count}          |
| Branches deleted | {count}          |
| Stash            | {Applied \| N/A} |

### Deleted Branches

- {branch_name} (upstream gone)

### Remaining Branches

{Output of `git branch -vv`}
```

---

## Subcommand: ship

Complete end-to-end workflow: commit → push → merge → sync.

### Step 1: Commit Phase

Execute Subcommand: commit protocol:

1. Identify all changes
2. Create feature branch if on main
3. Create commits for ALL changes
4. Verify working tree is clean

### Step 2: Push Phase

Execute Subcommand: push protocol:

1. Push branch with tracking
2. Check for existing PR
3. Create draft PR if needed

### Step 3: Merge Phase

Merge the PR:

```bash
# Merge with admin privileges
gh pr merge <number> --squash --admin

# Delete remote branch
git push origin --delete <branch>
```

### Step 4: Sync Phase

Execute Subcommand: sync protocol:

1. Fetch with prune
2. Switch to main
3. Update main: `git pull --rebase`
4. Delete merged local branches

### Step 5: Report

Output using Ship Report format below.

### Ship Report

```
## Ship Complete

| Phase  | Status                  |
| ------ | ----------------------- |
| Commit | {count} commits created |
| Push   | Branch pushed           |
| PR     | {url}                   |
| Merge  | Squashed to main        |
| Sync   | Cleaned up              |

### Summary

- **Branch:** {branch_name}
- **Commits:** {count}
- **PR:** {url}
- **Merged to:** main
```

---

## Standards

- Use Conventional Commits format for branches and messages
- Create cohesive, independently meaningful commits
- Never leave uncommitted changes after `/git commit`
- Generate concise PR descriptions from commit messages
- Squash merge for clean history

## Constraints

- Never push to main/master directly
- Never force push
- Never use interactive flags (`-i`)
- Do not commit sensitive files (.env, credentials.json, etc.)
- Do not modify git config
- Do not skip hooks (`--no-verify`, `--no-gpg-sign`)
