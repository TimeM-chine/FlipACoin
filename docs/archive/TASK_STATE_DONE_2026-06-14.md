# Task State Done 2026-06-14

来源：`docs/TASK_STATE.md` 的旧 `Recent Done` 记录。

这份文档保留 2026-06-14 的完成项摘要，不作为当前项目事实来源。当前事实以 `docs/PROJECT_LOGIC.md` 和源码为准；当前待办以 `docs/TASK_STATE.md` 为准。

## Entries

### 2026-06-14 Analytics custom event batching

- Outcome: `AnalyticsSystem` custom events now batch by player, event name, and the three custom fields, flush every `15` seconds under a soft `120 + 20 * CCU` per-minute AnalyticsService budget, and force flush on player leave / server close; docs now clarify that Dashboard `Count` is batch count and `Sum value` keeps the original value semantics.

### 2026-06-14 Growth panel preview polish

- Outcome: Studio/MCP 已把 Shop 和 Boosts 右侧 Preview 子元素重新居中并统一标题、图标框、描述和底部状态的纵向层级；运行态 sanity 确认 Shop / Boosts 填充真实文本后不再向左溢出。

### 2026-06-14 Boosts panel split

- Outcome: `Frames.Boosts` is now a standalone Studio-authored growth panel, `EcoSystem/ui.lua` renders Boosts separately from Shop, shared HUD / close / analytics paths recognize Boosts, and legacy catch-all `*Button` frame binding no longer overrides system-owned growth panel buttons.
