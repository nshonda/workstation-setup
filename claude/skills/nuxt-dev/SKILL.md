---
name: nuxt-dev
description: Use when working in a project with nuxt.config.ts or Nuxt dependencies detected. Covers Nuxt 3/4 conventions, composable patterns, and SSR best practices.
---

# Nuxt Development Helper

Assists with Nuxt 3 and Nuxt 4 development following framework conventions.

## Version Detection

Before generating code, check:

1. `package.json` for `nuxt` version (^3.x or ^4.x)
2. **Nuxt 3**: `pages/`, `composables/`, `server/` at project root
3. **Nuxt 4**: `app/` directory containing `pages/`, `composables/`, etc. (future compat mode)
4. Package manager: check for `pnpm-lock.yaml` (pnpm), `yarn.lock` (yarn), or `package-lock.json` (npm)

## Key Conventions

### Auto-Imports

Nuxt auto-imports from:
- `composables/` — custom composables
- `utils/` — utility functions
- Vue APIs (`ref`, `computed`, `watch`, etc.)
- Nuxt APIs (`useRoute`, `useFetch`, `useRuntimeConfig`, etc.)

**Do not manually import** auto-imported items unless the project's ESLint config requires it.

### Data Fetching

```typescript
// SSR-safe data fetching (runs on server and client)
const { data, pending, error } = await useFetch('/api/items')

// Client-only fetching
const { data } = await useFetch('/api/items', { server: false })

// With key for deduplication
const { data } = await useFetch('/api/items', { key: 'items-list' })
```

Never use raw `fetch()` or `axios` in components — always use `useFetch` or `useAsyncData` for SSR compatibility.

### Server Routes (Nitro/H3)

```typescript
// server/api/items.get.ts
export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  return { items: [] }
})

// server/api/items.post.ts
export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  return { created: true }
})
```

### Middleware

```typescript
// middleware/auth.global.ts (runs on every route)
export default defineNuxtRouteMiddleware((to, from) => {
  const auth = useAuth()
  if (!auth.isAuthenticated && to.path !== '/login') {
    return navigateTo('/login')
  }
})
```

### State Management (Pinia)

```typescript
// stores/counter.ts
export const useCounterStore = defineStore('counter', () => {
  const count = ref(0)
  const increment = () => count.value++
  return { count, increment }
})
```

## SSR Considerations

- **State isolation**: Never use module-level mutable state — use `useState()` or Pinia stores
- **Client-only code**: Wrap in `<ClientOnly>` component or use `.client.vue` suffix
- **Environment detection**: Use `import.meta.server` / `import.meta.client` instead of `process.server`
- **Hydration**: Ensure server-rendered HTML matches client — avoid random values, dates, or browser APIs during SSR

## Project-Specific Context

Read the project's CLAUDE.md for:
- Nuxt version (3 vs 4) and directory structure (`app/` vs root)
- Layer system (shared layers, monorepo packages)
- CMS integration (Contentful, Strapi, etc.)
- Component library (PrimeVue, Nuxt UI, etc.)
- Auth pattern (OAuth, cookies, sessions)
- Deployment target (Vercel, AWS, Docker, etc.)

## Key Rules

- Detect package manager from lock file (`pnpm-lock.yaml`, `yarn.lock`, or `package-lock.json`)
- PascalCase for component file names
- Check project's ESLint config for `console.log` rules and `vuejs-accessibility` rules before generating code
- Check project's CLAUDE.md for CMS-specific codegen commands (e.g., GraphQL schema generation)
