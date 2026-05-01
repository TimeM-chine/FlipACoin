# TASK_STATE

最后更新：2026-05-01

> 目的：记录当前正在做什么、下一步是什么、已做验证、关键决策与后续想法。项目事实放 `PROJECT_LOGIC.md`，框架规则放 `FRAMEWORK.md`。

## Active

### 首发优化重置：单桌自动入座 / 桌面视角 / 统一 Flip 输入 / HUD 收口

- Started: 2026-04-19
- Status: `进行中`
- Owner: cross-session handoff
- Scope:
  - 产品方向校准为单桌 `8` 人弱社交桌面运气游戏，参考“坐在桌上持续打牌 / 翻牌”的轻桌游体验。
  - 每个服务器只有一张主桌，玩家进服后自动分配座位并立即坐下。
  - 玩家暂时不能离座，也不做手动切桌。
  - 镜头进入桌面沉浸视角，优先保证玩家能看到自己的 Flip、桌面和轻量同桌反馈。
  - Flip 输入统一支持 HUD 点击、`Space`、手柄 `RT`。
  - `Space` 不再触发跳跃或离座。
  - 不再显示旧座位 `BillboardGui` / 复杂观战面板。
  - 参考示意图重做 `Flip HUD`，主按钮居中，两侧承载信息。
  - 保留弱社交桌面存在感：其他座位的 flip / streak / 高光只做低噪音反馈，不做强社交。
  - 主 UI / Billboard / 世界资源改为 Studio 预制，代码只负责绑定与显隐。

Progress:

- 已完成旧围观优化方向重置。
- 已完成第一人称社区方案检索，`Open FPC` 作为优先评估候选。
- 已完成 `M0-03` Studio 资源清单冻结。
- 已落 `M1-01` 自动分配空座位首版代码。
- 已落 `M1-02 / M1-03` 强制坐席首版代码。
- 已落 `M1-04` 旧 prompt / AFK 逻辑退场首版代码。
- 已落 `M3-01 / M3-02 / M3-03` 统一 Flip 输入首版代码。
- 已完成单人 Studio Play 回归，确认自动入座、`Space`、手柄 `RT` 与 HUD 点击共用 Flip 主路径。
- 已落 `M2` 第一人称 fallback 首版模块，并完成单人 Studio Play 定向回归。
- 已补 `TableSeatSystem` seat key、满桌等待队列与重生后回座位状态同步首版代码。
- 已完成单人 Studio Play 回归，确认第一人称下重生后会重新坐回座位，HUD 与 `Space` Flip 继续正常。
- 已完成产品方向校准：不再追多桌大厅，首发聚焦单桌 `8` 人、弱社交、强 `FLIP` 按钮、高频短循环。
- 已落 `M4-01 / M4-02` 代码级退场首版：服务端不再刷新旧座位 Billboard，客户端隐藏旧 Billboard、spectator feed 和 table overview。
- 已落 `M4-03 / M4-04` 首版：Studio 预制版 Flip HUD 现在是左 / 中 / 右三栏结构，主 HUD 绑定改为读取预制节点，不再为统计卡、升级按钮或 Leave 按钮运行时创建兜底资源。
- 已按逻辑验证完成单桌 `8` 人满员链路审查：场景确认为 `8` 个 Seat，自动分配 / 满员等待 / 空位释放后再分配 / 重生回座 / 离服清理链路闭环成立。
- 已补等待队列边界：等待玩家若在空位出现时角色暂不可坐，不会从等待队列丢失，会继续等待下一轮自动入座。

Next:

- 决定当前 head-camera fallback 是否足够，优先做“桌面沉浸视角”而不是封闭第一人称。
- 清理 `M4-01 / M4-02`：旧座位 Billboard、spectator feed、table overview、复杂 featured seat 表现退出主流程。
- 设计低噪音同桌反馈：其他玩家 flip、当前 streak、高 streak 全桌轻微高光。

Decisions:

