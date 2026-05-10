# TASK_STATE

最后更新：2026-05-10

> 目的：记录当前正在做什么、下一步是什么、已做验证、关键决策与后续想法。项目事实放 `PROJECT_LOGIC.md`，框架规则放 `FRAMEWORK.md`。

## Active

### 2026-05-08 Mobile UI production and logic wiring

- Started: 2026-05-08
- Status: `VAL-09` tab layout adjusted away from left touch controls; only real touch category-tab switching remains for user confirmation.
- Scope:
  - Main HUD: remove the top-left Brand / table population block from the live UI plan because players do not need table population status.
  - Build Studio UI for main HUD entry buttons, Rebirth, Shop, and Inventory based on the latest HTML direction.
  - Wire UI logic after the visual hierarchy is stable: open / close panels, sync player resources, purchase / equip flows, rebirth preview and confirmation.
  - Keep the current one-button `FLIP` core loop prominent; new systems must feel like side panels around the table, not a replacement for the main loop.
- Non-negotiable UI constraints:
  - New UI size and position must be Scale-first (`UDim2` scale for `Size` / `Position`); avoid fixed pixel Offset for layout-critical sizing and placement.
  - Offset is allowed only for small local details such as padding, stroke thickness, icon/text spacing, or minimum touch target polish when Scale cannot express it cleanly.
  - Mobile / touch is the primary validation target for this pass.
  - Safe area must be checked in runtime Play mode because the phone safe area only applies after the game is running.
  - Studio is already switched to a phone device; validation route is: start Play -> capture screenshot -> inspect proportions, safe area, overlap, and touch target readability.
- Task split:
  - `UI-00` Source audit and target hierarchy: inspect current `StarterGui.Main`, `CoinFlipHUD`, `uiClient.client.lua`, `uiController.lua`, active systems, and existing unused `RebirthSystem` / `BackpackSystem` / shop-like legacy modules before editing.
  - `UI-01` Main HUD production: remove top-left Brand/table-count concept; keep resources and equipment buffs only where they help decisions; place Rebirth / Shop / Inventory entry buttons in a mobile-safe location.
  - `UI-02` Rebirth panel production: show reset impact, expected rebirth points, permanent upgrade cards, upgrade costs, and confirmation states.
  - `UI-03` Shop panel production: support Coin and Desk Setup categories first; item cards show price, ownership, rarity/role, and stat bonuses such as coin multiplier, luck, and coin multiplier from desk setup.
  - `UI-04` Inventory panel production: support category tabs and fixed equipment slots for Coin and Desk Setup; leave room for future item types without changing the main HUD.
  - `LOGIC-01` Data contract planning: decide persisted keys and runtime state for rebirth points/upgrades, owned items, equipped Coin, equipped Desk Setup, and derived stat bonuses.
  - `LOGIC-02` Server authority: implement purchase, equip, and rebirth confirmation on server first; client UI only requests actions and renders synced state.
  - `LOGIC-03` Client binding: bind buttons through `uiController`, sync panels from `ClientData` / system payloads, and keep deterministic UI paths loud rather than over-guarded.
  - `VAL-01` Mobile runtime validation: Play in current phone device, screenshot main HUD and each panel, then record whether safe area, proportions, text fit, touch targets, and close/open flows pass.
  - `VAL-02` Regression checks: verify core Flip still works from HUD / `Space` / gamepad path where applicable, player still auto-seats, and rebirth returns player to a usable seat.
