# Fastify Rules

## Architecture
- Routes only declare endpoints + schemas. Controllers handle req/reply. Services hold business logic and DB access. Never put business logic in routes.
- Register everything through plugins. Use `fastify-plugin` for shared things (db, auth) so decorators are visible app-wide.
- Keep `app.ts` and `server.ts` separate so tests can use `inject()`.
- Use `async` handlers and return the value (don't mix `reply.send` with returning).

## Validation & types
- Every route must define a schema for body, params, querystring, and responses.
- Derive TS types from the schema (TypeBox `Static<>`), don't duplicate types.
- Response schemas are required, so they strip unwanted fields (e.g. password hashes).

## Errors
- Use `@fastify/sensible` (`reply.notFound()`, `httpErrors`) or custom error classes.
- One central `setErrorHandler`. Consistent shape:
  `{ "statusCode": 400, "error": "Bad Request", "message": "..." }`
- Never leak stack traces or internal errors in production.

## Config & security
- Parse env vars once in `config/env.ts` with validation (`@fastify/env` or Zod). Fail fast on missing vars.
- Use `@fastify/helmet`, `@fastify/cors`, `@fastify/rate-limit`.
- Auth via `@fastify/jwt` + a `preHandler`/decorator, not copy-pasted checks.
- Hash passwords with argon2 or bcrypt.

## Logging
- Use Fastify's built-in pino logger (`request.log`, `fastify.log`). No `console.log`.
- Never log tokens, passwords, or full request bodies with PII.

## Code style
- TypeScript strict, no `any` (use `unknown` + narrowing).
- Named exports, small files, async/await only (no raw callbacks/`.then` chains).
- Use HTTP status codes correctly: 201 create, 204 no content, 409 conflict, etc.

## Testing
- Each route gets tests via `app.inject()`: success, validation failure, auth failure, not found.
- Use a separate test DB or mocks. Tests must not depend on each other.