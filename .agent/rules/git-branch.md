# Git Rules

- I work on feature branches, never directly on `main`. Check the current branch with `git branch --show-current` before making changes and tell me if it's `main`.
- Do not switch branches, rebase, force-push, or delete branches without asking.
- Commit in small logical chunks using Conventional Commits:
  `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`
- Don't commit `node_modules`, `dist`, `.env`, or generated files.
- Show me `git diff --stat` summary when you finish a task.