- Next:
  - `UI-00` source / hierarchy audit is complete.
  - `UI-01` main HUD + Rebirth / Shop / Inventory Studio UI assets are in place.
  - `LOGIC-01` data contract uses existing `fateShards` as Rebirth Points, existing `rebirthTree` as permanent upgrade tree, existing `equippedCoin / ownedCoins`, and new `equippedDeskSetup / ownedDeskSetups`.
  - `LOGIC-02` server authority is now in `CoinFlipSystem`: purchase, equip, rebirth confirmation, rebirth upgrade, and loadout-derived flip bonuses.
  - `LOGIC-03` client binding is now in `CoinFlipSystem/ui.lua`: `Buttons.CoinFlipMenu` opens `Frames.Rebirth / Shop / Inventory`, renders synced `growthState`, and sends server requests only.
  - `VAL-01` Studio phone screenshots captured for main HUD, Rebirth, Shop, and Inventory after moving the growth menu away from the left touch controls and shrinking/right-shifting growth panels.
  - MCP synthetic clicking reliably covered `FLIP`, but remained unreliable for Rebirth / Shop / Inventory entry and close buttons; final touch feel should be confirmed manually on device / Studio touch input.
  - `VAL-02` Studio single-client regression passed on 2026-05-10: auto-seat on join to `Seat01`, HUD `FLIP` click, `Space`, and simulated `ButtonR2` all triggered flips and updated Cash while preserving the seat.
  - `VAL-02` rebirth regression passed on 2026-05-10: with temporary Studio-only seeded Cash, server rebirth reset Cash to 30, kept HUD usable, kept the player seated at `Seat01`, and a post-rebirth `Space` flip updated Cash again.
  - `VAL-02` respawn auto-seat regression passed on 2026-05-10: killing the local humanoid produced a new character that auto-sat back into `Seat01` with HUD still visible.
  - User touch validation on 2026-05-10: Rebirth / Shop / Inventory entry buttons all open their panels correctly, and each panel `X` closes correctly.
  - User visual feedback on 2026-05-10: Rebirth panel is acceptable overall, but button text was a bit blurry; Rebirth button text was adjusted in Studio from `TextScaled` heavy text to fixed-size Bold text with `UITextSizeConstraint`.
  - `VAL-03` growth loop validation passed on 2026-05-10 with temporary Studio-only seeded state: purchasing `Lucky Nickel` and `Green Felt` deducted Cash from 3000 to 2560, equipped both items, and synced the Shop preview plus Inventory loadout.
  - `VAL-03` equip switching passed on 2026-05-10: equipping `Rusty Penny` and `Folding Table` after purchase did not deduct more Cash and synced Shop / Inventory loadout text back to starter items.
  - `VAL-03` Rebirth upgrade validation passed on 2026-05-10: buying `Polished Start` spent 1 RP, updated the card to `Lv.1/5`, left 2 RP banked before rebirth, and immediately raised HUD Value to `Lv.1`.
  - `VAL-03` rebirth-after-upgrade validation passed on 2026-05-10: rebirth reset Cash to 30, increased banked RP to 10, preserved `Polished Start Lv.1/5`, kept HUD Value at `Lv.1`, kept the player seated, and a post-rebirth `Space` flip updated Cash to 31.
  - MCP synthetic clicking is not authoritative for Shop / Inventory category tab touch. Data/render sync for both Coin and Desk loadout paths passed via server requests; user should still tap category tabs on device / Studio touch if judging final feel.
  - `VAL-04` text polish applied on 2026-05-10: Shop / Inventory tab and action button text changed from scaled Heavy text to fixed-size Bold text with `UITextSizeConstraint`, matching the Rebirth button clarity fix.
  - `VAL-04` Shop button labels shortened on 2026-05-10: Shop cards now show `On` for equipped and `Need` for unaffordable items, avoiding clipped `Equipped` / `Need Cash` text on phone-width buttons.
  - `VAL-04` Inventory polish applied on 2026-05-10: the unbound `ApplyButton` was hidden because equip changes apply immediately through item-card buttons; runtime screenshot confirmed the loadout panel still reads cleanly.
  - `VAL-05` source codification completed on 2026-05-10: `CoinFlipSystem/ui.lua` now applies the fixed-size Bold text polish and hides the unbound Inventory `ApplyButton` during `CoinFlipUi.Init()`, so the behavior does not depend on manual Studio instance edits.
  - `VAL-05` runtime verification passed on 2026-05-10: Play mode confirmed Shop tab / buy buttons, Inventory equip buttons, Rebirth confirm button, and hidden Apply state all inherit from the new code path.
  - `VAL-06` tab target polish applied on 2026-05-10: Shop and Inventory category tabs now get runtime `Size = UDim2.fromScale(0.92, 0.15)`, increasing phone runtime height from about 29px to about 34px while staying Scale-first.
  - `VAL-06` runtime screenshot checked on 2026-05-10: enlarged tab targets still fit the panel, keep clean spacing, and do not overlap card content.
  - MCP synthetic clicking still did not reliably trigger category tab switching even after target enlargement, so final `COINS / DESK / OTHER` tab switching must be confirmed by user touch input.
  - `VAL-07` source / Studio hygiene passed on 2026-05-10: no `Codex_VAL` temporary validation scripts remain in source or Studio, Play is stopped, and `git diff --check` only reports existing CRLF conversion warnings.
  - `VAL-07` UI constraint naming cleaned on 2026-05-10: runtime-created text constraints now use `GrowthTextSizeConstraint` instead of the temporary `CodexTextSizeConstraint` name, with compatibility for already-existing old instances.
  - `VAL-08` Studio asset naming cleanup passed on 2026-05-10: 25 existing `CodexTextSizeConstraint` instances under `StarterGui.Main` were renamed to `GrowthTextSizeConstraint`; Studio tree now has no `Codex`-named instances.
  - `VAL-09` landscape tab target layout adjusted on 2026-05-10: growth panels now use `Position = UDim2.fromScale(0.65, 0.51)` and `Size = UDim2.fromScale(0.62, 0.72)` on mobile landscape, moving Shop / Inventory category tabs away from the left TouchGui thumbstick area.
  - `VAL-09` Studio phone screenshot checked on 2026-05-10: Shop panel still fits cleanly, tab labels remain readable, item cards and loadout preview do not overlap, and the tab column is no longer visually sitting over the left stick.
  - MCP `user_mouse_input` remains unreliable for `uiController.SetButtonHoverAndClick` buttons, including the already user-confirmed growth entry buttons, so it is not authoritative for tab touch confirmation.
  - Console notes from validation: one `CashCard` error came from an incorrect assistant probe path, not game code; `Sit : param is not a Humanoid or humanoid is dead` appeared during forced death but recovered to a seated state; existing Studio style warnings for `RoundedCorner8` are not represented in Rojo source search.
  - `FRAMEWORK.md` §8 was read for this implementation pass on 2026-05-10.
