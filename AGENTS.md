# Codex Project Rules

Use this file as the project-level operating rules for Codex.
Keep decisions practical, framework-aware, and consistent with the repo's real style.

## Core Principles

- Confirm the real runtime path before editing: entry script -> `SystemMgr` -> target system -> `PlayerServerClass` / `DataManager` -> UI.
- Trust the current game runtime more than old docs or leftover folders.
- Reuse the existing framework before adding new patterns.
- Server authority first, client presentation second.
- Respect the existing lifecycle ordering, especially on `PlayerRemoving`.

## What Is Active

- Always verify the active system list in `src/ReplicatedStorage/Systems/SystemMgr.lua` before changing gameplay code.
- Treat systems not registered in `SystemMgr.systems` as legacy by default, even if their folders still exist.
- Treat `LoadOrder` as intentional startup sequencing, not a place to append every new system.
- Current Flip-A-Coin work should center on the active gameplay path, not old simulator loops.

## Framework Rules

- The project's real backbone is:
- `SystemMgr`
- `PlayerSystem`
- `CharacterSystem`
- `GuiSystem`
- `MusicSystem`
- `ScheduleModule`
- `PlayerServerClass`
- `DataManager`
- `ClientData`
- New gameplay systems should use `SystemName/init.lua + Presets.lua + ui.lua + Assets/`.
- `BaseSystem.lua` is not yet a finished foundation for this project and is not part of the default workflow.
- Do not introduce `BaseSystem` into new work unless the user explicitly asks for it or the task is specifically about finishing `BaseSystem`.
- When editing old systems that already follow the pre-`BaseSystem` style, keep their local style unless the task clearly justifies migration.
- Do not force a full "AI cleanup" pass on legacy files during small tasks.

## Writing Style Rules

- Match the repo's existing hand-written structure first; do not normalize everything into generated-looking code.
- Preserve legacy file header comments when editing existing files.
- Keep the existing section order when present:
- `services`
- `requires`
- `common variables`
- `server variables`
- `client variables`
- Prefer direct, readable Luau over over-abstracted helpers.
- Prefer Luau backtick interpolation for new strings.
- Do not introduce `do end` blocks for manual grouping.
- Avoid defensive clutter; keep guards that protect real failure cases.
- Good guards in this repo include:
- sender trust
- player still in game
- profile lifecycle timing
- seat / character existence

## Legacy Style vs New Style

- Most older systems in this repo are hand-written and follow the `SENDER` + `GetSystemMgr()` + pending UI pattern.
- Some newer systems, such as `CoinFlipSystem`, use `BaseSystem` and a more generated style.
- Treat that style as an experiment, not the project default.
- For old systems:
- prefer local consistency over style migration
- keep current naming and layout
- do not rewrite them into `BaseSystem` just because it is newer
- For new systems or major rewrites:
- prefer the repo's established hand-written system pattern
- use `SENDER` + `GetSystemMgr()` unless the task explicitly targets `BaseSystem`
- reuse the existing pending-calls UI pattern
- Codex should bias toward the user's existing style, not Claude's default style, when both are viable.

## Cross-Server / Client Rules

- Do not create ad hoc `RemoteEvent` objects for gameplay code.
- Cross-boundary calls should go through `SystemMgr` proxies:
- server to client: `self.Client:Method(player, args)`
- server broadcast: `self.AllClients:Method(args)`
- client to server: `self.Server:Method(args)`
- Internal-only methods must be added to `whiteList`.
- Important server methods should keep trusted sender validation through `sender ~= SENDER` or `CheckSender()`.
- Preserve the current alive-guard mindset for remote handling; do not assume the player still exists.

## Data Rules

- Player authority data is server-owned.
- Gameplay systems should read and write through `PlayerServerClass`, not direct `ProfileService` access.
- Client state should read from `ClientData`.
- When adding persisted data, update:
- `Keys.DataKey`
- `DefaultData`
- `DebugData` when needed
- Prefer storing global tunables in `GameConfig.lua`.
- Prefer storing system-private formulas and defaults in that system's `Presets.lua`.
- Do not scatter gameplay constants across unrelated modules.

## Lifecycle Rules

- Do not break the current `PlayerRemoving` order:
- systems cleanup first
- `DataManager:ReleaseProfile` second
- `PlayerServerClass.RemoveIns` last
- Any system cleanup that still needs player data must happen before profile release.
- Player initialization should attach through the current `SystemMgr` lifecycle, not custom parallel hooks.

## UI Rules

- When checking UI statically, inspect `StarterGui`, not runtime `PlayerGui`.
- Reuse `uiController` for button behavior, frame opening, notifications, and common UI interactions.
- Use the existing pending-calls pattern in legacy systems, or `BaseSystem:InitUI()` in newer systems.
- Prefer scale-friendly layouts and keep touch / mobile constraints in mind.
- UI should reflect server-authoritative gameplay state rather than inventing local truth.

## Performance Rules

- Prefer `ScheduleModule.AddSchedule()` over long-running `while true do task.wait()` loops.
- Use unreliable remote semantics only for high-frequency, non-critical updates.
- Keep protections where they matter:
- remote trust
- timed task isolation
- character / seat validity
- profile lifecycle

## Flip-A-Coin Rules

- Build around the current gameplay split:
- `CoinFlipSystem`
- `TableSeatSystem`
- `AnnouncementSystem`
- later: `TableHypeSystem`
- later: `CoinLoadoutSystem`
- later: lightweight `RebirthSystem`
- Do not revive old simulator complexity unless it directly supports the current coin-flip game.
- Prefer the "single table, 8 players, shared spectacle" direction from the docs over multi-world simulator expansion.
- Keep `wins` as the compatible server-side cash field unless a task explicitly includes a data migration plan.

## Source Of Truth

- Project-specific rationale and expanded guidance live in `docs/CodexRules.md`.
- Product and system planning live in the `docs/` folder, but runtime truth comes from the actual code.
- If `AGENTS.md` and other local docs conflict, follow `AGENTS.md` first for implementation behavior.