- 旧“围观优化版”计划已失效，不继续做多桌大厅、空位抢座引导、离座按钮、手动切桌、复杂观战面板。
- 当前核心体验是“进服即坐下，面前一个巨大明确的 `FLIP` 按钮，循环简单但上头”。
- 弱社交成立：不做强聊天 / 自由移动 / 主动组队，但要让玩家感觉自己坐在一张正在发生事的桌上。
- 桌面沉浸视角前置，不排到最后；当前先保留项目内 head-camera fallback，若不舒服再调相机，而不是急着接第三方 `Open FPC`。
- 玩家重生后应重新回到可用座位，不进入自由行走态。
- 首发只有一张主桌，最大 `8` 人；满桌时做等待 / 降级处理。
- “资源全部预制到 Studio”的口径是主资源预先存在，代码只负责读、绑、显隐、改字、改值。
- 由于本机 Studio 难以稳定开启 `8` 个客户端，单桌满员这类高资源场景不强求实机 Team Test；采用源码状态机审查、场景资源检查、单客户端 sanity 与必要边界补丁作为可接受验证。

Milestone Outline:

- `M0` 范围冻结与资源清点：停掉旧围观方向，明确 HUD / 输入 / 相机 / 座位资源清单。
- `M1` 单桌自动入座与强制坐席：服务端在唯一主桌分配空座位，`PlayerAdded / CharacterAdded` 后自动坐下，禁用离座、跳跃离座和 AFK 踢座主路径。
- `M2` 桌面沉浸相机：优先保证桌面、自己的硬币、同桌轻量反馈可读；覆盖坐姿、头部遮挡、穿模、重生再绑定。
- `M3` Flip 输入统一：HUD 点击、`Space`、手柄 `RT` 都走同一个 `RequestFlip` 入口，`Space` 不再导致跳跃。
- `M4` HUD 重做与旧表现清理：删除旧座位 Billboard、spectator feed、table overview、复杂 featured seat 表现，HUD 改成 Studio 预制绑定，并补轻量同桌反馈。
- `M5` 回归验证与文档续写：覆盖单人、单桌 `8` 人满员、重生、桌面视角和三输入。

Current Code Conflicts To Remove:

- `TableSeatSystem` 仍保留 `RequestStand`、`SeatInfoBillboard`、featured seat 计算、audience / spectator 同步语义。
- `CoinFlipSystem/ui.lua` 仍保留隐藏态 `CoinFlipSpectatorFeed`、`CoinFlipTableOverview` 与对应 overview row / onboarding step 兜底创建逻辑。
- 当前主 HUD 已改成预制节点绑定；剩余运行时 UI 创建点主要在旧 overview / onboarding / 世界落点 pulse / Announcement banner，后续按是否保留对应表现决定清理或预制。
- 旧代码里的多桌 / 观战命名要按单桌 `8` 人语义收敛；不要继续扩展为大厅式多桌系统。

M0-03 Resource Freeze:

- Current `StarterGui.Main.Elements` includes `CoinFlipHUD`、`CoinFlipOnboarding`、`CoinFlipTableOverview`、`CoinFlipSpectatorFeed` and `_backup` variants.
- Current `CoinFlipHUD` includes `Content.LeftPanel`、`Content.CenterPanel`、`Content.RightPanel`。
- `LeftPanel` includes Cash / Streak cards, `CenterPanel` includes `SeatLabel`、`ResultLabel`、`FlipButton`、`InputHints.SpaceHint`、`InputHints.GamepadRTHint`，`RightPanel` includes Chance / Speed cards and four upgrade buttons.
- Legacy `Stats` / `Actions` containers may still exist under `Content` as hidden compatibility leftovers, but the active HUD binding no longer reads them.
- Current `Workspace.CoinFlipTable` includes `Seats.Seat01` through `Seat08`、`Prompt`、`SeatInfoBillboard`、`Attachments`、`Assets.CoinVisuals`、`TableTop`、`TableBase`、`SpectatorZone`.
- New `CoinFlipHUD` should be Studio-prebuilt with `LeftPanel` cash / streak cards, `CenterPanel` flip button / result / input hints, and `RightPanel` chance / speed cards plus four upgrade buttons.
- Each upgrade button should be prebuilt with `Title`、`Level`、`Cost`、`UICorner`、`UIStroke` and text constraints.
- Input hint nodes should be prebuilt as `SpaceHint` and `GamepadRTHint`.
- Camera module boundary: module under `StarterPlayer.StarterPlayerScripts.Modules.FirstPersonCamera` or equivalent; project adapter in `StarterPlayer.StarterPlayerScripts` or `CoinFlipSystem` client init; camera module only owns local camera, mouse behavior, local transparency, and respawn rebinding.
- Seat resources to keep: `Workspace.CoinFlipTable.Seats` as automatic seat pool, `Attachments` as visual / camera anchors, `Assets.CoinVisuals` as coin visual presets.
- Resources exiting the launch path: seat `Prompt` main flow, `SeatInfoBillboard`, `CoinFlipTableOverview`, `CoinFlipSpectatorFeed`, complex `featured seat`, spectator / audience presentation, empty-seat prompt onboarding.
- Replacement presentation direction: one strong center `FLIP` button plus low-noise table signals for other seats, streak spikes, and all-table hype moments.
- Runtime creation points still left in `CoinFlipSystem/ui.lua`: onboarding fallback nodes, table overview rows, legacy overview subtitle / empty label, text / size constraints for non-main-HUD legacy paths, and `CoinLandingPulse`.
- `AnnouncementSystem/ui.lua` still creates the top banner at runtime. If launch keeps announcements, add a Studio-prebuilt banner template; otherwise remove this presentation path in cleanup.
- `ReplicatedFirst/LoadingScreen/Loader.lua` still has loading-screen runtime creation. It is not blocking `M0-03`, but belongs in a later cleanup if the prebuilt-resource rule expands to loading UI.

Task Table:

