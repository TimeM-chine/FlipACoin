# Repository Instructions

## First Read

Before answering questions about this repository or making changes in it, read:

- `docs/PROJECT_LOGIC.md`

Treat that file as the primary project-specific map for:

- active systems
- runtime call chains
- data and loading flow
- legacy or low-priority directories
- feature-specific architecture notes

## Working Rules

- Use `docs/PROJECT_LOGIC.md` first for orientation, then verify details in source files before making assumptions.
- If the document and current code disagree, trust the current code and update the document when appropriate.
- Do not assume every directory under `src/ReplicatedStorage/Systems` is active; check `SystemMgr.lua`.

## Framework Rules

Apply these framework-level rules for repositories built on this framework:

- Treat `SystemMgr.lua` as the runtime source of truth for active systems, registration, and bridge behavior.
- Preserve the framework structure where applicable:
  - `init.lua` for initialization and orchestration
  - `Presets.lua` for system constants and rules
  - `ui.lua` for client rendering and local interactions
  - `Modules/` for logic split-out
- Use the framework bridge pattern consistently:
  - `self.Client`
  - `self.AllClients`
  - `self.Server`
  - `whiteList` for internal non-bridge methods
- Prefer framework utilities over ad hoc replacements:
  - `uiController` for UI interaction helpers
  - `ScheduleModule` for periodic work when scheduling is needed
- Keep persisted schema changes consistent across keys, defaults, and save/load paths.
- Prefer Roblox backtick interpolation over `string.format` when interpolation is sufficient.
- Validate server-client features in Studio and verify initialization, runtime behavior, cleanup, and persistence impact where relevant.

## Separation Of Concerns

- Keep framework-generic rules in `AGENTS.md`.
- Keep repository-specific architecture, active system details, and feature logic in `docs/PROJECT_LOGIC.md`.
- If `AGENTS.md` and `PROJECT_LOGIC.md` overlap, use `AGENTS.md` for reusable framework constraints and `PROJECT_LOGIC.md` for repository facts.
