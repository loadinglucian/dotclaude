---
paths: .claude/**
---

# Prompt Engineering Rules

Rules for writing effective prompts based on Anthropic's official documentation.

## Document Structure

Markdown headers and formatting provide semantic structure that's both human-readable and AI-parseable.

**Core principles:**

- Use semantic header names (`## Instructions`, `## Context`, not `## Section 1`)
- Be consistent—same section names throughout the file
- Reference sections explicitly: "Following the instructions above..."
- Use header hierarchy for nesting: H2 → H3 → H4

**Standard sections:**

| Section | Purpose |
|---------|---------|
| `## Context` | Background information |
| `## Instructions` | Task directives |
| `## Examples` | Container for example subsections |
| `### Example: {name}` | Single named example |
| `## Protocol` | Multi-step execution workflow |
| `### Step N: {name}` | Named step within protocol |
| `## {Name} Report` | Structured output template (as code block) |
| `## Standards` | Quality requirements |
| `## Constraints` | Guardrails and limitations |
| `> **IMPORTANT**` | Critical information blockquote |

## Information Architecture

Position matters—up to 30% quality improvement in tests.

**Ordering (top to bottom):**

1. Role/persona (if using system prompt pattern inline)
2. Context and background
3. Long documents/data (20K+ tokens)
4. Examples
5. Instructions
6. Query/task (ALWAYS last)

```markdown
## Context

{{BACKGROUND}}

## Documents

### Document 1: report.pdf

{{CONTENT}}

## Examples

### Example: Ticket Classification

Input: The dashboard loads slowly
Category: Performance
Sentiment: Negative

## Instructions

1. Analyze the documents above
2. Focus on X, Y, Z

What are the key findings?  <!-- Query last -->
```

## Examples (Multishot)

3-5 diverse examples dramatically improve output quality.

**Requirements:**

- Relevant: Mirror actual use case
- Diverse: Cover edge cases, vary enough to avoid unintended pattern matching
- Clear: Each example has its own header

```markdown
## Examples

### Example: Performance Issue

Input: The dashboard loads slowly
Category: Performance
Sentiment: Negative
Priority: High

### Example: Positive Feedback

Input: Love the new dark mode!
Category: UI/UX
Sentiment: Positive
Priority: Low

### Example: Feature Request

Input: Please add Slack integration
Category: Feature Request
Sentiment: Neutral
Priority: Medium
```

**For code examples with correctness labels:**

```markdown
### Example: Correct DI Usage

```php
$result = $container->build(Service::class);
```

### Example: Wrong (Breaks DI)

```php
$result = new Service(new Dependency());  // breaks DI
```
```

## Chain of Thought

Explicit thinking improves accuracy for complex tasks. Three levels:

**Basic:** Add "Think step-by-step" (minimal guidance)

**Guided:** Outline specific reasoning steps

```text
Think before answering:
1. Identify the core problem
2. List possible approaches
3. Evaluate trade-offs
4. Select and justify your recommendation
```

**Structured:** Request specific output sections

```text
First explain your reasoning in a "## Thinking" section.
Then provide your final answer in a "## Answer" section.
```

**When to use:** Math, logic, multi-step analysis, complex decisions.

**When to skip:** Simple lookups, formatting tasks, direct questions.

## Role Prompting

Roles dramatically improve domain-specific performance.

**Pattern:**

- System parameter: Role definition only
- User turn: Task instructions and data

```text
System: You are a senior security engineer specializing in
application security for financial services.

User: Review this authentication code for vulnerabilities:

## Code

{{CODE}}
```

**Tips:**

- Specific roles outperform generic ("senior security engineer at a Fortune 500 bank" > "security expert")
- Include relevant context (industry, company size, constraints)

## Prefill Techniques

Start Claude's response to control output format.

**JSON output—prefill with `{`:**

```text
User: Extract name and email as JSON: {{TEXT}}
Assistant: {
```

**Maintain character—prefill with role marker:**

```text
User: What do you observe?
Assistant: [Detective Holmes]
```

**Skip preamble—prefill with content start:**

```text
User: Write a haiku about code
Assistant: Silent keystrokes fall
```

**Note:** Prefill unavailable with extended thinking mode.

## Prompt Chaining

Break complex tasks into subtasks for better accuracy and traceability.

**When to chain:**

- Multi-step analysis
- Content pipelines (Research -> Outline -> Draft -> Edit)
- Tasks requiring verification
- Complex transformations

**Pattern:**

```text
Prompt 1: Analyze -> Output in "## Analysis" section
Prompt 2: Using the analysis, draft -> Output in "## Draft" section
Prompt 3: Review the draft, provide "## Feedback"
Prompt 4: Revise the draft based on feedback
```

**Self-correction chain:**

```text
1. Generate initial output
2. Grade/review output (separate prompt)
3. Refine based on feedback (separate prompt)
```

## Grounding in Quotes

For long documents, have Claude quote first, then reason.

```text
## Documents

{{LONG_CONTENT}}

Find quotes relevant to the user's complaint and list them in a
"## Relevant Quotes" section. Then, based on these quotes, provide
your analysis in a "## Analysis" section.
```

This reduces hallucination and improves accuracy on long-context tasks.

## Extended Thinking

For complex STEM, constraint optimization, or deep analysis.

**Tips:**

- Start with general instructions, add specifics only if needed
- Minimum 1024 token budget; start small, increase as needed
- Don't pass thinking back to Claude
- Ask Claude to verify its work with test cases

```text
Think deeply about this problem. Consider multiple approaches.
If your first method doesn't work, try alternatives.
Before finalizing, verify your solution against these test cases:
- Edge case 1
- Edge case 2
```

## Writing Style

**Prefer:**

```text
Commands handle I/O. Services contain logic. No circular dependencies.
```

**Over:**

```text
Commands are responsible for handling all user interaction including
input and output operations, while Services provide the core business
logic functionality.
```

**Hierarchy:**

1. Code examples (most efficient)
2. Imperative bullets
3. Short declarative sentences
4. Tables (reference data only)
5. Prose (last resort)

## Compliance Reports

Use report templates in code blocks to enforce rule compliance and verification.

````markdown
## Verification Report

```
**[Constraint]:** PASS | FAIL (value)
**[Details]:** findings

**Proceeding with:** [next action] | **Blocked by:** [issue]
```
````

## Agent & Command Structure

Template for `.claude/agents/` and `.claude/commands/` files.

### Agent Frontmatter

Agents include usage examples in the description field (matching Anthropic agent builder pattern). Use `\n` for newlines since YAML frontmatter doesn't support literal newlines.

````yaml
---
name: {agent-name}
description: "{Purpose description}\n\nExamples:\nuser: \"{example input}\"\nassistant: \"{expected response}\"\n\nuser: \"{another input}\"\nassistant: \"{another response}\""
model: inherit
color: cyan
---
````

### Command Frontmatter

Commands have examples in the body (not in description).

````yaml
---
description: {One-line description of purpose and when to use}
allowed-tools: {tool list}
model: inherit
---
````

### Body Structure

**For agents** (examples in frontmatter, not body):

````markdown
# {Role Title}

{One-line role description}

## Protocol

### Step 1: {Step Name}

{Instructions for this step}

### Step 2: {Next Step}

{Instructions for next step}

### Step 3: Report

Output using {Report Name} format below.

## {Report Name}

```
{Structured output template with placeholders}
```

## Standards

- {Quality requirement 1}
- {Quality requirement 2}

## Constraints

- {Guardrail 1}
- {Guardrail 2}
````

**For commands** (include examples in body):

````markdown
# {Role Title}

{Description}

## Examples

### Example: {Use Case 1}

**user:** "{invocation}"

**assistant:** "{expected response}"

## Protocol

{Same structure as agents...}
````

### Protocol Pattern

Use `## Protocol` + `### Step N:` for multi-step workflows:

- **`## Protocol`**: Wrapper header for entire execution flow
- **`### Step N: {Name}`**: Named, numbered checkpoint (mandatory, not advisory)
- Steps execute sequentially unless specified otherwise
- Final step should reference report template

```markdown
## Protocol

### Step 1: Gather

Collect required information...

### Step 2: Analyze

Process the gathered data...

### Step 3: Report

Output using Report format below.
```

**Why this works:** Numbered steps with descriptive names create clear execution sequences that Claude follows reliably.

### Important Callouts

Use blockquotes for critical information that must not be ignored:

```markdown
> **IMPORTANT**
>
> - Critical rule 1
> - Critical rule 2
```

## Model Selection

Choose the appropriate model based on task complexity:

### Use `model: haiku`

Fast, cost-efficient tasks that follow templates or run commands:

| Pattern | Examples |
|---------|----------|
| **Tool runners** | Linters, formatters, build tools |
| **Template transformers** | Tone adjustment, format conversion |
| **Pure orchestrators** | Spawning other agents without analysis |
| **Procedural workflows** | Git commands, file operations |

### Use `model: inherit` (Sonnet/Opus)

Tasks requiring reasoning, analysis, or judgment:

| Pattern | Examples |
|---------|----------|
| **Static analysis** | Bug detection, security review |
| **Code understanding** | Schematics, documentation |
| **Decision making** | Commit message writing, PR triage |
| **Complex synthesis** | Combining multiple sources |

### Sub-Agent Pattern

For multi-agent workflows, use the Anthropic-recommended pattern:

- **Orchestrator**: Sonnet/Opus breaks down the problem
- **Workers**: Haiku executes parallel subtasks

This matches the `pr-triage` pattern where the orchestrator spawns parallel analysis agents.

### Standards & Constraints

End every agent/command with quality bars and guardrails:

```markdown
## Standards

- {What quality looks like}
- {Required behaviors}
- {Output expectations}

## Constraints

- {What NOT to do}
- {Scope limitations}
- {Safety guardrails}
```

## Quality Gate

After writing prompts or `.claude/` files:

```bash
wc -l <file>                              # Line count
wc -c <file> | awk '{print int($1/4)}'    # Token estimate
```

### General Prompts

```
**Document Structure:** PASS | FAIL (are sections semantic and consistent?)
**Information Order:** PASS | FAIL (data before query?)
**Examples:** PASS | FAIL | N/A (3-5 diverse examples if needed?)
**Clarity:** PASS | FAIL (colleague test—would they understand?)

**Proceeding with:** [action] | **Blocked by:** [issue]
```

### Agent/Command Files

```
**Frontmatter Examples:** PASS | FAIL (2-3 diverse examples?)
**Protocol Structure:** PASS | FAIL (## Protocol + ### Step N: pattern?)
**Report Template:** PASS | FAIL (code block template defined?)
**Standards Section:** PASS | FAIL (quality bars defined?)
**Constraints Section:** PASS | FAIL (guardrails defined?)

**Proceeding with:** [action] | **Blocked by:** [issue]
```
