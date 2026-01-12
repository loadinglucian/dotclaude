---
paths: app/Console/Pro/**
---

# Pro Command Rules

Pro commands integrate with cloud providers (AWS, DigitalOcean) and provide premium features. They display a subscription banner and must follow specific naming conventions.

<important>

- **Extend ProCommand:** All Pro commands MUST extend `ProCommand`, not `BaseCommand`
- **Primary name:** Use `pro:{namespace}:{action}` format (e.g., `pro:aws:key:add`)
- **Alias required:** Every Pro command MUST have a non-`pro:*` alias (e.g., `aws:key:add`)

</important>

<examples>

  <example name="command-attribute">
```php
// CORRECT - Primary name is pro:*, alias is shorthand
#[AsCommand(
    name: 'pro:aws:key:add|aws:key:add',
    description: 'Add a local SSH public key to AWS'
)]
class KeyAddCommand extends ProCommand
```
  </example>

  <example name="wrong-no-alias">
```php
// WRONG - Missing non-pro alias
#[AsCommand(
    name: 'pro:aws:key:add',
    description: 'Add a local SSH public key to AWS'
)]
```
  </example>

  <example name="wrong-base-command">
```php
// WRONG - Extends BaseCommand instead of ProCommand
class KeyAddCommand extends BaseCommand
```
  </example>

</examples>

<rules>

- Extend `ProCommand` for automatic Pro banner display
- Use pipe syntax in `#[AsCommand]`: `'pro:x:y|x:y'`
- Primary name (before pipe) must start with `pro:`
- Alias (after pipe) mirrors primary without `pro:` prefix
- Place commands in `app/Console/Pro/{Provider}/` directory

</rules>
