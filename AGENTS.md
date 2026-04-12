# Codex Project Rules

This file is the project-level instruction entry for Codex.
Keep it short, concrete, and implementation-oriented.

## Core Principles

- Confirm the real runtime path before changing code: entry script -> `SystemMgr` -> target system -> `PlayerServerClass`/`DataManager` -> UI.
- Prefer reusing the current framework over introducing parallel patterns.
- Server authority first, client presentation second.
- Respect the current lifecycle ordering, especially on `PlayerRemoving`.

## System Rules

- Before modifying a feature, confirm the related system is actually enabled in `src/ReplicatedStorage/Systems/SystemMgr.lua`.
- Treat old simulator systems as legacy unless the current `SystemMgr` load list proves they are active.
- New systems should use `SystemName/init.lua + Presets.lua + ui.lua + Assets/`.
- New systems should prefer `BaseSystem.lua` unless there is a concrete compatibility reason not to.
- Only add a system to `LoadOrder` if it truly has priority startup requirements.

## Cross-Server/Client Rules

- Do not create ad hoc `RemoteEvent` objects for gameplay code.
- Cross-boundary calls should go through `SystemMgr` proxies:
- Server to client: `self.Client:Method(player, args)`
- Server broadcast: `self.AllClients:Method(args)`
- Client to server: `self.Server:Method(args)`
- Non-remote methods must be added to `whiteList`.
- Keep trusted sender validation for important server methods by using `CheckSender()` or equivalent.

## Data Rules

- Player authority data is server-owned.
- Read and write player data through `PlayerServerClass`, not direct `ProfileService` calls in gameplay systems.
- Client state should read from `ClientData`.
- When adding a persisted field, update `Keys.DataKey`, `DefaultData`, and `DebugData` when needed.
- Preserve `PlayerRemoving` order:
- systems cleanup first
- `DataManager:ReleaseProfile` second
- `PlayerServerClass.RemoveIns` last

## UI Rules

- Use the current pending-calls pattern or `BaseSystem:InitUI()` for system UI startup.
- Reuse `uiController` for common interactions and notifications.
- Prefer `Scale`-friendly UI layouts and keep mobile/touch constraints in mind.
- When inspecting UI statically, look in `StarterGui`, not runtime `PlayerGui`.

## Config Rules

- Put global tunables in `GameConfig.lua`.
- Put system-private tuning in that system's `Presets.lua`.
- Avoid hardcoding gameplay constants in random modules.

## Performance Rules

- Prefer `ScheduleModule.AddSchedule()` over long-running `while true do task.wait()` loops.
- Use unreliable remote semantics only for high-frequency, non-critical updates.
- Add protection where it matters: remote trust, player alive checks, timed tasks, profile lifecycle.

## Style Rules

- Prefer Luau backtick interpolation for new strings.
- Do not introduce `do end` blocks for manual grouping.
- Keep the existing file organization style:
- services
- requires
- common variables
- server variables
- client variables
- Preserve file header comments in legacy files when editing them.
- Avoid unnecessary defensive clutter, but keep meaningful guards.

## Roblox Flip-A-Coin Rules

- Build around the active framework assets:
- `SystemMgr`
- `BaseSystem`
- `PlayerSystem`
- `GuiSystem`
- `MusicSystem`
- `ScheduleModule`
- `PlayerServerClass`
- `DataManager`
- Preferred gameplay system split:
- `CoinFlipSystem`
- `TableSeatSystem`
- `TableHypeSystem`
- `CoinLoadoutSystem`
- `AnnouncementSystem`
- Do not revive old simulator complexity unless it directly serves the current coin-flip game.

## Source Of Truth

- Project-specific rationale and expanded guidance live in `docs/CodexRules.md`.
- If `AGENTS.md` and other local docs conflict, follow `AGENTS.md` first for implementation behavior.
