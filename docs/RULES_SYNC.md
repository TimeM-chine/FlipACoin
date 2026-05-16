# Rules Sync

This project uses a shared rules source at `../_central-rules`.

The central folder also contains reusable setup assets:

- `tools/Sync-Rules.ps1`
- `templates/rules-sync.json`

Managed shared files:

- `AGENTS.md`
- `.cursor/rules/*.mdc`

Project-local files such as `docs/BOOTSTRAP.md`, `docs/FRAMEWORK.md`, `docs/PROJECT_LOGIC.md`, and `docs/TASK_STATE.md` are not synced.

## Commands

Initialize the central rules folder from this project:

```powershell
.\tools\rules\Sync-Rules.ps1 -Mode InitCentral
```

Pull the latest central rules into this project:

```powershell
.\tools\rules\Sync-Rules.ps1 -Mode Sync
```

Check whether this project is current:

```powershell
.\tools\rules\Sync-Rules.ps1 -Mode Check
```

## Updating Shared Rules

Edit the file in `../_central-rules` first, then run `Sync` in each project that should receive the update. Run `Check` afterward to verify the project matches the central source.

## Adding Another Project

Copy `../_central-rules/templates/rules-sync.json` into the project as `.rules-sync.json`, then either copy `../_central-rules/tools/Sync-Rules.ps1` into `tools/rules/Sync-Rules.ps1` or run the central script directly with `-ProjectRoot`.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ..\_central-rules\tools\Sync-Rules.ps1 -ProjectRoot C:\Path\To\OtherProject -Mode Sync
```