- Decisions:
  - Brand/table population is removed from the main UI plan.
  - UI production comes before logic wiring so the data contract can match the final visible surfaces.
  - Rebirth, Shop, and Inventory are treated as first-class launch systems, but their panels must not obscure the `FLIP` loop unless intentionally opened.
  - Any new persisted fields must be handled in one change across `Keys.DataKey`, `DefaultData`, `DebugData`, runtime read/write points, and downstream consumers.
  - Rebirth Points reuse persisted `fateShards` instead of adding a duplicate point currency.
  - Legacy `RebirthSystem` remains disabled because it depends on currently inactive systems and old UI paths; the launch Rebirth flow is handled inside active `CoinFlipSystem`.
  - Legacy onboarding / spectator / overview overlays stay hidden during the new mobile UI pass so button entry opens are not blocked.
  - The new panels are Scale-first and were validated in Studio Play on the phone device with screenshots for main HUD, Rebirth, Shop, and Inventory.
  - `CoinFlipMenu` is reparented from `Main.Buttons` to `Main` at runtime so its nested TextButtons can sit above touch controls and receive input reliably.
  - `Main.DisplayOrder` is raised above Roblox `TouchGui`; legacy `OpeningUI.Frame` and `Notifications.TipFrame` are hidden at UI startup because they were covering current main UI hit tests.
  - Rebirth button labels should avoid `TextScaled` at small button heights; fixed text sizes read cleaner on the phone viewport.
  - Shop / Inventory small buttons follow the same fixed-size Bold text rule; status labels should stay short enough to fit the actual phone button width.
  - Inventory loadout applies immediately from item cards, so an unbound separate Apply button should stay hidden unless a real staged-loadout flow is added.
  - Studio-only UI polish should be codified in runtime UI setup when the corresponding instances are not represented as Rojo source files.
  - Category tabs should stay larger than the original 0.12 scale height on phone; 0.15 scale height is the current compromise between touch target and compact panel layout.
  - Mobile landscape growth panels should stay shifted right and slightly narrower so left-side category tabs do not compete with Roblox TouchGui controls.
  - Temporary validation helper names should not remain in runtime-created Studio instances; use project-facing names for UI helper instances.
  - Next manual validation should focus on Shop / Inventory category tab touch feel and any remaining visual polish, especially text clarity and spacing under real phone input.

