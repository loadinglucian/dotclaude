---
paths: **/*.php
---

# PHP Rules

<important>

- **Yoda conditions:** Constants/literals ALWAYS on LEFT side of comparisons
- **Always use braces:** ALL control structures must use `{ }` - no single-line shortcuts
- **Strict types:** Declare `declare(strict_types=1);` in every file

</important>

<examples>

  <example name="yoda-conditions" type="correct">
```php
if (null === $value) { ... }
if ('' === trim($name)) { ... }
if (0 === count($items)) { ... }
```
  </example>

  <example name="yoda-conditions" type="wrong">
```php
if ($value === null) { ... }  // constant should be on LEFT
if (trim($name) === '') { ... }  // literal should be on LEFT
```
  </example>

  <example name="yoda-two-variables">
```php
// Two variables - Yoda doesn't apply
if ($typedName !== $server->name) { ... }
```
  </example>

  <example name="phpstan-annotation" type="correct">
```php
/** @var string $apiToken */
$apiToken = $this->env->get(['API_TOKEN']);
```
  </example>

  <example name="phpstan-annotation" type="wrong">
```php
assert(is_string($apiToken));  // don't use assert() in production
```
  </example>

  <example name="comment-structure">
```php
// ----
// Section Header (h1)
// ----

//
// Subsection (h2)
// ----

//
// Minor heading (h3)

// Regular comment (p)
```

  </example>

</examples>

<context>

## PHP Standards

- PSR-12 coding standard
- Strict types in every file
- PHP 8.x features: unions, match, attributes, readonly, constructor promotion
- Explicit return types with generics: `Collection<int, User>`
- Dependency injection via Symfony patterns
- Use Symfony classes over native PHP functions (Filesystem, Process) for testability

</context>

<instructions>

## Imports

- Always add `use` statements for vendor packages
- Root namespace FQDNs acceptable for exceptions (`\RuntimeException`)

## DocBlocks

- Minimalist descriptions
- Parameters and return types only when not inferable from signature
- Use `@var` annotations for PHPStan, not `assert()` in production

## Comments

- Separate sections visually using the structure in examples
- No obvious comments - if code needs explanation, refactor it
- Remove comments when removing code

</instructions>

## Standards

- PSR-12 compliance on all PHP files
- Strict types declared in every file
- Explicit return types with generics where applicable
- Yoda conditions for all literal/constant comparisons
- Braces on all control structures

## Constraints

- Never use `assert()` in production code (use `@var` annotations)
- Never omit braces from control structures
- Never place variables on left side of literal comparisons
- Never use native PHP functions when Symfony equivalents exist (Filesystem, Process)
- Never write obvious comments
