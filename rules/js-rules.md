---
paths: package.json
---

# JavaScript/TypeScript Ecosystem RULES

Detect package manager from lock files before running any JS/TS commands.

## Detection Order

1. `bun.lockb` or `bun.lock` → `bun`
2. `pnpm-lock.yaml` → `pnpm`
3. `yarn.lock` → `yarn`
4. `package-lock.json` → `npm`
5. No lock file → `bun` (default)

## Command Mapping

### Example: pnpm

```
Lock file: pnpm-lock.yaml
Install: pnpm install
Add dep: pnpm add lodash
Dev dep: pnpm add -D typescript
Run script: pnpm run build
Execute: pnpm dlx create-next-app
```

### Example: yarn

```
Lock file: yarn.lock
Install: yarn install
Add dep: yarn add lodash
Dev dep: yarn add -D typescript
Run script: yarn build
Execute: yarn dlx create-next-app
```

### Example: bun

```
Lock file: bun.lockb
Install: bun install
Add dep: bun add lodash
Dev dep: bun add -D typescript
Run script: bun run build
Execute: bunx create-next-app
```

### Example: npm

```
Lock file: package-lock.json
Install: npm install
Add dep: npm install lodash
Dev dep: npm install -D typescript
Run script: npm run build
Execute: npx create-next-app
```

## Application

Use detected package manager for:

- Installing packages
- Running scripts
- Adding/removing dependencies
- Building and dev servers
- Executing one-off packages (dlx/npx/bunx)