| ID | Module | Priority | Status | Acceptance / Current Note | Updated |
| --- | --- | --- | --- | --- | --- |
| `M0-01` | 进度文档重置 | `P0` | `已完成` | 旧围观计划已清空，新需求口径已重置 | 2026-04-19 |
| `M0-02` | 第一人称社区检索 | `P0` | `已完成` | `Open FPC` 可作为优先评估候选 | 2026-04-19 |
| `M0-03` | Studio 资源清单冻结 | `P0` | `已完成` | 已确认预制资源、待退场旧资源、新 HUD 预制结构、输入提示节点与相机模块边界 | 2026-04-19 |
| `M1-01` | 自动分配空座位 | `P0` | `已完成` | 逻辑验证确认 `8` 座顺序分配、满员等待、空位释放后再分配闭环成立 | 2026-05-01 |
| `M1-02` | 自动坐下链路 | `P0` | `已完成` | 自动入座已接 `PlayerAdded / CharacterAdded` 与脱座回拉逻辑，单人 sanity 通过 | 2026-05-01 |
| `M1-03` | 禁止离座与跳座 | `P0` | `进行中` | 已关闭 `RequestStand` 主路径、禁用跳跃状态与触屏跳跃按钮 | 2026-04-19 |
| `M1-04` | 旧 prompt / AFK 逻辑退场 | `P1` | `进行中` | 已停掉客户端 `PromptShown` 主链路、服务端 AFK 踢座已关闭 | 2026-04-19 |
| `M2-01` | 桌面沉浸视角评估 | `P0` | `进行中` | 当前先以项目内 head-camera fallback 对齐目标效果，后续重点是桌面和同桌反馈可读性 | 2026-05-01 |
| `M2-02` | 视角回退方案 | `P1` | `进行中` | 已落自实现 fallback：相机贴头、隐藏头与配件、身体可见、鼠标不锁中心 | 2026-05-01 |
| `M2-03` | 重生与再绑定 | `P0` | `进行中` | 单人回归确认 HUD 和视角都会恢复；待单桌满员验证 | 2026-05-01 |
| `M3-01` | `Space` Flip 绑定 | `P0` | `进行中` | 已通过 `ContextActionService` 接到统一 Flip 入口 | 2026-04-19 |
| `M3-02` | 手柄 `RT` Flip 绑定 | `P0` | `进行中` | 已通过 `ContextActionService` 接到统一 Flip 入口 | 2026-04-19 |
| `M3-03` | HUD 点击 Flip 统一入口 | `P0` | `进行中` | HUD 点击、`Space`、`RT` 统一走 `requestFlip()` | 2026-04-19 |
| `M4-01` | 移除旧座位 BillboardGui | `P0` | `进行中` | 已停用服务端刷新与客户端显示，待 Studio Play 确认旧 `SeatInfoBillboard` 不再出现 | 2026-05-01 |
| `M4-02` | 移除旧围观 HUD 链路 | `P0` | `进行中` | 已隐藏 `CoinFlipSpectatorFeed`、`CoinFlipTableOverview`、复杂 featured seat 表现；待补新轻量桌面反馈 | 2026-05-01 |
| `M4-03` | 新 Flip HUD 预制资源 | `P0` | `已完成` | 已补 Studio 预制三栏结构：左侧 Cash/Streak，中间 Flip/结果/输入提示，右侧 Chance/Speed/四升级 | 2026-05-01 |
| `M4-04` | HUD 绑定改为预制模式 | `P0` | `已完成` | 主 HUD 已改为读取预制节点，不再为统计卡、升级按钮或 Leave 按钮运行时创建兜底资源 | 2026-05-01 |
| `M5-01` | 单人首轮回归 | `P0` | `已完成` | 单人 Play 确认自动坐下、HUD 可见，`Space` / HUD 点击 / `RT` 均可 Flip | 2026-05-01 |
| `M5-02` | 单桌满员验证 | `P0` | `已完成` | 按逻辑验证口径通过：`8` 个座位、等待队列、空位再分配、重生回座与离服清理链路成立 | 2026-05-01 |
| `M5-03` | 文档续接维护 | `P0` | `进行中` | 每轮实现后都回写本文件的状态、决策与测试结论 | 2026-05-01 |

Status values:

- `未开始`
- `进行中`
- `已完成`
- `阻塞`

## Validation Log

### 2026-04-19 资源审计

- Checked `StarterGui.Main.Elements`、`Workspace.CoinFlipTable`、活跃系统运行时创建点与旧围观链路。
- Found existing `CoinFlipHUD`、`CoinFlipOnboarding`、`CoinFlipTableOverview`、`CoinFlipSpectatorFeed` and backups.
- Found `CoinFlipHUD` 仍缺升级区等预制节点，`CoinFlipSystem/ui.lua` 仍靠 fallback 创建主节点。
- Found `Seat01` 到 `Seat08` 仍带 `Prompt` 和 `SeatInfoBillboard`。
- Result: `M0-03` completed; feeds `M4-01` through `M4-04`.

### 2026-04-19 自动入座代码级校验

- `TableSeatSystem` 已新增空座位选择与自动入座重试逻辑。
- 新玩家进入时绑定 `CharacterAdded`，角色可用后自动调用 `RequestSit`。
- 座位 `Prompt` 在代码路径里会被强制禁用，不再作为主流程入口。
- `rojo build --output build-test.rbxlx` passed.
- Remaining risk: 未做 Studio Play 真机回归；临时 `build-test.rbxlx` 当时因路径访问被拒绝未删除。

### 2026-04-19 强制坐席代码级校验

- 座椅 `Occupant` 变空时，若玩家仍存活，会重新进入自动入座流程。
- `RequestStand` 不再触发离座清理，而是回到自动入座逻辑。
- 服务端和客户端都禁用跳跃状态，触屏 `JumpButton` 已隐藏。
- HUD 默认提示改成自动分配和 Flip 口径。
- `rojo build --output build-test-2.rbxlx` passed.
- Remaining risk: `LeaveSeatButton` 资源和 fallback 函数仍在，真正删链路放到 `M4`。

