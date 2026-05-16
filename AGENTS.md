# Repository Instructions

## First Read

Before answering questions about a repository or making changes in it:

1. Read the repository's own startup guidance first when it exists, such as `AGENTS.md`, `README.md`, `docs/BOOTSTRAP.md`, or equivalent onboarding notes.
2. Read the repository's live task-state doc when it exists, starting from current active work and backlog sections.
3. Read deeper architecture, framework, and project-logic docs only when the task needs them.

Rule of thumb:

- If you will write or review Luau, read the repository's canonical Luau / framework guidance first when it exists.
- If the task is about **how a shared framework works**, read that framework's reference docs.
- If the task is about **what this repository has or does**, read its project-logic docs when they exist, then verify details in source files.
- If the task is about **what is currently in progress**, start with the repository's task-state doc when it exists.
- If the task is about **old plans, audits, or historical decisions**, read archive docs selectively when the repository keeps them.

## Working Rules

- Use the repository's own orientation docs first, then verify details in current source before making assumptions.
- If docs and code disagree, trust the current code and update docs when appropriate.
- Do not assume every directory or module is active just because it exists; find the real runtime entry points and registries first.
- Prefer the repository's existing architecture, helpers, and conventions over inventing parallel patterns.
- For code-only Luau changes, do not run `rojo build` as validation unless the repository's mapping, instance tree, asset structure, or Rojo config changed.
- Do not use Rojo/source edits just to create complex asset placeholders. Treat art, models, layered UI prefabs, VFX/SFX, and other rich Roblox assets as Studio-owned unless the user explicitly asks to source-control a specific simple structure.
- Do not generate adjustable Roblox UI at runtime with code. Author Frames, cards, layouts, corners, strokes, constraints, and other inspectable UI structure in Studio via MCP tools, then let Luau read existing instances, bind interactions, toggle visibility, and update dynamic text/state. Topbar/icon modules, template clones for short-lived effects, and non-UI runtime instances are acceptable when they are intentionally not designer-edited prefabs.
- When authoring editable UI prefabs, use `Scale` for both `Position` and `Size` on layout-bearing containers and controls. Keep `Offset` for intentional padding, border thickness, text inset, or other fixed micro-adjustments only.
- If an operation can be completed with an MCP tool, prefer MCP over computer-use automation.
- For complex visual, multi-client, mobile-device, or Studio-only validation that automation cannot verify reliably, record feasible source review and sanity checks, then leave final feel / visual judgment to the user.

### Task-State Maintenance

When the repository keeps live task state:

- Add a new task entry when starting work.
- Keep `Progress` / `Next` / `Decisions` accurate while working.
- Move finished work to the repository's done/history section with a concise outcome and date.
- Record non-obvious decisions, rejected alternatives, and follow-ups.
- Put unscheduled future ideas in the repository's backlog section.
- Keep long historical plans, audit records, and stale execution logs in archive docs when the repository has them.

### Project-Logic Maintenance

When the repository keeps a project-logic document, update it in the same change whenever:

- A runtime module, system, or service is registered, removed, renamed, or moved in or out of the active startup path.
- Persisted schema changes.
- A significant core gameplay or product flow changes.
- Entry-point scripts or startup-time initialization change.
- Project-specific constants change.
- Known legacy items or project quirks are added or resolved.

Prefer small targeted edits over rewriting large sections.

### Framework Maintenance

When the repository keeps a framework reference document, update it only when the framework itself changes, such as:

- Startup or lifecycle orchestration.
- Communication conventions.
- Standard module / system file layout.
- Shared coding habits or framework-level helpers.

Do not put repository-specific facts into framework docs.

## Non-Negotiables

If a repository has stricter local guidance, follow the local guidance. Otherwise:

- Identify the real runtime entry points and registries before deciding what is active.
- Reuse the repository's established communication, scheduling, UI, and data-flow conventions instead of creating parallel ones.
- Broadcast through the repository's established broadcast path instead of hand-rolling loops when one already exists.
- Let framework-owned lifecycle paths keep ownership of teardown / persistence ordering when the framework provides them.
- When adding persisted data, update the repository's key definitions, defaults, debug/test fixtures, runtime read/write points, and downstream consumers together.
- Prefer Roblox backtick interpolation over `string.format`.
- Do not use `do ... end` scoping blocks.
- Do not add defensive nil/type/shape guards for deterministic project-owned paths, configs, or internal calls. Validate player-provided inputs and genuinely optional runtime state.
- Do not use `Instance.new` in gameplay UI code to build editable UI prefabs or styling helpers; create those instances in Studio and bind them from code.
- Preserve the repository's established server/client method shape in shared files.
- Keep helper functions near the end of the file. Do not predeclare `local f` just for forward references. Extract helpers only when reused, non-trivial, or materially clearer.
- Implement server-authoritative behavior before client presentation when a feature crosses the network boundary.
- Avoid circular dependencies.
- Validate init, runtime, cleanup, and persistence paths; use multi-client validation when the feature crosses the network boundary.

## Separation Of Concerns

Do not duplicate content across document tiers when a repository has them:

- `AGENTS.md` — cross-tool working rules.
- Startup / bootstrap docs — cheap orientation and routing.
- Framework docs — reusable framework mechanics and conventions.
- Project-logic docs — facts specific to one repository.
- Task-state docs — live progress and cross-session handoff.
- Archive docs — historical plans, detailed audits, and old reference material read only on demand.

If the same content appears in two places, treat the more specific tier as canonical and trim the broader one.