## Current Baseline

- 首发方向：单桌 `8` 人弱社交桌面运气游戏；玩家进服后自动分配座位并立即坐下，暂不支持主动离座或手动切桌。
- 核心循环：玩家面前一个明确的 `FLIP` 主按钮；HUD 点击、`Space`、手柄 `RT` 都走统一 Flip 入口，`Space` 不再触发跳跃或离座。
- 桌面视角：idle 使用可自由转向的头部第一人称，自己的 Flip 期间临时跟随硬币，落下后回到 idle。
- 弱社交反馈：其他座位的 flip / streak / 高光只做低噪音反馈；头部姿态经服务端驱动角色关节复制，用户真双客户端验证确认会同步到另一个客户端。
- 主 UI / Billboard / 世界表现资源以 Studio 预制为目标；代码主要负责读取、绑定、显隐和更新数值。
- 旧座位 Billboard、复杂观战面板、旧 spectator feed / table overview 已退出主流程。
- 单桌满员链路按逻辑验证通过：`8` 个座位、自动分配、满员等待、空位释放后再分配、重生回座和离服清理闭环成立。

## Decisions

- 旧“围观优化版”计划已失效，不继续做多桌大厅、空位抢座引导、离座按钮、手动切桌或复杂观战面板。
- 当前核心体验是“进服即坐下，面前一个巨大明确的 `FLIP` 按钮，循环简单但上头”。
- 弱社交成立：不做强聊天 / 自由移动 / 主动组队，但要让玩家感觉自己坐在一张正在发生事的桌上。
- 桌面沉浸视角前置；首发采用项目内两态相机，不接第三方 `Open FPC`。
- 头部姿态只是弱互动反馈，不做全身 IK；采用服务端驱动角色关节 C0，客户端只上报相机相对身体的 pitch / yaw。
- 玩家重生后应重新回到可用座位，不进入自由行走态。
- 复杂客户端视觉、多客户端、移动端设备或 Studio-only 观感验证交由用户手动确认；Codex 不用不稳定工具强行给出视觉通过结论，只记录可自动覆盖的源码 / 单客户端 sanity 和用户回传结果。

## Known Follow-Ups

当前没有明确排期的 follow-up。等待用户基于当前版本补充新的任务。

## Backlog / Ideas

- `P2` 首发成长闭环：轻量 `RebirthSystem`、`CoinLoadoutSystem`、6 枚首发功能硬币、Auto Flip、少量每日目标、Profile XP。
- `P3` 首发表现与运营：庆祝 VFX / SFX、桌面轻表情 / cheer、基础商城和 gamepass、核心埋点、移动端和触屏适配。
- 可评估极简决策点：高 streak 后出现 `Cash Out` / `Double` / bonus choice，但不要破坏“一键 Flip”的主循环。

## Done

### 2026-05-08 HTML UI redesign for rebirth / shop / inventory

- Outcome: 将 `flip_a_coin_ui_design.html` 更新为新的静态 HTML UI 原型，覆盖主界面、重生、商店、背包；设计围绕当前单桌桌面视角和强 `FLIP` 主按钮，新功能通过左侧图标入口打开覆盖层。
- Validation: `git diff --check` 通过；锚点目标检查通过；必需页面区块检查通过。Codex in-app browser 后端本轮不可用，未能做实际浏览器截图验证。

### 2026-05-08 LoadingScreen legacy 退场

