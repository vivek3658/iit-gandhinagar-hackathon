# Workflow: add a new module

1. Ask for the module name and its endpoints if not given.
2. Create `src/modules/<name>/` with `.schema.ts`, `.service.ts`, `.controller.ts`, `.routes.ts`.
3. Define TypeBox schemas first (body, params, query, response).
4. Implement the service, then controller, then routes.
5. Register the routes in `app.ts` with a prefix (e.g. `/api/v1/<name>`).
6. Add tests in `test/<name>.test.ts` using `app.inject()`.
7. Run `npm run lint && npm run build && npm test` and fix failures.
8. Summarize files created/changed.