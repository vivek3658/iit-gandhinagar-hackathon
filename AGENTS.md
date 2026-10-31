# Project: Backend (Fastify + TypeScript)

## Stack
- Node.js (LTS), TypeScript (strict), Fastify v5
- Validation: TypeBox (@fastify/type-provider-typebox) or Zod
- DB: <PostgreSQL/MongoDB> via <Prisma/Drizzle/Mongoose>
- Tests: Vitest + fastify.inject()
- Lint/format: ESLint + Prettier

## Commands
- Install: `npm install`
- Dev: `npm run dev`
- Build: `npm run build`
- Test: `npm test`
- Lint: `npm run lint`

## Structure
src/
  app.ts            # builds and exports the Fastify instance (no listen)
  server.ts         # imports app, calls listen
  config/           # env parsing/validation
  plugins/          # fastify-plugin wrappers (db, auth, cors, etc.)
  modules/<name>/   # feature modules
    <name>.routes.ts
    <name>.controller.ts
    <name>.service.ts
    <name>.schema.ts
  utils/
  types/
test/

## Working agreement
- Read existing code and follow its patterns before writing new code.
- Make small, focused changes. Do not refactor unrelated files.
- Before finishing: run lint, build, and tests, and report results.
- Ask me before adding new dependencies or changing the folder structure.
- Never commit secrets. Never edit `.env`; update `.env.example` instead.