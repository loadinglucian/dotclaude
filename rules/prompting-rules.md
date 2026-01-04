---
paths: .claude/**
---

# Prompt Engineering RULES

Rules for writing effective prompts based on Anthropic's official documentation.

## XML Structure

XML tags are the foundation of structured prompting. They improve parsing accuracy and enable clean output extraction.

**Core principles:**

- Use semantic tag names (`<instructions>`, `<context>`, `<data>`, not `<tag1>`)
- Be consistent—same tag names throughout prompt
- Reference tags explicitly: "Using the data in `<data>` tags..."
- Nest tags for hierarchy: `<outer><inner></inner></outer>`

**Standard tags:**

```xml
<instructions>   <!-- Task directives -->
<context>        <!-- Background information -->
<data>           <!-- Input data to process -->
<document>       <!-- Long-form content with <source> and <document_content> -->
<examples>       <!-- Container for multiple <example> tags -->
<example>        <!-- Single example -->
<thinking>       <!-- Chain of thought output -->
<answer>         <!-- Final response -->
<report>         <!-- Compliance/verification output -->
<protocol>       <!-- Multi-step execution workflow -->
<step>           <!-- Named step within protocol (use name attribute) -->
<important>      <!-- Critical information that must not be ignored -->
```

## Information Architecture

Position matters—up to 30% quality improvement in tests.

**Ordering (top to bottom):**

1. Role/persona (if using system prompt pattern inline)
2. Context and background
3. Long documents/data (20K+ tokens)
4. Examples
5. Instructions
6. Query/task (ALWAYS last)

```xml
<context>{{BACKGROUND}}</context>

<documents>
  <document index="1">
    <source>report.pdf</source>
    <document_content>{{CONTENT}}</document_content>
  </document>
</documents>

<examples>
  <example>...</example>
</examples>

<instructions>
1. Analyze the documents above
2. Focus on X, Y, Z
</instructions>

What are the key findings?  <!-- Query last -->
```

## Examples (Multishot)

3-5 diverse examples dramatically improve output quality.

**Requirements:**

- Relevant: Mirror actual use case
- Diverse: Cover edge cases, vary enough to avoid unintended pattern matching
- Clear: Wrapped in `<example>` tags

```xml
<examples>
  <example>
    Input: The dashboard loads slowly
    Category: Performance
    Sentiment: Negative
    Priority: High
  </example>
  <example>
    Input: Love the new dark mode!
    Category: UI/UX
    Sentiment: Positive
    Priority: Low
  </example>
  <example>
    Input: Please add Slack integration
    Category: Feature Request
    Sentiment: Neutral
    Priority: Medium
  </example>
</examples>
```

**For code examples:**

```xml
<example type="correct">
$result = $container->build(Service::class);
</example>

<example type="wrong">
$result = new Service(new Dependency());  // breaks DI
</example>
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

**Structured:** Use XML tags for parseable output

```text
Think through your analysis in <thinking> tags.
Then provide your final answer in <answer> tags.
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
<code>{{CODE}}</code>
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
Prompt 1: Analyze -> Output in <analysis> tags
Prompt 2: Using <analysis>, draft -> Output in <draft> tags
Prompt 3: Review <draft>, provide <feedback>
Prompt 4: Revise <draft> based on <feedback>
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
<documents>{{LONG_CONTENT}}</documents>

Find quotes relevant to the user's complaint and place them in
<quotes> tags. Then, based on these quotes, provide your analysis
in <analysis> tags.
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

Require `<report>` output to enforce rule compliance and verification.

```xml
<report>
**[Constraint]:** PASS | FAIL (value)
**[Details]:** findings

**Proceeding with:** [next action] | **Blocked by:** [issue]
</report>
```

## Agent & Command Structure

Template for `.claude/agents/` and `.claude/commands/` files.

### Frontmatter

````yaml
---
name: {agent-name}  # agents only
description: {One-line description of purpose and when to use}
allowed-tools: {tool list}  # commands only
model: inherit
color: cyan  # agents only
---
````

### Body Structure

````markdown
<examples>
  <example name="use-case-1">
    user: "{invocation}"
    assistant: "{expected response}"
  </example>
  <example name="use-case-2">
    user: "{invocation}"
    assistant: "{expected response}"
  </example>
</examples>

# {Role Title}

{One-line role description}

<protocol>

  <step name="step-name">
    {Instructions for this step}
  </step>

  <step name="next-step">
    {Instructions for next step}
  </step>

  <step name="report">
    Output using {Report Name} format below.
  </step>

</protocol>

## {Report Name}

<report>
{Structured output template with placeholders}
</report>

## Standards

- {Quality requirement 1}
- {Quality requirement 2}

## Constraints

- {Guardrail 1}
- {Guardrail 2}
````

### Protocol Pattern

Use `<protocol>` + `<step>` for multi-step workflows:

- **`<protocol>`**: Wrapper for entire execution flow
- **`<step name="...">`**: Named checkpoint (mandatory, not advisory)
- Steps execute sequentially unless specified otherwise
- Final step should reference report template

```xml
<protocol>
  <step name="gather">
    Collect required information...
  </step>
  <step name="analyze">
    Process the gathered data...
  </step>
  <step name="report">
    Output using Report format below.
  </step>
</protocol>
```

**Why this works:** Named steps create implicit state machines that Claude follows more reliably than markdown headers.

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

<report>
**XML Structure:** PASS | FAIL (are tags semantic and consistent?)
**Information Order:** PASS | FAIL (data before query?)
**Examples:** PASS | FAIL | N/A (3-5 diverse examples if needed?)
**Clarity:** PASS | FAIL (colleague test—would they understand?)

**Proceeding with:** [action] | **Blocked by:** [issue]
</report>

### Agent/Command Files

<report>
**Frontmatter Examples:** PASS | FAIL (2-3 diverse examples?)
**Protocol Structure:** PASS | FAIL (`<protocol>` + `<step>` tags?)
**Report Template:** PASS | FAIL (`<report>` block defined?)
**Standards Section:** PASS | FAIL (quality bars defined?)
**Constraints Section:** PASS | FAIL (guardrails defined?)

**Proceeding with:** [action] | **Blocked by:** [issue]
</report>