### 2026-04-19 旧 prompt 退场与 Flip 输入统一代码级校验

- 服务端不会再因 AFK 定时器把在线玩家踢离座位。
- 客户端不再依赖座位 `Prompt` 作为 onboarding 或主交互入口。
- `Space` 与手柄 `RT` 已通过 `ContextActionService` 接入，与 HUD 点击共享 `requestFlip()`。
- `rojo build --output /tmp/flipacoin-codex-build.rbxlx` passed.
- Remaining risk: spectator / overview / billboard 链路仍待 `M4` 清理。

### 2026-04-19 单人 Studio Play 首轮回归

- 玩家进入 Play 后自动落到 `Workspace.CoinFlipTable.Seats.Seat05`。
- 角色 `Humanoid.Sit = true`，`JumpHeight = 0`。
- `Space` 成功触发真实 Flip，HUD 返回 `Heads! +$ 7`。
- 手柄 `RT` 成功触发真实 Flip，HUD 返回 `Tails! +$ 1 | Streak reset...`。
- 两次输入后玩家都保持坐席。
- Remaining risk: 只覆盖单人单桌，未覆盖重生、单桌 `8` 人满员。

### 2026-04-20 第一人称 head-camera 定向回归

- 第一人称从 `LockFirstPerson` 改为项目内 head-camera fallback。
- Runtime check: `cameraToHeadDistance = 0`、`headHidden = 1`、`upperTorsoHidden = 0`、`mouseBehavior = Default`。
- `Space` 在第一人称下仍可正常 Flip，角色保持坐席。
- 重生后第一人称恢复，头部隐藏、身体可见。
- Remaining risk: 使用项目内 fallback，不是 `Open FPC`。

### 2026-04-20 重生回座位联动回归

- 玩家进入后 HUD 显示 `Click FLIP, press Space, or press RT to flip.`。
- `Space` 触发后 HUD 返回真实结算文案。
- 角色重生后 `HumanoidState = Seated`。
- HUD 重生后重新可见。
- Runtime check: `cameraToHeadDistance = 0`、`hudVisible = true`。
- Remaining risk: 单桌 `8` 人满员与等待 / 降级还没有实机覆盖。

### 2026-05-01 旧桌面表现退场代码级校验

- `TableSeatSystem` 的旧 `refreshSeatBillboards()` 已替换为 `disableSeatBillboards()`，保留座位状态同步，不再写入 Billboard 文案。
- `CoinFlipSystem/ui.lua` 不再 `WaitForChild("SeatInfoBillboard")`，旧世界 Billboard 聚焦逻辑只会隐藏旧 Billboard。
- `CoinFlipSpectatorFeed` 和 `CoinFlipTableOverview` 当前保持隐藏，不再进入主流程可见 UI。
- `git diff --check` 通过。
- Remaining risk: 尚未做 Studio Play 视觉回归，无法确认 Studio 内所有旧 Billboard 预制实例都被正确隐藏。

### 2026-05-01 预制版 Flip HUD 首版回归

- Studio `StarterGui.Main.Elements.CoinFlipHUD` 已补 `LeftPanel / CenterPanel / RightPanel` 三栏结构。
- `LeftPanel` 绑定 Cash / Streak，`CenterPanel` 绑定 SeatLabel / ResultLabel / FlipButton / SpaceHint / GamepadRTHint，`RightPanel` 绑定 Chance / Speed 与四个升级按钮。
- `CoinFlipSystem/ui.lua` 主 HUD 绑定已改为读取预制节点，不再为统计卡、升级按钮或 Leave 按钮运行时创建兜底资源。
- 单人 Studio Play：玩家自动坐到 `Seat01`，HUD 可见，角色保持坐席。
- `Space`、HUD 点击 `FLIP`、手柄 `RT` 均触发真实 Flip 结算，HUD Cash / streak / chance / speed / upgrade cost 文案正常更新。
- `git diff --check` 通过。
- Remaining risk: 仍未覆盖单桌 `8` 人满员；旧 overview / onboarding / announcement 的运行时 UI 创建点尚未统一预制或删除。