- Outcome: 删除未启用的 `src/ReplicatedFirst/LoadingScreen` 旧加载屏目录；当前启动链只保留 `Loading.client.lua` 挂载 `RobStar`。同时清理了 `Loading.client.lua` 与 `RobStar.LocalScript` 中指向旧 LoadingScreen / Loader 的注释引用，并同步 `PROJECT_LOGIC.md`。
- Validation: `git diff --check` 通过；引用扫描确认源码不再引用旧 `LoadingScreen` / `Loader.lua` 主路径；`rojo build --output /private/tmp/flipacoin-loading-check.rbxlx` 通过。

### 2026-05-08 Announcement banner runtime creation 收口

- Outcome: `AnnouncementSystem/ui.lua` 不再运行时创建顶部 `StreakAnnouncementBanner`；streak 播报保留 `uiController.SetNotification` 与可选音效。`PROJECT_LOGIC.md` 已同步为轻量 notification / sound 反馈口径。
- Validation: `git diff --check` 通过；引用扫描确认 `AnnouncementSystem/ui.lua` 已无 `Instance.new`、`TweenService`、`StreakAnnouncementBanner`、banner UI 子节点残留。

### 2026-05-08 CoinFlip onboarding fallback 收口

- Outcome: `CoinFlipSystem/ui.lua` 不再绑定旧 `CoinFlipOnboarding` guide 子节点，也不再运行时创建 `ProgressText` / `Steps` / step chip；客户端只查找旧面板并保持隐藏。`PROJECT_LOGIC.md` 已同步为“服务端 onboarding 状态仍用于头顶文案和漏斗埋点，主 HUD 不再显示旧 guide 面板”。
- Validation: `git diff --check` 通过；引用扫描确认旧 onboarding runtime creation 关键词不再存在于 `CoinFlipSystem/ui.lua`。`stylua --check` 未执行成功，因为当前 Aftman 配置未声明 stylua。

### 2026-05-08 单桌桌面 Flip 核心体验收口

- Outcome: 完成单桌 `8` 人方向校准、自动入座、强制坐席、统一 Flip 输入、两态第一人称相机、重生再绑定、头部姿态同步、旧 Billboard / 观战 UI 退场、三栏 Flip HUD 预制绑定、同桌轻高光与 coin pulse 预制化。
- Validation: 单人 Studio Play 覆盖自动坐下、HUD、`Space` / HUD 点击 / `RT` Flip、重生回座、旧表现隐藏；单桌满员采用源码状态机审查 + 资源检查 + 单客户端 sanity；用户真双客户端验证确认头部姿态同步。

### 2026-05-08 验证边界规则收口

- Outcome: 已明确复杂客户端视觉、多客户端、移动端设备或 Studio-only 验证不作为 Codex 自动化阻塞项；Codex 记录可行验证，最终观感由用户手动确认并回写。

### 2026-05-06 新对话启动路由优化

- Outcome: 新增 `docs/BOOTSTRAP.md` 作为低成本启动路由；`AGENTS.md`、`FRAMEWORK.md`、`PROJECT_LOGIC.md` 已改为先读 bootstrap 和 `TASK_STATE.md` Active，再按任务类型读取相关章节。

### 2026-05-04 Docs 收敛与旧 Markdown 清理

- Outcome: `docs/` 收敛为 `FRAMEWORK.md`、`PROJECT_LOGIC.md`、`TASK_STATE.md` 三份核心文档；旧策划、旧路线图、旧执行进度、旧系统拆分和旧架构梳理 Markdown 已删除，旧引用已改为核心文档说明。

### 2026-05-01 文档状态迁移与产品方向校准

- Outcome: 新建 `docs/TASK_STATE.md` 并迁入当时的执行状态、任务表、决策、验证记录与后续项；明确首发不是多桌大厅或强社交 simulator，而是单桌 `8` 人、弱社交、高频 Flip、强按钮反馈的桌面运气游戏。

## Maintenance Rules

- 每次开始新任务，在 `## Active` 添加一条，至少写 `Started / Status / Progress / Next / Decisions`。
- 任务完成后移动到 `## Done`，写一行 outcome 和日期。
- 新发现但不排期的想法放到 `## Backlog / Ideas`，保持单行。
- 若代码和本文件冲突，先确认代码，再更新本文件。
