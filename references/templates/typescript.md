# Template Overlay: TypeScript / JavaScript

Append this when Phase 1 detects TS/JS (`package.json`). Use the detected package manager (`pnpm`, `npm`, `yarn`, `bun`) — do not assume npm.

## Verification — detect actual scripts from package.json

```markdown
## Verification (run after EVERY change)
1. `<pm> run typecheck` (or `npx tsc --noEmit`) — fix ALL type errors
2. `<pm> test` — fix ALL failing tests
3. `<pm> run lint` — fix ALL lint errors (no warnings either if `--max-warnings 0`)
4. `<pm> run build` — confirm it builds without errors

YOU ARE FORBIDDEN from reporting a task as complete until all 4 pass with zero errors.
```

Substitute `<pm>` with actual manager. Check `package.json` scripts and use their exact names — don't invent. If `build` isn't in scripts, skip step 4 and note it.

## Framework detection — add the right overlay

**Next.js** (detect `next` in deps):
- Flag partial migration: Pages router AND App router coexisting (`src/pages/` + `src/app/`) → flag as partial-migration confusion. Document the target.
- Server vs client components — rule: "Mark components with `'use client'` directive ONLY when they need client-side interactivity (hooks, browser APIs). Default to server components."
- `fetch()` caching semantics — changed in Next 14/15/16. Detect version and cite the correct defaults.
- Turbopack vs webpack — if Next 16+, default is Turbopack.

**React** (without Next):
- Component conventions: functional + hooks. Flag class components in a modern codebase as a partial-migration.
- State management — detect Redux / Zustand / Jotai / TanStack Query and enforce its boundaries.

**Vue / Nuxt / SvelteKit / Astro / Remix / Solid** — detect and add framework-specific boundary rules.

**tRPC / GraphQL / REST** — detect API style from deps (`@trpc/*`, `graphql`, etc.) and enforce the right request/response conventions.

## Module system

- Detect `"type": "module"` in package.json → ESM. Enforce `import/export`, no `require`.
- Mixed CJS + ESM → flag as partial migration.
- `.ts` / `.tsx` / `.mts` / `.cts` — enforce consistency.

## TypeScript config

Read `tsconfig.json` and surface strictness:
- `"strict": true` → enforce it in rules
- `"noUncheckedIndexedAccess": true` → rule: "Always handle `undefined` from array/Record access"
- `"exactOptionalPropertyTypes": true` → rule: "Don't use `?:` and `undefined` interchangeably"
- If strict NOT enabled → flag as CLAUDE.md gap

## Testing

Detect framework and tailor:
- **Vitest** — `vitest run`, config in `vitest.config.ts`, use `describe/it/expect`
- **Jest** — `jest --ci`, setup files in `jest.config`
- **Playwright** — `npx playwright test`, don't mix with unit tests
- **Testing Library** — enforce `getByRole` over `getByTestId` where possible

```markdown
- Vitest globals — if `test.globals: true`, no imports needed; otherwise import from `vitest`
- One `describe` per module; nested `describe` for sub-behaviors
- Snapshot tests only for stable output — refactor flakiness is a DEFECT, not snapshot update territory
- Test the contract, not the implementation
```

## Monorepo-specific

If `pnpm-workspace.yaml`, `turbo.json`, `nx.json`, or `lerna.json` detected:
- Per-package CLAUDE.md in each package's root — loaded on demand when Claude works there
- Root CLAUDE.md covers cross-cutting: workspace commands, shared types, inter-package dependency rules
- Use `claudeMdExcludes` in `.claude/settings.local.json` to skip other teams' CLAUDE.md if noisy

## Anti-patterns to flag

- "Use arrow functions" / "prefer const" → .eslintrc territory, remove from prose
- "Use Prettier" → `.prettierrc` exists or it doesn't. Don't re-declare in CLAUDE.md
- "Handle errors" → too vague. Specify: "All async boundaries use try/catch. Propagate with typed errors from `src/errors/`. Never swallow with bare `catch`"
- "Use TypeScript" → the project already does or doesn't. Delete.
