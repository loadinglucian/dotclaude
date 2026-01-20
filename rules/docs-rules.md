---
paths: docs/**/*.md, **/README.md
---

# Documentation Writing Rules

Rules for writing user documentation following Laravel's documentation style.

> **IMPORTANT**
>
> - **Reader-first**: Every sentence should help the reader accomplish their goal
> - **Active voice**: Use "you" to address the reader directly (~95% of sentences)
> - **Explain why before how**: Context precedes implementation details
> - **Simple to complex**: Start with basic usage, then layer in advanced features

## Examples

### Example: Opening Problem-Solution

```markdown
While building your web application, you may have some tasks that take too long
to perform during a typical web request. Thankfully, Laravel allows you to
easily create queued jobs that may be processed in the background.
```

### Example: Opening Conceptual

```markdown
Migrations are like version control for your database, allowing your team to
define and share the application's database schema definition.
```

### Example: Opening Feature

```markdown
Laravel includes Eloquent, an object-relational mapper (ORM) that makes it
enjoyable to interact with your database. When using Eloquent, each database
table has a corresponding "Model" that is used to interact with that table.
```

### Example: Convention Explanation

```markdown
After glancing at the example above, you may have noticed that we did not
tell Eloquent which database table corresponds to our `Flight` model. By
convention, the "snake case", plural name of the class will be used as the
table name unless another name is explicitly specified.
```

### Example: Quickstart Intro

```markdown
To learn about Laravel's powerful validation features, let's look at a
complete example of validating a form and displaying the error messages
back to the user. By reading this high-level overview, you'll be able to
gain a good general understanding of how to validate incoming request data.
```

### Example: Permissive Language

```markdown
You may use the `route:list` Artisan command to view all routes.
You are free to organize your application however you like.
```

### Example: Reassurance Pattern

```markdown
As you can see, the validation rules are passed into the `validate` method.
Don't worry - all available validation rules are documented. Again, if the
validation fails, the proper response will automatically be generated.
```

### Example: Code Progression

```php
// SIMPLE - Basic usage
Route::get('/greeting', function () {
    return 'Hello World';
});

// INTERMEDIATE - With controller
Route::get('/user', [UserController::class, 'index']);

// ADVANCED - Multiple HTTP verbs
Route::match(['get', 'post'], '/', function () {
    // ...
});
```

### Example: Alternatives Transition

```markdown
Alternatively, validation rules may be specified as arrays instead of a
single `|` delimited string:
```

### Example: Callout Note

```markdown
> [!NOTE]
> Blade's `{{ }}` echo statements are automatically sent through PHP's
> `htmlspecialchars` function to prevent XSS attacks.
```

### Example: Callout Warning

```markdown
> [!WARNING]
> Be very careful when echoing content that is supplied by users of your
> application. You should typically use the escaped syntax to prevent attacks.
```

## Context

### Voice & Tone

| Aspect      | Pattern                                                            |
| ----------- | ------------------------------------------------------------------ |
| Audience    | Direct ("you", "your") - never "the user" or "one"                 |
| Confidence  | High but humble - recommend without dictating                      |
| Formality   | Professional-casual - use contractions freely                      |
| Complexity  | Graduated (beginner -> advanced)                                   |
| Metaphors   | Frequent, always clarifying ("X is like Y for your Z")             |
| Pronoun mix | "You" for actions, "We" for exploration ("let's", "we will cover") |

**Contractions:** Use `let's`, `you'll`, `it's`, `don't`, `we'll`, `won't`, `can't` freely. This creates an approachable, conversational tone.

### Phrase Reference Tables

#### Permission & Capability

| Category    | Phrases                                                                       |
| ----------- | ----------------------------------------------------------------------------- |
| Permission  | "You may...", "You can also...", "You are free to..."                         |
| Capability  | "provides a convenient shortcut", "allows you to easily", "makes it easy to"  |
| Flexibility | "you may even", "you may also", "you may optionally"                          |
| Enablement  | "makes it enjoyable to", "provides a simple way to", "gives you full control" |

#### Defaults & Conventions

| Category    | Phrases                                                                |
| ----------- | ---------------------------------------------------------------------- |
| Defaults    | "By default...", "Unless otherwise specified...", "Typically..."       |
| Built-ins   | "includes...", "ships with...", "is included with...", "comes with..." |
| Conventions | "By convention...", "unless another name is explicitly specified"      |
| Location    | "is stored in your application's `config/X.php` configuration file"    |
| Discovery   | "In this file, you will find...", "you may have noticed that..."       |

