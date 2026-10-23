# global agent instructions

- Never use the em dash "—". Use plain dash "-" instead
- When writing commit messages, NEVER auto-add your agent name as co-author
- Never manually modify CHANGELOG.md files or any files that are marked as auto-generated
- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- For one-off or infrequent operational work, start with the simplest direct end-to-end path. Do not build wrappers, control planes, policy layers, custom verifiers, or automation unless the direct path exposes a concrete blocker or repeated need that justifies the added machinery.
- When doing bug fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end user would experience it as possible.
  This makes sure you find the real problem so your fix will actually solve it.
- Keep UI quality, lint and tests high within the task. Report unrelated defects without adding their repair to the change.
- Choose validation from the changed behavior and its risks. For fixed-value config or docs, use focused checks.
  Broaden checks when shared executable logic changes or focused checks cannot cover the risk. Required CI still applies.
  Reproduce a failing check on the unmodified base before assigning blame. Do not run full baseline suites for every edit.
- Reuse loaded instructions and docs. Re-read only changed or missing material and references needed for the task.
- Keep task-specific worktree isolation and repository review rules. Use the worktree skill for isolation, not automatic setup.
  Task-specific validation replaces its generic dependency-install and baseline-test steps. Install only what selected checks need.
- Prepare repository-only edits from declarations and relevant policy. Inspect live systems only when the change depends on live facts.
  Keep authorization, security checks and review. Do not report a prepared change as active.
- Edit small changes at known paths directly. Do not delegate them to subagents or add a planning workflow.
- Before using "dynamic workflows", "ultra code" or any harness feature that immediately spawns a large swarm of subagents, always explain the tradeoffs and ask the user for explicit approval.
- Write in simple language, use direct and concrete word. Avoid abstractions unless they genuinely add value.s
