# Repository Instructions

## First Read

Before answering questions about this repository or making changes in it, read **in this order**:

1. `docs/FRAMEWORK.md` — the generic SystemMgr framework (shared across all projects built on this framework). Covers system registration, bridge pattern (`self.Client / AllClients / Server`), `whiteList`, `SENDER`, lifecycle orchestration, data layer (ProfileService → DataManager → PlayerServerClass → ClientData), standard system file layout, **and the canonical coding-habits checklist in §8 — read it before writing Luau in this repo**.
2. `docs/PROJECT_LOGIC.md` — this repository's specific facts: active systems list, gameplay main loop, project constants, persisted schema, known legacy quirks, lookup table.
3. `docs/TASK_STATE.md` — current active tasks, progress, decisions, backlog (cross-session / cross-device handoff log). Check `## Active` before starting work so you do not duplicate or contradict in-flight work.

Rule of thumb:

- If it's about **how the framework itself works** → `FRAMEWORK.md`.
- If it's about **what this specific repo has / does** → `PROJECT_LOGIC.md`.
- If it's about **what we're currently doing** → `TASK_STATE.md`.

## Working Rules

- Use `docs/PROJECT_LOGIC.md` first for orientation, then verify details in source files before making assumptions.
- If the document and current code disagree, trust the current code and update the document when appropriate.
- Do not assume every directory under `src/ReplicatedStorage/Systems` is active; check `SystemMgr.lua`.
- For code-only Luau changes, do not run `rojo build` as validation; the Rojo structure is already known-good. Reserve Rojo build checks for project mapping, instance tree, asset structure, or Rojo config changes.

### Task State Maintenance (`docs/TASK_STATE.md`)

- When starting a new task, add an entry under `## Active` using the template in that file.
- While working, keep the task's `Progress` / `Next` / `Decisions` accurate in real time.
- When a task is finished, move the entry to `## Done` with a one-line outcome and date.
- Record non-obvious decisions (trade-offs, rejected alternatives, follow-ups) in `Decisions`.
- Put future ideas that are not yet scheduled in `## Backlog / Ideas` as single lines.

### Project Logic Maintenance (`docs/PROJECT_LOGIC.md`)

Update this file in the same change whenever any of the following happens in **this repository**:

- A system is registered, removed, renamed, or moved in/out of `SystemMgr.systems` / `LoadOrder`.
- Persisted schema changes (new/removed `Keys.DataKey`, default values, reconcile behavior).
- A significant change lands in the project's core gameplay flow (e.g. `ForgeSystem:TryForge`).
- Entry-point scripts or startup-time initialization change (`server.server.lua`, `client.client.lua`, character scripts, `Loading.client.lua`).
- Project-specific constants change (`GameConfig.Badges`, `DevIds`, `Zones`, version).
- Known-legacy/quirk items are added or resolved.

Prefer small targeted edits over rewriting sections.

### Framework Maintenance (`docs/FRAMEWORK.md`)

Only touch this file when the **framework itself** changes. Typical triggers:

- `SystemMgr.Start` / `LoadSystem` / bridge generation changes.
- Lifecycle orchestration (`PlayerAdded` / `PlayerRemoving` chain, `DataMgr:ReleaseProfile` ordering) changes.
- Communication conventions change (`self.Client / AllClients / Server`, `whiteList` semantics, unreliable transport).
- Standard system file layout or the `Types.mt` pending-calls mechanism changes.
- Framework-level coding habits are introduced or retired.

**Do not** put repository-specific facts (which systems are active, specific badges, specific gameplay rules) here—those belong in `PROJECT_LOGIC.md`.

## Non-Negotiables (quick reference)

The **canonical coding-habits checklist is `docs/FRAMEWORK.md` §8** (30 items). The list below is only the highest-priority subset; when in doubt, consult §8.

- `SystemMgr.lua` is the runtime source of truth for active systems. A system not in `systems` is not loaded.
- Use the framework bridge consistently: `self.Client:Fun(player, args)` / `self.AllClients:Fun(args)` / `self.Server:Fun(args)`. Methods in `whiteList` are internal-only and must not be treated as remote-callable.
- Broadcast via `self.AllClients`, not by looping `self.Client`. Non-critical broadcasts add `args.unreliable = true`.
- Do not hook `Players.PlayerRemoving` to release profiles or clear `playerInsList`; `SystemMgr` orchestrates that order.
- Use `uiController` for button interactions; use `ScheduleModule` for periodic work (not `while task.wait()`).
- When adding a persisted field, update `Keys.DataKey` + `DefaultData` + `DebugData` + runtime read/write points + downstream consumers, all in the same change.
- Prefer Roblox backtick interpolation over `string.format`. Do not use `do ... end` scoping blocks.
- No defensive nil-guards on deterministic project-owned paths; let broken setup fail loudly in dev. Guards are only for genuinely optional runtime state, player-driven absence, or cross-system timing.
- Do not add defensive type / shape checks for deterministic project-owned data, configs, or internal calls. Validate player-provided remote inputs and genuinely optional runtime state only.
- In system methods outside `whiteList`, keep the `if IsServer then ... else ... end` double-branch structure even if one side is a placeholder.
- Helper functions at the end of the file. Do not predeclare `local f` just for forward references. Only extract a helper when the logic is reused, non-trivial, or materially more readable.
- Implement server logic first, then client. Avoid circular requires (use the `GetSystemMgr()` lazy-load pattern).
- Validate in Studio covering init → runtime → cleanup → persistence; Team Test for server-client features.
- Code-only Luau edits do not require `rojo build`; use source review and Studio/runtime checks when available.

## Separation Of Concerns

Four-tier split. Do not duplicate content across tiers:

- `AGENTS.md` — cross-tool working rules (reading order, doc maintenance rules, non-negotiable style requirements).
- `docs/FRAMEWORK.md` — the SystemMgr framework itself. Portable across all projects built on this framework.
- `docs/PROJECT_LOGIC.md` — facts specific to this repository (active systems, gameplay, constants, legacy).
- `docs/TASK_STATE.md` — live task progress and cross-session handoff state.

If you find the same content in two tiers, treat the more specific tier as canonical and trim the other.