#### Process & Transitions

| Category     | Phrases                                                                 |
| ------------ | ----------------------------------------------------------------------- |
| Starting     | "To get started...", "First, let's assume...", "Let's look at..."       |
| Continuing   | "Next, let's...", "Now that you have...", "Once you have..."            |
| Alternatives | "Alternatively...", "Or, you may...", "On the other hand..."            |
| Elaborating  | "In this example...", "As you can see...", "As mentioned previously..." |
| Deep dive    | "To get a better understanding of X, let's jump back into..."           |
| Rhetorical   | "So, what if...?" (to introduce edge cases or next concepts)            |

#### Emphasis & Reassurance

| Category      | Phrases                                                          |
| ------------- | ---------------------------------------------------------------- |
| Importance    | "It's important to understand...", "Remember...", "Note that..." |
| Reassurance   | "Don't worry - ...", "Again, if...", "It's a cinch!"             |
| Prerequisites | "Before getting started...", "be sure to configure..."           |
| Reminder      | "Remember, any...", "Keep in mind that..."                       |

#### Technical Descriptions

| Category     | Phrases                                                               |
| ------------ | --------------------------------------------------------------------- |
| Architecture | "provides a unified X API across a variety of different Y"            |
| Performance  | "adds essentially zero overhead to your application"                  |
| Conceptual   | "may be thought of as", "which can be thought of as"                  |
| Benefit      | "meaning...", "allowing your application to...", "so that you can..." |

## Instructions

### Document Structure

Every documentation file follows this structure:

1. **H1 Title** - Single main title
2. **Table of Contents** - Anchor links to all sections
3. **Introduction** - Problem-solution or conceptual overview
4. **Quickstart** (optional) - Complete working example before details
5. **Sections (H2)** - Major topics with anchor tags
6. **Subsections (H3/H4)** - Detailed subtopics

**Table of Contents format:**

```markdown
- [Main Section](#main-section)
  - [Subsection One](#subsection-one)
  - [Subsection Two](#subsection-two)
- [Another Section](#another-section)
```

Use 4-space indentation for nested items. Match anchor names to heading text in kebab-case.

**Anchor pattern:**

```markdown
<a name="section-name"></a>

## Section Name
```

**Quickstart sections:**

For feature documentation, include a "Quickstart" section early:

> To learn about Laravel's powerful validation features, let's look at a
> complete example of validating a form and displaying the error messages
> back to the user. By reading this high-level overview, you'll be able to
> gain a good general understanding of how to validate incoming request data.

This provides a complete working example before diving into individual features.

### Introduction Patterns

Three standard opening approaches:

**Problem-Solution Opening:**

> While building your web application, you may have some tasks that take too long
> to perform during a typical web request. Thankfully, [Product] allows you to
> easily create queued jobs that may be processed in the background.

Pattern: `While [context], you may [problem]. Thankfully, [product] allows you to [solution].`

**Conceptual/Metaphor Opening:**

> Migrations are like version control for your database, allowing your team to
> define and share the application's database schema definition.

Pattern: `[Feature] is like [familiar concept], allowing [benefit].`

**Feature Introduction Opening:**

> Laravel includes Eloquent, an object-relational mapper (ORM) that makes it
> enjoyable to interact with your database.

Pattern: `[Product] includes [feature], [descriptor] that [benefit].`

### Writing Patterns

#### Convention Explanations

When explaining default behavior:

> After glancing at the example above, you may have noticed that we did not
> tell Eloquent which database table corresponds to our `Flight` model. By
> convention, the "snake case", plural name of the class will be used as the
> table name unless another name is explicitly specified.

Pattern: `By convention, [default behavior] unless [override condition].`

Follow with code showing how to override:

> If your model's corresponding database table does not fit this convention,
> you may manually specify the model's table name by defining a `table`
> property on the model.

#### Prose Guidelines

**Sentence structure:**

- Average 15-20 words per sentence
- Mix simple, compound, and complex sentences
- Short declarative sentences for emphasis
- Break complex ideas into multiple shorter sentences

**Paragraph organization:**

- 2-4 sentences per paragraph
- Topic sentence first
- Code blocks follow explanatory text
- End with practical implications or next steps

### Transitions Between Topics

**Between sections:**

- "To get a better understanding of X, let's jump back into..."
- "Let's look at a complete example..."
- "So, what if..." (rhetorical question)

**Introducing alternatives:**