### 2026-05-01 单桌满员逻辑验证

- 验证口径调整：本机不强求开启 `8` 个 Studio 客户端，满员类验证采用逻辑审查 + 资源检查 + 单客户端 sanity。
- Studio 资源检查：`Workspace.CoinFlipTable.Seats` 下存在 `8` 个 `Seat`。
- 自动分配逻辑：`_FindOpenSeatKey()` 优先保持玩家当前座位，否则按 `_seatOrder` 找第一个无有效 owner 的座位。
- 满员等待逻辑：无空位时 `_QueueAutoSeat()` 在重试后设置 `_playersWaitingForSeat[userId] = true` 并进入 `_seatWaitQueue`，客户端 seatState 会显示 `assignmentStatus = "full"`。
- 空位释放逻辑：`clearSeatOwnership()` 清理 owner / player seat / activity 后调用 `_TryAssignWaitingPlayers()`，队头玩家会重新进入 `_QueueAutoSeat()`。
- 重生回座逻辑：`CharacterAdded` 会重新 `_QueueAutoSeat()`；座椅 `Occupant` 为空但玩家仍存活时也会 defer 回拉自动入座。
- 离服清理逻辑：`PlayerRemoving` 会断开 CharacterAdded、清 auto-seat token、移除等待队列项，再释放座位并广播。
- 已补边界：等待玩家若在空位出现时角色暂不可坐，会继续留在等待队列，不再只 warn 后丢失等待状态。
- 单客户端 sanity：启动后 HUD 可见、玩家坐在 `Seat01`、提示为 `Click FLIP, press Space, or press RT to flip.`。
- `git diff --check` 通过。
- Remaining risk: 未做真实网络延迟下多客户端竞争实测；后续若出现线上抢座异常，优先检查 `_seatOwners` 与实际 `Seat.Occupant` 的同步时序。

## Done

### 2026-05-01 文档状态迁移

- Outcome: 新建 `docs/TASK_STATE.md`，把当前执行状态、任务表、决策、验证记录与后续项从旧进度文档迁入。
- Source docs touched: `docs/FlipACoin_首发优化执行与进度.md`、`docs/FlipACoin_首发路线图与进度.md`、`docs/PROJECT_LOGIC.md`。

### 2026-05-01 产品方向校准

- Outcome: 明确首发不是多桌大厅或强社交 simulator，而是单桌 `8` 人、弱社交、高频 Flip、强按钮反馈的桌面运气游戏。
- Follow-up: 文档与后续实现都应优先服务“进服即坐下，面前一个巨大明确的 `FLIP` 按钮，短循环升级与 streak 情绪曲线”。

## Backlog / Ideas

- `P2` 首发成长闭环：轻量 `RebirthSystem`、`CoinLoadoutSystem`、6 枚首发功能硬币、Auto Flip、少量每日目标、Profile XP。
- `P3` 首发表现与运营：庆祝 VFX / SFX、桌面轻表情 / cheer、基础商城和 gamepass、核心埋点、移动端和触屏适配。
- 可评估极简决策点：高 streak 后出现 `Cash Out` / `Double` / bonus choice，但不要破坏“一键 Flip”的主循环。
- `P4 / v1.1`：Fate Cards、更完整个性化外观、私人桌主题、排行榜扩展、赛季化内容。
- 清理旧 `TODO.md`、旧武器 / 锻造方向、`BaseSystem` 相关过时描述时，优先以当前代码和 `PROJECT_LOGIC.md` 为准。

## Maintenance Rules

- 每次开始新任务，在 `## Active` 添加一条，至少写 `Started / Status / Progress / Next / Decisions`。
- 任务完成后移动到 `## Done`，写一行 outcome 和日期。
- 新发现但不排期的想法放到 `## Backlog / Ideas`，保持单行。
- 若代码和本文件冲突，先确认代码，再更新本文件。
