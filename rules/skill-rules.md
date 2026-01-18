---
paths: .claude/skills/**/SKILL.md, skills/**/SKILL.md
---

# Skill Writing Rules

Rules for writing effective SKILL.md files that Claude auto-discovers and activates.

> **IMPORTANT**
>
> - **Name format**: Lowercase letters, numbers, hyphens only (max 64 chars). Must match directory name.
> - **Description is everything**: Claude uses description to decide when to activate—include keywords users would naturally say.
> - **Directory structure**: Each skill lives in its own folder with `SKILL.md` required.
> - **Progressive disclosure**: Keep SKILL.md under 500 lines. Reference supporting files for complex skills.

## Examples

### Example: Good Description

```yaml
---
name: pr-review
description: Review pull requests for code quality, security issues, and best practices. Use when asked to "review PR", "check my changes", or "look at this diff".
---
```

Why it works: Specific keywords ("review PR", "check my changes", "look at this diff") match natural user language.

### Example: Bad Description

```yaml
---
name: code-helper
description: Helps with code tasks.
---
```

Why it fails: Too vague—Claude can't distinguish when to activate this vs any other skill.

### Example: Directory Structure

```
.claude/skills/
└── deploy-checker/
    ├── SKILL.md              # Required: skill definition
    ├── checklist.md          # Optional: referenced content
    └── templates/            # Optional: supporting files
        └── report.md
```

SKILL.md references supporting files:

```markdown
## Protocol

### Step 1: Load Checklist

Read `checklist.md` in this skill's directory for deployment requirements.
```

### Example: Frontmatter with Tool Restrictions

```yaml
---
name: git-workflow
description: Git operations including commit, push, and branch management. Activate for "commit my changes", "push to remote", "create branch".
allowed-tools: Bash, Read, Glob
model: haiku
---
```

### Example: User-Invocable Skill

```yaml
---
name: format-code
description: Format code files using project formatters.
user-invocable: /format
---
```

User can type `/format` to invoke directly, or Claude activates based on context.

## Context

### Skills vs Commands vs Agents

| Aspect | Skills | Commands | Agents |
|--------|--------|----------|--------|
| Trigger | Auto (Claude decides) | Manual (`/name`) | Spawned via Task tool |
| Location | `skills/{name}/SKILL.md` | `commands/{name}.md` | `agents/{name}.md` |
| Discovery | Description-based | User invokes directly | Orchestrator spawns |
| Required frontmatter | `name`, `description` | `description` | `name`, `description` |

### How Skills Work

1. **Startup**: Claude loads only `name` and `description` from all SKILL.md files
2. **Matching**: When user request matches a description, Claude activates that skill
3. **Activation**: Full SKILL.md content loads into context
4. **Execution**: Claude follows the skill's instructions

### Frontmatter Reference

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Skill identifier (lowercase, hyphens, max 64 chars) |
| `description` | Yes | Activation trigger text (max 1024 chars) |
| `allowed-tools` | No | Restrict available tools (comma-separated) |
| `model` | No | `haiku`, `sonnet`, `opus`, or `inherit` (default) |
| `user-invocable` | No | Slash command alias (e.g., `/format`) |
| `context` | No | Additional context files to load |
| `agent` | No | Run as autonomous agent (`true`/`false`) |
| `hooks` | No | Lifecycle hooks (pre/post execution) |

### String Substitutions

Available variables in skill content:

| Variable | Expands To |
|----------|------------|
| `$ARGUMENTS` | User's input after skill activation |
| `${CLAUDE_SESSION_ID}` | Current session identifier |
| `${SKILL_DIR}` | Absolute path to skill directory |

```markdown
## Instructions

Process the user's request: $ARGUMENTS

Save output to: ${SKILL_DIR}/output/
```

## Instructions

### Creating a New Skill

1. Create directory: `.claude/skills/{skill-name}/`
2. Create `SKILL.md` with required frontmatter
3. Write description with activation keywords
4. Add instructions, optionally with Protocol pattern
5. Reference supporting files for complex content

### Writing Effective Descriptions

**Include:**

- Action verbs users would say ("review", "format", "deploy")
- Synonyms and variations ("check my code", "look at this", "review PR")
- Specific use cases ("when deploying to production")

**Avoid:**

- Generic terms ("helps with", "assists in")
- Technical jargon users wouldn't naturally say
- Overlapping keywords with other skills

### Progressive Disclosure Pattern

For complex skills, keep SKILL.md focused and reference supporting files:

```markdown
---
name: security-audit
description: Security audit for code and dependencies.
---

# Security Audit

Comprehensive security review following OWASP guidelines.

## Protocol

### Step 1: Load Checklists

Read the following from this skill's directory:
- `owasp-top-10.md` for vulnerability categories
- `dependency-audit.md` for package review steps

### Step 2: Execute Audit

Follow checklists systematically...
```

### Tool Restrictions

Use `allowed-tools` to limit skill scope:

```yaml
---
name: read-only-review
description: Code review without modifications.
allowed-tools: Read, Glob, Grep
---
```

Common restriction patterns:

| Pattern | Tools | Use Case |
|---------|-------|----------|
| Read-only | `Read, Glob, Grep` | Analysis, review |
| Git operations | `Bash, Read, Glob` | Version control |
| Full access | (omit field) | Complex tasks |

### Subagent Integration

Skills can be attached to agents via the agent's `skills` field:

```yaml
# In agents/code-reviewer.md
---
name: code-reviewer
description: Reviews code changes
skills: security-audit, style-check
---
```

The agent gains access to listed skills during execution.

## Standards

- Write descriptions that match natural user language
- Keep SKILL.md under 500 lines
- Use progressive disclosure for complex skills
- Include quick-start examples when helpful
- Test activation by asking Claude when it would use the skill
- Match naming conventions: lowercase, hyphens, descriptive

## Constraints

- Never bloat SKILL.md—offload to supporting files
- Never write vague descriptions ("helps with tasks")
- Never hardcode values that should use substitutions
- Never skip required frontmatter fields (`name`, `description`)
- Never create skills with overlapping activation keywords
- Never exceed 1024 characters in description field
