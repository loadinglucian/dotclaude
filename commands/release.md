---
description: Release workflow (tag, changelog, push)
allowed-tools: Bash(git:*), Bash(gh:*), Read, Write, Edit, Glob
model: haiku
---

# Release Workflow Automation

Automates version tagging and changelog management following semver and keepachangelog specifications.

## Examples

### Example: Patch Release

**user:** "/release"

**assistant:** "I'll increment the patch version, update the changelog, create an annotated tag, and push to origin."

### Example: Minor Release

**user:** "/release minor"

**assistant:** "I'll increment the minor version (reset patch to 0), update the changelog, tag, and push."

### Example: Major Release

**user:** "/release major"

**assistant:** "I'll increment the major version (reset minor and patch to 0), update the changelog, tag, and push."

## Dispatch

Parse `$ARGUMENTS` to determine version increment:

| Argument        | Action                                |
| --------------- | ------------------------------------- |
| (empty)         | Increment patch (+0.0.1)              |
| `patch`         | Increment patch (+0.0.1)              |
| `minor`         | Increment minor (0.+1.0, reset patch) |
| `major`         | Increment major (+1.0.0, reset minor) |
| (unknown)       | Output usage help below               |

```
Usage: /release [major|minor|patch]

Arguments:
  major   Increment major version (X.0.0)
  minor   Increment minor version (0.X.0)
  patch   Increment patch version (0.0.X) [default]

Examples:
  /release         # 1.2.3 → 1.2.4
  /release patch   # 1.2.3 → 1.2.4
  /release minor   # 1.2.3 → 1.3.0
  /release major   # 1.2.3 → 2.0.0
```

---

## Protocol

### Step 1: Discover

Get the latest version tag:

```bash
git describe --tags --abbrev=0 2>/dev/null
```

Strip leading `v` if present (e.g., `v1.2.3` → `1.2.3`).

If no tags exist, use `1.0.0` as the initial version (skip increment calculation and validation).

### Step 2: Validate

**Skip this step if no tags exist (initial release).**

Check if there are commits since the last tag:

```bash
git log v{old_version}..HEAD --oneline
```

If the output is empty (no commits), abort with this message:

```
## No Changes to Release

There are no commits since v{old_version}. Nothing to release.

To see the current state:
  git log --oneline -5
  git describe --tags --abbrev=0
```

### Step 3: Calculate

If no tags exist, use `1.0.0` as the version and skip to Step 4.

Otherwise, parse the current version into components: `MAJOR.MINOR.PATCH`

Apply increment based on argument:

| Argument | Calculation                        |
| -------- | ---------------------------------- |
| major    | MAJOR+1, MINOR=0, PATCH=0          |
| minor    | MAJOR, MINOR+1, PATCH=0            |
| patch    | MAJOR, MINOR, PATCH+1              |

New version format: `{MAJOR}.{MINOR}.{PATCH}`

Tag format: `v{MAJOR}.{MINOR}.{PATCH}`

### Step 4: Changelog

**If this is the initial release (no previous tags):**

Create a simple changelog entry and skip to Step 4.4:

```markdown
## [1.0.0] - {YYYY-MM-DD}

First release.
```

**Otherwise, proceed with commit gathering:**

#### 4.1: Gather Commits

Get all commits since the last tag:

```bash
git log v{old_version}..HEAD --pretty=format:"%s" --reverse
```

#### 4.2: Categorize Commits

Map commit prefixes to keepachangelog sections:

| Commit Prefix | Changelog Section |
| ------------- | ----------------- |
| `feat:`       | Added             |
| `fix:`        | Fixed             |
| `security:`   | Security          |
| `deprecated:` | Deprecated        |
| Other         | Changed           |

Group commits by section. Skip empty sections.

#### 4.3: Format Entry

Create the changelog entry:

```markdown
## [{version}] - {YYYY-MM-DD}

### Added
- {feat commit messages}

### Fixed
- {fix commit messages}

### Security
- {security commit messages}

### Deprecated
- {deprecated commit messages}

### Changed
- {other commit messages}
```

Only include sections that have commits.

#### 4.4: Update CHANGELOG.md

Check if `CHANGELOG.md` exists:

**If exists:** Insert the new entry after the header (after the "All notable changes..." line).

**If not exists (initial release):** Create with simple format:

```markdown
# Changelog

## [1.0.0] - {YYYY-MM-DD}

First release.
```

**If not exists (subsequent release):** Create with header:

```markdown
# Changelog

{new entry}
```

### Step 5: Confirm

**Always require explicit user confirmation before proceeding.**

Present the release summary and ask for approval:

```
## Ready to Release

| Field   | Value         |
| ------- | ------------- |
| Current | v{old_version} |
| New     | v{version}    |
| Commits | {count}       |

### Changelog Preview

{changelog_entry}

---

Proceed with release? This will:
1. Commit CHANGELOG.md
2. Create annotated tag v{version}
3. Push commit and tag to origin
```

Wait for explicit user confirmation (e.g., "yes", "proceed", "do it").

If the user declines or requests changes, abort and provide guidance on how to adjust.

### Step 6: Tag

Create an annotated tag with the changelog entry as the message:

```bash
git add CHANGELOG.md
git commit -m "docs(changelog): add entry for v{version}"
git tag -a "v{version}" -m "{changelog_entry}"
```

### Step 7: Push

Push the tag and commit to origin:

```bash
git push origin HEAD
git push origin "v{version}"
```

### Step 8: Report

Output using Release Report format below.

---

## Release Report

```
## Release Complete

| Metric   | Value         |
| -------- | ------------- |
| Version  | {version}     |
| Tag      | v{version}    |
| Commits  | {count}       |
| Pushed   | Yes           |

### Changelog Entry

{changelog_content}
```

---

## Standards

- Use semantic versioning (MAJOR.MINOR.PATCH)
- Follow keepachangelog format for entries
- Create annotated tags with release notes
- Commit changelog before tagging

## Constraints

- Never create pre-release versions (alpha, beta, rc)
- Never force push tags
- Never modify existing tags
- Do not skip the changelog update