- "Alternatively, X may be specified as..."
- "Or, you may even..."
- "On the other hand, if..."

**Elaborating:**

- "In this example, the..."
- "As you can see, the..."
- "As mentioned previously..."

**Reassuring:**

- "Don't worry - all available X are [documented](#link)."
- "Again, if validation fails..."

### Code Examples

**Language annotations:**

| Annotation | Use for                        |
| ---------- | ------------------------------ |
| `php`      | PHP code                       |
| `blade`    | Blade templates (not `html`)   |
| `shell`    | Terminal commands (not `bash`) |
| `json`     | JSON configuration             |
| `xml`      | XML/HTML markup                |
| `env`      | Environment files              |

**Naming in examples:**

Use realistic, domain-specific class names:

- Good: `Flight`, `User`, `Post`, `Comment`, `Order`, `Invoice`, `Photo`
- Avoid: `Thing`, `Item`, `Foo`, `Bar`, `MyClass`, `Example`

This helps readers see themselves using the feature in real applications.

**File path comments:**

Include path when context needed:

```blade
<!-- /resources/views/post/create.blade.php -->
```

Or in PHP:

```php
// config/queue.php
```

**Progression:**

- Start with simplest working example
- Add complexity incrementally
- Show alternatives sequentially with transition text

**Comments in code:**

- Sparse - only when explaining "why"
- Use `// ...` for implementation placeholders
- Use docblocks for method/class context

**Completeness:**

- Full files when showing structure/architecture
- Focused snippets when demonstrating features

**Multiple approaches:**

- Present sequentially, not side-by-side
- Use transition: "Alternatively..." or "Or, you may..."
- Explain when to use each approach

### Cross-References

Link to related documentation using these patterns:

**Inline reference:**

> These routes are assigned the `web` [middleware group](/docs/{{version}}/middleware#section-name).

**End-of-paragraph reference:**

> You can read more about CSRF protection in the [CSRF documentation](/docs/{{version}}/csrf).

**Prerequisite reference:**

> Before getting started, be sure to configure a database connection in your
> application's `config/database.php` configuration file. For more information
> on configuring your database, check out [the database configuration documentation](/docs/{{version}}/database#configuration).

### Callouts

**NOTE** - Additional helpful information:

```markdown
> [!NOTE]
> Helpful context or tips that enhance understanding.
```

**WARNING** - Important cautions:

```markdown
> [!WARNING]
> Critical information about potential issues or security concerns.
```

Use callouts sparingly - one or two per major section maximum.

### Technical Explanations

**Layer from simple to complex:**

1. Simple statement of what it does
2. How to create/use it (with code)
3. How to apply it (practical example)
4. Advanced variations

**Use metaphors when helpful:**

- "Migrations are like version control for your database"
- "Guards define how users are authenticated"
- "Middleware can be thought of as layers HTTP requests pass through"

### Docs Workflow

**Scope:** `docs/**/*.md` files only

**After changes:** Run prettier to auto-format using the detected package manager:

| Lock File           | Command                                    |
| ------------------- | ------------------------------------------ |
| `bun.lockb`         | `bunx prettier --write "docs/**/*.md"`     |
| `pnpm-lock.yaml`    | `pnpm dlx prettier --write "docs/**/*.md"` |
| `yarn.lock`         | `yarn dlx prettier --write "docs/**/*.md"` |
| `package-lock.json` | `npx prettier --write "docs/**/*.md"`      |
| No lock file        | `bunx prettier --write "docs/**/*.md"`     |

Fix any formatting issues before committing.

## Standards

- Address reader directly with "you" and "your"
- Use active voice in 95%+ of sentences
- Explain the "why" before showing the "how"
- Progress from simple to complex examples
- Include working code examples for every feature
- Use callouts sparingly for important notes and warnings
- Keep paragraphs short (2-4 sentences)
- Use contractions for conversational tone
- Include Quickstart section for feature documentation
- Use realistic class names in examples (Flight, User, Post)

## Constraints

- Never use passive voice for instructions ("The file should be created" -> "Create the file")
- Never start with code before explaining the concept
- Never show advanced features before basic usage
- Never use jargon without explanation on first use
- Never write walls of text - break into digestible chunks
- Never omit the table of contents in long documents
- Never use "simply" or "just" - they dismiss complexity
- Never use generic example names (Foo, Bar, Thing, Item)
- Never skip the introduction pattern - every doc needs context first
- Never use em-dashes (—) - use commas, parentheses, or colons instead
