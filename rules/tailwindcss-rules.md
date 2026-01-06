---
paths: resources/views/**/*.blade.php, resources/**/*.css, **/*.vue, **/*.jsx, **/*.tsx
---

# Tailwind CSS Rules

<important>

- **Tailwind v4 only:** Use v4 utilities—never use deprecated v3 utilities
- **CSS-first config:** Use `@theme` directive in CSS—no `tailwind.config.js` needed
- **Gap for spacing:** Use `gap-*` utilities for list spacing, not margins
- **Dark mode:** If existing pages support dark mode, new components must too via `dark:`

</important>

<examples>

  <example name="tailwind-v4-import" type="correct">
```css
/* Tailwind v4 import */
@import "tailwindcss";

@theme {
  --color-brand: oklch(0.72 0.11 178);
  --font-display: "Inter", sans-serif;
}
```
  </example>

  <example name="tailwind-v4-import" type="wrong">
```css
/* Tailwind v3 directives - deprecated */
@tailwind base;
@tailwind components;
@tailwind utilities;
```
  </example>

  <example name="gap-spacing" type="correct">
```html
<!-- Use gap for list spacing -->
<div class="flex gap-4">
  <div>Item 1</div>
  <div>Item 2</div>
  <div>Item 3</div>
</div>

<ul class="flex flex-col gap-2">
  <li>First</li>
  <li>Second</li>
</ul>
```
  </example>

  <example name="gap-spacing" type="wrong">
```html
<!-- Margins for list spacing - use gap instead -->
<div class="flex">
  <div class="mr-4">Item 1</div>
  <div class="mr-4">Item 2</div>
  <div>Item 3</div>
</div>
```
  </example>

  <example name="opacity-utilities" type="correct">
```html
<!-- Tailwind v4 opacity syntax -->
<div class="bg-black/50">50% opacity black</div>
<div class="text-white/75">75% opacity white text</div>
<div class="border-gray-500/25">25% opacity border</div>
```
  </example>

  <example name="opacity-utilities" type="wrong">
```html
<!-- Deprecated opacity utilities -->
<div class="bg-black bg-opacity-50">...</div>
<div class="text-white text-opacity-75">...</div>
```
  </example>

  <example name="dark-mode">
```html
<!-- Dark mode support -->
<div class="bg-white dark:bg-gray-900">
  <h1 class="text-gray-900 dark:text-white">Title</h1>
  <p class="text-gray-600 dark:text-gray-300">Content</p>
</div>
```
  </example>

  <example name="class-organization">
```html
<!-- Organized class order: layout → spacing → sizing → colors → effects -->
<button class="flex items-center gap-2 px-4 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700 transition-colors">
  Submit
</button>
```
  </example>

</examples>

<context>

## Tailwind v4 Changes

Tailwind v4 uses CSS-first configuration:

```css
@import "tailwindcss";

@theme {
  --color-primary: oklch(0.65 0.2 250);
  --spacing-18: 4.5rem;
}
```

**Not supported in v4:**
- `tailwind.config.js` (use `@theme` in CSS)
- `corePlugins` option
- `@tailwind` directives

## Deprecated Utilities

| Deprecated | Replacement |
|------------|-------------|
| `bg-opacity-*` | `bg-black/*` (e.g., `bg-black/50`) |
| `text-opacity-*` | `text-black/*` |
| `border-opacity-*` | `border-black/*` |
| `divide-opacity-*` | `divide-black/*` |
| `ring-opacity-*` | `ring-black/*` |
| `placeholder-opacity-*` | `placeholder-black/*` |
| `flex-shrink-*` | `shrink-*` |
| `flex-grow-*` | `grow-*` |
| `overflow-ellipsis` | `text-ellipsis` |
| `decoration-slice` | `box-decoration-slice` |
| `decoration-clone` | `box-decoration-clone` |

Opacity values remain numeric (e.g., `bg-black/50` for 50% opacity).

</context>

<instructions>

## Class Organization

Think through class placement carefully:

1. **Remove redundant classes** - Don't repeat what's inherited
2. **Parent vs child** - Add shared styles to parent, unique to children
3. **Logical grouping** - Layout → spacing → sizing → colors → effects

## Spacing

- Use `gap-*` for flex/grid children spacing
- Reserve margins for positioning relative to siblings outside the container
- Use padding for internal spacing

## Dark Mode

If the project supports dark mode:

```html
<div class="bg-white dark:bg-slate-800">
  <span class="text-slate-900 dark:text-slate-100">Text</span>
</div>
```

Check existing components for dark mode patterns before adding new ones.

## Theme Extension

Extend the theme in CSS using `@theme`:

```css
@import "tailwindcss";

@theme {
  --color-brand: oklch(0.72 0.11 178);
  --color-brand-light: oklch(0.85 0.08 178);
  --font-display: "Cal Sans", sans-serif;
}
```

Then use as: `bg-brand`, `text-brand-light`, `font-display`

## Component Extraction

When patterns repeat, extract into Blade/Vue/React components:

```blade
{{-- resources/views/components/button.blade.php --}}
<button {{ $attributes->merge(['class' => 'px-4 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700']) }}>
    {{ $slot }}
</button>
```

## Documentation

Use `search-docs` tool with queries like:
- `flexbox`
- `grid layout`
- `dark mode`
- `responsive design`

</instructions>

## Standards

- Use Tailwind v4 syntax exclusively
- Configure theme via `@theme` in CSS
- Use `gap-*` for spacing between flex/grid children
- Support dark mode if existing pages do
- Organize classes logically (layout → spacing → sizing → colors → effects)
- Extract repeated patterns into components

## Constraints

- Never use deprecated v3 utilities (see table above)
- Never use `@tailwind` directives (use `@import "tailwindcss"`)
- Never use `tailwind.config.js` for theme configuration
- Never use margins for list item spacing (use gap)
- Never add dark mode inconsistently with existing pages
- Never use `corePlugins` option (not supported in v4)
