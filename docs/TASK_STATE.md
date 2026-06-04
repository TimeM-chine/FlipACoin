# TASK_STATE

最后更新：2026-06-04

> 目的：记录当前正在做什么、下一步是什么、关键决策、待验证项与后续想法。项目事实放 `PROJECT_LOGIC.md`，框架规则放 `FRAMEWORK.md`；已完成的历史日志放 `docs/archive/`。

## Active

- 当前没有进行中的实现任务。

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
- Rebirth Points 复用持久化 `fateShards`，不新增重复点数币种。
- Shop 商品卡购买按钮采用底部居中的大按钮，按钮直接显示价格或 `Owned`；Inventory 装备按钮仍采用短状态标签，优先避免挤压长文案。
- Inventory 装备从 item card 立即生效；除非新增 staged-loadout 流程，否则独立 Apply 按钮保持隐藏。
- 运行态 Rebirth / Shop / Inventory 入口使用 TopbarPlus 顶栏按钮；`CoinFlipMenu` 只保留为旧绑定兼容节点，玩法态不再显示。
- Growth panels 保持 Studio-authored 结构但由运行时代码统一套黑底大面板布局；当前游戏具备基础触屏支持，但移动端布局、提示、安全区和实机观感仍需专项收敛。
- `Main.Frames.noUse` 下的 legacy 透明 UI 保持不可交互，避免抢 Rebirth / Shop / Inventory hit test。
- 复杂客户端视觉、多客户端、移动端设备或 Studio-only 观感验证交由用户手动确认；Codex 只记录可自动覆盖的源码 / 单客户端 sanity 和用户回传结果。
- 2026-06-01 及以前的详细完成日志已移入 `docs/archive/TASK_STATE_DONE_2026-05_TO_2026-06-01.md`；live task state 只保留最近完成项和当前交接信息。

## Known Follow-Ups

- Studio / device QA：按 `docs/ROBLOX_PLATFORM_IMPROVEMENT.md` 覆盖手机 portrait / landscape、平板、桌面键鼠、手柄和双客户端同桌，确认 HUD 响应式布局、安全区、growth panels、Topbar 入口与装扮刷新。
- Studio Play：填入真实 Developer Product / Game Pass id 后，确认 Boosts 入口能弹出 Robux 购买 prompt；购买 Cash / Rebirth Points / Apex bundle / VIP / 2x Cash / Lucky Charm / Quick Flip 后刷新 HUD、Shop、Inventory、Rebirth 和座位表现，并记录 `coinflip_gamepass_granted`。
- Creator Dashboard：创建 `cashPackSmall / cashPackMedium / cashPackLarge / rebirthShardSmall / rebirthShardLarge / apexLoadoutBundle / paidCash2x10m` 七个付费 Developer Products、一个 Rewarded Ads 专用 Developer Product，以及 `vip / winsX2 / luckyCharm / quickFlip` 四个 Game Pass；把付费 product id 填回 `Products.flipACoin`，把广告奖励 product id 填回 `RewardedAds.DevProductId`。
- Studio Play：新档默认 Cash 为 `9`，入座后看到首次 Flip 引导；首次 Flip 后进入 v4 Value 升级阶段，Cash 不足时继续高亮 `FLIP`，Cash 达到 `12` 后高亮 HUD 内实际 `ValueButton`，点击升级后进入 Rebirth 引导。
- Studio Play：确认 Phase 0 正反馈调参后的首局节奏，重点看首次升级是否更有反馈、首次 Rebirth 是否过快；如果 Rebirth 明显过快，再单独调整 `RebirthPresets.FlipACoin.Rebirth.MinCash`。
- Studio Play：确认 Rebirth `Coin Spread` 购买后的真实运行体感，重点看多 Coin 立即生效后的世界表现、round streak 是否按成功轮数增减、失败但有 Heads 的奖励是否能接受；源码层已确认购买后 `coinCountLevel` / `coinCount` 会即时同步增长。
- Studio Play：确认 Phase 2 HUD 文案，重点看 `1/1`、`1/3`、`2/3`、`3/3` 等结果是否清楚，`Streak reset` 是否不会和有 Heads 奖励矛盾，移动端是否挤压底部 ResultLabel。
- Studio Play：确认 Phase 3 多金币扇形世界表现，重点看自己的相机是否能看清多枚硬币、扇形是否以玩家到中心落点为中轴、临时 coin / shadow / pulse 是否在下一轮或座位隐藏后清理。
- Studio Play：确认 Phase 4 组合庆祝，重点看 Triple / Four Heads / Perfect / Perfect Five 的落地 VFX 强度、Perfect Five 全桌通知频率、自己高价值组合有 SFX / 轻量 camera shake，而观察者不播放高价值结果 SFX 且不触发 camera shake，Perfect Five / Perfect 结果文案不挤压底部 ResultLabel。
- Studio Play：确认 Phase 5 Bad Luck Pity 体感，重点看连续失败 3 轮后下一轮是否更容易回正但不显得保送、成功后 pity 是否清零、round streak 语义是否保持不变。
- Studio Play 双客户端：确认真实玩家 `5/5 Heads` 触发 Table Bonus 时，同桌其他真实玩家收到 `$15` Cash 和轻 notification，触发者 ResultLabel 追加 Table bonus，fake player 不发共享奖励，并记录内部埋点 `coinflip_table_jackpot`。
- Studio Play：确认 Edge Stand 只在真实玩家失败轮低概率触发，触发时 Tails coin 竖立落桌、当前 round streak 不清零、发 `$8` bonus、ResultLabel 显示 `Edge Stand! Streak saved.`，fake player 不触发，并记录 `coinflip_edge_stand`。
- Studio Play：确认装备高阶 Coin `coin7` 到 `coin10` 后，真实玩家 Edge Stand 触发率按 `edgeStandChanceBonus` 小幅提高且仍受 `EdgeStand.MaxChance` 限制；fake player 仍不触发 Edge Stand。
- Studio Play：确认装备高阶 Coin `coin7` 到 `coin10` 后，`Perfect` / `Perfect Five` 组合奖励按 `perfectRewardMultiplierBonus` 小幅提高，但普通 Heads / Pair / Triple / Four Heads 奖励不被额外放大。
- Studio Play：确认装备高阶 Coin `coin7` 到 `coin10` 后，低概率 Tails reroll 每轮最多触发一次，重掷后最终 `coinResults / headsCount / reward / combo / Edge Stand / Table Bonus` 判定一致，且不会让普通 Flip 结果文案产生困惑。
- Studio Play：确认 Profile XP 每次真实玩家 Flip 后增加 `exp`，达到 `PlayerLevel` 阈值后 `level` 正确提升；fake player flip 不增加 XP，客户端 `ClientData.level / exp` 同步不报错。
- Studio Play：确认轻量每日目标按服务器日写入 `dailyClaim.flipACoinGoals`，真实玩家完成 `Flip 10 times / Flip 15 Heads / Reach a 3 streak` 后自动发 Cash 和轻提示，fake player 不推进目标，重新进服同日不重复领奖。
- Studio Play / Analytics：确认真实玩家进服、session 设备画像、前 `3` 分钟短会话结束、首次入座、首次 Flip、首次 Auto Toggle、首次 run upgrade、首次打开 Shop / Inventory / Rebirth、达到 `10` 次 Flip、离服时分别能写入 `coinflip_session_start`、`coinflip_device_profile`、`coinflip_early_session_end`、`coinflip_first_seat_assigned_latency`、`coinflip_first_flip_latency`、`coinflip_first_auto_toggle`、`coinflip_first_run_upgrade`、`coinflip_first_growth_panel_open`、`coinflip_flip_count_milestone`、`coinflip_session_end`；fake player 不产生 session / milestone 埋点。
- Studio Play 双客户端：确认他人 Heads / Tails 落地 pulse 更明显、Heads streak ring 按 streak 扩大、`streak >= 4` / milestone 有短 Highlight；低 streak best-streak 不再刷全桌大通知；`streak1` / `streak2` 资产缺失时 fallback pulse 不阻塞落地回调。
- Studio Play 双客户端：确认玩家点击 `TableTop` 时本人立即听到 / 看到 table knock，其他客户端在该玩家座位硬币落点附近看到低噪音 ripple / SFX；频繁点击会被服务端 `0.55s` 限频，不会刷屏。
- Studio Play：确认 `coin1` through `coin10` 在真实 Play 运行态能按装备显示，桌面落点和换装刷新观感正常；源码 / Studio 资产层已确认默认 `Copper R Coin`、旧 / 无效 Coin id 归一到 `coin1`、Shop Coin id 和 `Assets.Coins` 一一匹配。
- Studio Play：确认启动后 HUD 从 `Seat --` 切到分配座位并保持稳定；源码层已确认客户端没有本地 `currentSeatId` 时不会发 `RequestFlip()` 或进入本地 flip 等待 / 冷却态，避免旧 seat state 短暂锁住刚同步后的 `FLIP` 按钮。
- Studio Play：确认不同 Coin 自己/他人 flip 视觉观感正常；源码 / Studio 几何层已确认 `coin1` 到 `coin10` 在 `Seat01` 到 `Seat08` 的 Heads / Tails 平铺落点会按 `TableTop` raycast + bounds lift 放在桌面上方，不使用固定尺寸导致沉桌。
- Studio Play：确认 Shop 成功购买 Coin / Desk / Chair 后出现短 notification 并播放购买 SFX；Inventory 装备成功后出现短 notification、播放装备 SFX，并保持座位 Coin / Desk / Chair 立即刷新。
- Studio Play：确认 Desk Setup / Chair 购买或装备后真实 Play 观感正常，模型坐在桌面上且不遮挡 Coin；源码 / Studio 资产层已确认旧 / 无效 Desk Setup 和 Chair id 会归一到默认 `"1"`、商品 id 与资产一一匹配、入座 / 离座 / 离服清理路径存在。
- Studio Play：最终看一遍桌面版 Rebirth / Shop / Inventory 视觉比例、tab 状态、打开关闭流程；MCP synthetic click 对这些按钮不可靠。

## Backlog / Ideas

- `P0` 移动端首发剩余收敛：安全区、growth panels、Topbar 入口和真实设备观感 QA。
- `P1` 同桌弱社交补强后续：双客户端 Studio QA，确认低噪音桌面反馈强度和公告频率。
- `P1` 多金币 Flip 后续：Phase 0 正反馈调参、Phase 1 服务端 round 结算、Phase 2 HUD 结果文案、Phase 3 扇形世界表现、Rebirth `Coin Spread` 迁移、Phase 4 组合庆祝强化、Phase 5 Bad Luck Pity、Table Bonus、Edge Stand 和 Lucky Coin Edge Stand / perfect reward / Tails reroll 词条小步已完成；更复杂的符号、花色或可视化词条仍待未来评估。
- `P1` 装扮价值前置：购买 / 装备成功短 notification 与既有 SFX 小步已完成；剩余主要是 Studio 资产观感和真机确认。
- `P2` 首发成长补强：Profile XP 和轻量每日目标已完成；如需完整 Daily 面板，后续用 Studio-authored UI 单独做，不接回旧 `DailySystem / QuestSystem` 主线。
- `P3` 首发表现与运营：核心埋点、基础 gamepass analytics polish、桌面 table reaction、组合庆祝强度和合规语义收敛小步已完成；后续可继续按 Studio 观感反馈微调 VFX / SFX 数值。
- 可评估极简决策点：高 streak 后出现保留本轮 streak 或继续挑战额外 bonus 的轻选择，但不要使用强博彩词，也不要破坏“一键 Flip”的主循环。

## Recent Done

### 2026-06-04 Studio MCP remaining verification pass

- Outcome: 在当前 active Studio `Flip A Coin` 执行剩余可自动覆盖的 MCP 验证，不改源码。Edit-time sanity 通过：`coin1` 到 `coin10` 资产完整；Desk Setup `1` 到 `8`、Chair `1` 到 `11` 资产完整；`Seat01` 到 `Seat08` 的 Seat、CoinLanding / Decoration / Chair / Marker anchor 与 `TableTop.TableCenterAttachment` 均存在；Rebirth / Shop / Inventory prefab 与源码绑定路径一致；`Coin Spread` 的 `polishedStart -> coinCountLevel -> coinCount` 映射为 `0->1`、`1->2`、`2->3`、`3->4`、`4+->5`；Shop Coin / Desk / Chair 和七个 Developer Product 配置覆盖完整。
- Runtime MCP: 单客户端 Play sanity 通过：真实玩家 `MagicalHailuo` 自动入座 `Seat02`，`PlayerGui.Main` 克隆成功，`CoinFlipHUD` 显示 `Tap FLIP` 与主按钮 `FLIP`，Rebirth / Shop / Inventory frame 存在且默认关闭，当前座位 coin visual 存在，`noUse` legacy 容器下没有“有效可见且 Active”的 GuiObject 抢交互。控制台未见 fatal runtime error；有预期 / 非阻断输出：空动画 ID fallback、ProfileService 可保存、Analytics custom event 触发、旧 `RankingListFolder not found` 提示。
- Decisions: 未自动点击 `FLIP`、购买、装备、Rebirth 或 Robux prompt，因为当前 Studio Play 已显示 Roblox API services available，直接操作会影响真实 profile / 外部购买流程；这些保留给用户手动验证。`RewardedAds.DevProductId` 仍为 `0`，需外部创建并填回。
- Validation: Roblox Studio MCP `list_roblox_studios` 确认 active 为 `Flip A Coin`；多段只读 `execute_luau` sanity 和一次 `screen_capture` 完成；Play 已停止回 edit mode。未改 Luau，未运行 `rojo build`。

### 2026-06-04 Rebirth Coin Spread sync sanity

- Outcome: 执行 Rebirth `Coin Spread` 购买后即时同步源码 sanity 小步，不改手机端 UI、不改 Luau 源码。源码核对确认 `RebirthSystem:RequestRebirthUpgrade()` 成功购买 `polishedStart` 后会先更新 `rebirthTree` / `fateShards`，再用新的永久树调用 `RebirthPresets.ApplyFlipACoinRunBaseline()` 把当前 `runData.coinCountLevel` 抬到 baseline，并通过 `CoinFlipSystem:SyncPlayerState()` 立刻重建 `derivedStats.coinCount`。
- Decisions: 当前不需要新增同步事件或额外客户端缓存；`CoinFlipSystem/ui.lua` 已在 `rebirthUpgradePurchased == "polishedStart"` 且 coin count 增长时显示 `Coin Spread unlocked N coins per flip.`，`RebirthSystem/ui.lua` 同步刷新升级卡等级、成本和点数，并复用现有 purchase SFX。
- Validation: 源码核对覆盖 `RebirthSystem/Presets.lua` 的 `Coin Spread -> coinCountLevel` baseline、`RebirthSystem/init.lua` 的购买 / rebirth state 构建 / 同步路径、`CoinFlipSystem/Presets.lua` 的 `GetCoinCount()` / `BuildDerivedStats()`、`CoinFlipSystem/init.lua` 的 `buildClientState()` / `syncPlayerState()`、`CoinFlipSystem/ui.lua` 的购买提示分支和 `RebirthSystem/ui.lua` 的升级卡刷新。未改 Luau，未运行 `stylua`；本机未发现 `luau` / `selene` 命令；未执行 Studio Play，真实多 Coin 购买体感、round streak 语义和失败奖励接受度仍需用户在 Studio 中确认。

### 2026-06-04 Coin landing geometry sanity

- Outcome: 执行 Coin flip 落点 / 不沉桌源码与 Studio anchor sanity 小步，不改手机端 UI、不改源码。源码核对确认 `EffectSystem` 的单 Coin、多 Coin 和 idle 重摆都走 `getFlipPositions()` + `resolveFlatLandWorldPosition()`：先按当前座位 / `CoinLandingAnchor` 得到桌面平面落点，再 raycast 命中 `TableTop`，最后用硬币最终平铺姿态的真实 bounds corner 沿桌面法线做一次 lift，并追加 `CoinSurfaceGap = 0.01`，不再用固定 `coin.Size.X * 0.5` 或重复叠加 lift。
- Decisions: 本轮只做几何和资源 sanity，不替代 Studio Play 对动画、相机可见性、不同 Coin 材质观感和双客户端他人 flip 表现的验证。
- Validation: Roblox Studio MCP 当前 active 实例为 `Flip A Coin`；`Workspace.CoinFlipTable.TableTop` 存在且有 `TableCenterAttachment`，`Workspace.CoinFlipTable.Attachments` 对 `Seat01` 到 `Seat08` 均有 `CoinLandingAnchor`。Studio Luau sanity 对 `coin1` 到 `coin10`、`Seat01` 到 `Seat08`、Heads / Tails 平铺姿态共 `160` 个组合计算落点：`missingAnchors = ""`、`badRays = ""`、`badCoinLifts = ""`、`checkedPlacements = 160`、`minFinalGap ≈ 0.01`、`maxLift ≈ 0.107`。未改 Luau，未运行 `stylua`；未执行 Studio Play。

### 2026-06-04 Seat HUD immediate flip guard

- Outcome: 执行启动后座位 HUD 稳定性 / 立刻点击 `FLIP` 防旧 seat state 小步，不改手机端 UI。`CoinFlipSystem/ui.lua` 的 `requestFlip()` 现在在本地 `currentSeatId` 尚未同步时只显示 `Waiting for seat...` 并返回 `false`，不再提前设置 `awaitingFlipResponse / currentFlipInProgress / localFlipCooldownEndsAt`，也不再向服务端发 `RequestFlip()`；座位状态同步到达后 HUD 能立即按 seated 状态恢复可点。
- Decisions: 服务端 `CoinFlipSystem:RequestFlip()` 的权威座位校验保持不变；本轮只修客户端旧 seat state 竞态，不改变入座分配、自动 Flip、引导、冷却或移动端布局。
- Validation: 源码核对覆盖 `TableSeatSystem.syncCoinFlipSeatState()`、`CoinFlipUi.SyncRunState()`、`CoinFlipUi.SeatStateChanged()` 和 `requestFlip()`；无 seat id 时 `requestFlip()` 返回 `false`，`hudAuto / inputActionAuto` 仍会走既有 `scheduleAutoFlipRequest()` 等待后续 seated 状态。`git diff --check -- docs/TASK_STATE.md docs/PROJECT_LOGIC.md src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua` 通过；`stylua --check src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；本机未发现 `luau` / `selene` 命令；未执行 Studio Play，真实首帧点击体感仍需用户在 Studio 中确认。

### 2026-06-04 Desk and Chair runtime loadout sanity

- Outcome: 执行 Desk / Chair 装扮运行态 sanity 小步，不改手机端 UI。`DecorationSystem:RefreshPlayerDecoration()` 现在通过 `EcoSystem:GetLoadoutState()` 读取已归一化的 `equippedDeskSetup / equippedChair`，再克隆座位桌搭和椅子模型，避免系统 `PlayerAdded` 并发时旧 / 无效存档 id 在入座刷新阶段生成空装饰；无用 `Keys` / `dataKey` require 已清理。
- Decisions: 不改变 Shop / Inventory 解耦规则，不新增 Studio prefab，不调整模型位置或尺寸；本轮只收紧运行态 id 归一化和资源映射 sanity，真实摆放观感仍留给 Studio Play。
- Validation: Roblox Studio MCP 当前 active 实例为 `Flip A Coin`；Studio Luau sanity 返回默认 Desk `"1" / Tall Candle`、默认 Chair `"1" / Round Stool`，Desk 商品 id 为 `1` 到 `8` 且 `missingDesk = "" / badDesk = ""`，Chair 商品 id 为 `1` 到 `11` 且 `missingChair = "" / badChair = ""`；`Workspace.CoinFlipTable.Attachments` 对 `Seat01` 到 `Seat08` 均有 Decoration / Chair anchor fallback。源码核对覆盖 `EcoSystem.normalizeLoadoutData()`、`EcoSystem:RequestEquipItem()`、`DecorationSystem:RefreshPlayerDecoration()` / `ClearPlayerDecoration()`、`TableSeatSystem` 入座 / 离座 / 离服刷新清理路径。`git diff --check -- docs/TASK_STATE.md docs/PROJECT_LOGIC.md src/ReplicatedStorage/Systems/DecorationSystem/init.lua` 通过；`stylua --check src/ReplicatedStorage/Systems/DecorationSystem/init.lua` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；本机未发现 `luau` / `selene` 命令；未执行 Studio Play。

### 2026-06-04 Coin runtime loadout sanity

- Outcome: 执行 Coin 运行态装备 / 旧存档 reconcile 验证小步，不改手机端 UI、不改 Luau 源码。源码核对确认 `EcoSystem.normalizeLoadoutData()` 会在 `GetLoadoutState()` / `GetLoadoutBonuses()` 路径中把无效、缺失或未拥有的 `equippedCoin` 归一到 `EcoPresets.LoadoutDefaults.equippedCoin = "coin1"`，并补 `ownedCoins.coin1 = true`；`CoinFlipSystem.buildClientState()` 和 `RequestFlip()` 会通过这些路径获得归一后的 loadout / bonus；装备成功后 `EcoSystem:RequestEquipItem()` 会刷新 audience state 并 `CoinFlipSystem:SyncPlayerState()`，客户端 `CoinFlipUi.FlipResolved()` 和 `EffectSystem:RefreshPersistentSeatCoins()` 均使用同步 payload 里的 `equippedCoin`。
- Decisions: 本轮只做源码和 Studio 资产 sanity，不替代 Studio Play 对真实换装、Flip 落点、视觉不沉桌和座位刷新体感的验证。
- Validation: Roblox Studio MCP 当前 active 实例为 `Flip A Coin`；Studio Luau sanity 返回 `defaultCoin = "coin1"`、`defaultDisplayName = "Copper R Coin"`、Shop Coin id 为 `coin1` 到 `coin10`、`missingAssets = ""`、`badAssets = ""`、`coinFolderChildren = 10`。源码核对覆盖 `EcoSystem.normalizeLoadoutData()`、`CoinFlipSystem.buildClientState()` / `RequestFlip()`、`EcoSystem:RequestEquipItem()`、`CoinFlipSystem/ui.lua` 的 `coinId` payload 和 `EffectSystem` persistent coin asset fallback。未改 Luau，未运行 `stylua` 或 Studio Play。

### 2026-06-04 Coin asset consistency check

- Outcome: 执行 Coin 资产一致性检查小步，不改手机端 UI、不改源码、不迁移资产。源码配置 `EcoSystem/Presets.lua` 的 Coin 商品 id 连续覆盖 `coin1` 到 `coin10`，`Textures.lua` 的 coin icon 配置也覆盖 `coin1` 到 `coin10`，`DefaultData.lua` 和 `EcoPresets.LoadoutDefaults` 均默认 `equippedCoin = "coin1"`。
- Decisions: Roblox Studio 当前 `ReplicatedStorage.Systems.CoinFlipSystem.Assets.Coins` 已有完整 `coin1` 到 `coin10` 模型，且没有多余子项；本轮只收敛资产 / 配置一致性，不替代 Studio Play 对运行态装备显示、旧存档 reconcile 和桌面落点观感的验证。
- Validation: Roblox Studio MCP 当前 active 实例为 `Flip A Coin`；`InspectInstance("ReplicatedStorage.Systems.CoinFlipSystem.Assets.Coins")` 确认 `childrenCount = 10`，包含 `coin1` 到 `coin10` 且均为 `Model`；Studio Luau 校验返回 `missing = ""`、`extra = ""`。源码扫描确认 `EcoSystem/Presets.lua` 的 Coin item id 为 `coin1` 到 `coin10`，`Textures.lua` 的 icon 配置覆盖 `coin1` 到 `coin10`，`DefaultData.lua` 默认 `equippedCoin = "coin1"` / `ownedCoins.coin1 = true`。`git diff --check -- docs/TASK_STATE.md` 通过；未改 Luau，未运行 `stylua`。

### 2026-06-04 Decoration asset source check

- Outcome: 执行 Studio 资产整理检查小步，不改手机端 UI、不改源码、不迁移资产。已通过 Roblox Studio MCP 切到 `Flip A Coin` 实例并确认 `Workspace.TableDecoration` 不存在；目标目录 `ReplicatedStorage.Systems.DecorationSystem.Assets.TableDecoration` 已有 `1` 到 `8` 共 `8` 个桌搭模型，`ReplicatedStorage.Systems.DecorationSystem.Assets.Chairs` 已有 `1` 到 `11` 共 `11` 个椅子模型。
- Decisions: 当前不需要再执行 live `Workspace.TableDecoration` 迁移；保留 `DecorationSystem.migrateWorkspaceTableDecoration()` 作为未来误放 live asset 的启动兜底。live follow-up 中的 Studio 资产整理项已移除，剩余装扮相关工作主要是 Studio Play 观感验证。
- Validation: Roblox Studio MCP 已切到 `Flip A Coin` 实例；`InspectInstance("Workspace.TableDecoration")` 返回未找到；`InspectInstance("ReplicatedStorage.Systems.DecorationSystem.Assets.TableDecoration")` 确认 `childrenCount = 8` 且子模型为 `1` 到 `8`；`InspectInstance("ReplicatedStorage.Systems.DecorationSystem.Assets.Chairs")` 确认 `childrenCount = 11` 且子模型为 `1` 到 `11`。`git diff --check -- docs/TASK_STATE.md` 通过；未改 Luau，未运行 `stylua`。

### 2026-06-04 Early session end analytics

- Outcome: 执行 P2 数据和埋点小步，不改手机端 UI、不新增持久字段。`AnalyticsSystem:PlayerRemoving()` 在真实玩家当服时长少于 `180` 秒时额外记录 `coinflip_early_session_end`，value 为 session 秒数，字段带 session 设备分类、viewport band 和首局进度阶段，方便按设备口径看前 `3` 分钟流失点。
- Decisions: 复用 `coinflip_device_profile` 写入的当服 session 设备画像；如果玩家在设备画像上报前离服，字段回落为 `unknown`。进度阶段只用现有 session flag 推导为 `joined_no_seat / seated_no_flip / flipped_no_upgrade / upgraded_run / opened_growth_panel`，不新增 profile 或 UI 状态。
- Validation: `git diff --check -- docs/TASK_STATE.md docs/PROJECT_LOGIC.md docs/ROBLOX_PLATFORM_IMPROVEMENT.md src/ReplicatedStorage/Systems/AnalyticsSystem/init.lua` 通过；同批文件行尾空白扫描无命中；符号扫描确认 `coinflip_early_session_end / EarlySessionDuration / _EarlySessionStage / _LogEarlySessionEnd / earlySessionEndLogged` 和 `joined_no_seat / seated_no_flip / flipped_no_upgrade / upgraded_run / opened_growth_panel` 已接入源码和 live docs。`stylua --check src/ReplicatedStorage/Systems/AnalyticsSystem/init.lua` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play 或 Roblox Analytics 后台验证。

### 2026-06-04 Session device profile analytics

- Outcome: 执行 P2 数据和埋点小步，不改手机端 UI、不新增持久字段。`AnalyticsSystem` 新增客户端启动后一次性上报自身设备画像的 `ReportDeviceProfile()` 路径，服务端校验 `sender == player` 并清洗低基数字段后记录 `coinflip_device_profile`；字段覆盖 `touch / keyboard / gamepad / hybrid` 设备分类、`small_portrait / phone_landscape / tablet / desktop` viewport band 和最近输入类型。
- Decisions: `ReportDeviceProfile()` 刻意不放入 `whiteList`，让客户端可通过框架 remote 上报；其余记录方法和 helper 仍保持 `whiteList` 阻断客户端调用。上报只衡量当服 session，不写 profile，不采集原始 viewport 尺寸，不改任何 UI。
- Validation: `git diff --check -- docs/TASK_STATE.md docs/PROJECT_LOGIC.md docs/ROBLOX_PLATFORM_IMPROVEMENT.md src/ReplicatedStorage/Systems/AnalyticsSystem/init.lua` 通过；同批文件行尾空白扫描无命中；符号扫描确认 `coinflip_device_profile / ReportDeviceProfile / deviceProfileLogged / _DeviceClassField / _ViewportBandField / _InputTypeField / _ReportLocalDeviceProfile` 已接入源码和 live docs。`stylua --check src/ReplicatedStorage/Systems/AnalyticsSystem/init.lua` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play 或 Roblox Analytics 后台验证。

### 2026-06-04 First seat assignment latency analytics

- Outcome: 执行 P2 数据和埋点小步，不改座位流程、不改手机端 UI、不新增持久字段。`AnalyticsSystem:LogSeatAssigned()` 保持原有 `coinflip_seat_assigned` 事件，同时在同一当服 session 内首次入座时额外记录 `coinflip_first_seat_assigned_latency`，value 为进服 session start 到成功 seat assigned 的秒数，字段带 duration band、seat assign source 和 seat id。
- Decisions: 复用既有 `TableSeatSystem:RequestSit()` 成功路径，不新增客户端上报或新 profile 字段；重复入座 / 重生回座仍会写原有 `coinflip_seat_assigned`，但 first latency 只写一次。
- Validation: `git diff --check -- docs/TASK_STATE.md docs/PROJECT_LOGIC.md docs/ROBLOX_PLATFORM_IMPROVEMENT.md src/ReplicatedStorage/Systems/AnalyticsSystem/init.lua` 通过；同批文件行尾空白扫描无命中；符号扫描确认 `coinflip_first_seat_assigned_latency / firstSeatAssignedLogged / _GetSessionElapsed / LogSeatAssigned / 首次入座` 已接入源码和 live docs。`stylua --check src/ReplicatedStorage/Systems/AnalyticsSystem/init.lua` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play 或 Roblox Analytics 后台验证。

### 2026-06-04 First-session funnel analytics

- Outcome: 执行 P2 数据和埋点小步，不改手机端 UI、不新增持久字段。`AnalyticsSystem` 新增当服内存 session 去重的一次性漏斗事件：`coinflip_first_auto_toggle`、`coinflip_first_run_upgrade`、`coinflip_first_growth_panel_open`。`CoinFlipSystem` 在服务端 Auto Toggle 上报和 run upgrade 成功路径记录首次事件；`EcoSystem` / `RebirthSystem` 增加服务器校验过的 `ReportGrowthPanelOpened()`，客户端 Shop / Boosts / Inventory / Rebirth 的 Topbar、legacy menu 和 guide 打开路径都会上报 panel、source 和最近输入类型。
- Decisions: 这些漏斗事件只衡量当服首局行为，不写 profile，不影响 onboarding 状态，不新增 UI；Shop 的 Boosts 入口归入 `panel = "Shop"`，通过 `source = "topbarBoosts"` 区分。Auto Toggle 继续保留已有 `coinflip_input_action`，新增 first-event 只做一次性漏斗口径。
- Validation: `git diff --check -- docs/TASK_STATE.md docs/PROJECT_LOGIC.md docs/ROBLOX_PLATFORM_IMPROVEMENT.md src/ReplicatedStorage/Systems/AnalyticsSystem/init.lua src/ReplicatedStorage/Systems/CoinFlipSystem/init.lua src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua src/ReplicatedStorage/Systems/EcoSystem/init.lua src/ReplicatedStorage/Systems/EcoSystem/ui.lua src/ReplicatedStorage/Systems/RebirthSystem/init.lua src/ReplicatedStorage/Systems/RebirthSystem/ui.lua` 通过；同批文件行尾空白扫描无命中；符号扫描确认 `coinflip_first_auto_toggle / coinflip_first_run_upgrade / coinflip_first_growth_panel_open / LogFirstAutoToggle / LogFirstRunUpgrade / LogFirstGrowthPanelOpen / ReportGrowthPanelOpened / openGrowthFrame / openRebirthFrame` 已接入源码和 live docs。`stylua --check` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；本机未发现 `luau` / `selene` 命令；未执行 Studio Play 或 Roblox Analytics 后台验证。

### 2026-06-04 Compliance language pass

- Outcome: 执行 P2 合规语义收敛小步，不改手机端 UI、不改内部 analytics/schema 标识。玩家可见 `5/5 Heads` 结果名从 `Jackpot` 收敛为 `Perfect Five`；全桌共享奖励 notification 从 `Table Jackpot` 改为 `Table Bonus`；座位高 streak Billboard 状态从 `Jackpot` 改为 `Hot Streak`；Shop 中高阶 Coin / Desk / Chair 的 `role = "Jackpot"` 改为 `role = "Perfect"`。`2x Cash / Double Cash` 保持不变，因为它是明确收益的 gamepass 描述，不是随机收益或 streak 决策文案。
- Decisions: 内部 `comboKey = "jackpot"`、`TableJackpot` 配置、`JackpotBonus` 配置字段和 `coinflip_table_jackpot` 埋点保留为历史 schema，避免破坏 analytics / 既有代码引用；文档同步说明它们不是玩家可见文案。Backlog 中未实现的 `Cash Out / Double` 想法改为中性 streak 决策描述，并保留“不使用强博彩词、不破坏一键 Flip”的约束。
- Validation: `git diff --check -- docs/TASK_STATE.md docs/PROJECT_LOGIC.md docs/ROBLOX_PLATFORM_IMPROVEMENT.md docs/MULTI_COIN_FLIP_PLAN.md src/ReplicatedStorage/configs/GameConfig.lua src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua src/ReplicatedStorage/Systems/CoinFlipSystem/init.lua src/ReplicatedStorage/Systems/TableSeatSystem/init.lua src/ReplicatedStorage/Systems/EcoSystem/Presets.lua` 通过；同批文件行尾空白扫描无命中；源码 / live docs 扫描确认不再存在 `Jackpot!`、`Table Jackpot:`、`role = "Jackpot"`、`return "Jackpot"`、`[5] = "Jackpot"` 或 backlog `Cash Out / bonus choice` 落地方向。剩余 `Cash Out / Double / Jackpot` 命中只在平台文档的“避免使用”规则句、历史 Recent Done 或内部 schema key 中。`stylua --check` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play，最终玩家可见文案仍需 Studio 里确认。

### 2026-06-04 Loadout purchase and equip feedback

- Outcome: 执行装扮购买 / 装备即时反馈小步，不改手机端 UI、不新增 prefab。`EcoSystem:RequestShopPurchase()` 成功购买 Coin / Desk / Chair 后通过现有 `GuiSystem:SetNotification()` 显示 `Purchased ...`；`EcoSystem:RequestEquipItem()` 成功装备后显示 `Equipped ...`。客户端原有 `EcoSystem/ui.lua` 仍通过 `purchasedItem / equippedItem` 播放 `shopPurchase / equipItem` SFX。
- Decisions: 本轮只补轻 notification，不改变 Shop 与 Inventory 解耦规则，不自动装备新购买商品；Coin 刷新继续走现有座位状态 / persistent coin 路径，Desk / Chair 继续走 `DecorationSystem:RefreshPlayerDecoration()`。
- Validation: `git diff --check -- docs/PROJECT_LOGIC.md docs/TASK_STATE.md docs/ROBLOX_PLATFORM_IMPROVEMENT.md src/ReplicatedStorage/Systems/EcoSystem/init.lua` 通过；同批文件行尾空白扫描无命中；源码扫描确认 `notifyLoadoutChanged / Purchased / Equipped / shopPurchase / equipItem` 已接入服务端反馈和既有客户端 SFX 路径。`stylua --check` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play，购买 / 装备 notification、SFX 和座位资产刷新仍需 Studio 验证。

### 2026-06-04 Lucky Coin Tails reroll

- Outcome: 执行 Lucky Coin Tails reroll 小步，不改手机端 UI、不新增 Coin 面板、不新增资产、不写持久字段。高阶 Coin `coin7` 到 `coin10` 的现有 `stats` 增加低概率 `tailsRerollChance`，`EcoPresets.BuildLoadoutBonuses()` 汇总该字段，`CoinFlipSystem/Presets.RollCoinResults()` 在初始 roll 后每轮最多把 1 个 Tails 重掷一次；最终 roll 结果再进入 round success、reward、Table Jackpot、Edge Stand 和 Analytics compact outcome。
- Decisions: reroll 是服务端权威的轻量隐藏词条，不新增手动选择、不展示 Coin 词条面板、不额外播放 VFX/SFX；payload 会带 `luckyCoinReroll`、触发 coin index、chance 和最终 result，方便后续调试与 analytics 低基数字段识别。
- Validation: `git diff --check -- docs/MULTI_COIN_FLIP_PLAN.md docs/PROJECT_LOGIC.md docs/TASK_STATE.md src/ReplicatedStorage/Systems/EcoSystem/Presets.lua src/ReplicatedStorage/Systems/CoinFlipSystem/Presets.lua src/ReplicatedStorage/Systems/CoinFlipSystem/init.lua src/ReplicatedStorage/Systems/AnalyticsSystem/init.lua` 通过；同批文件行尾空白扫描无命中；源码扫描确认 `tailsRerollChance / luckyCoinReroll / ApplyLuckyCoinTailsReroll / GetLuckyCoinTailsReroll / Lucky Coin / coin7 / coin10` 已接入文档与源码。Node sanity 覆盖 reroll 后为 Heads 与 reroll 后仍为 Tails 两条路径，确认 heads/tails count 会按最终结果更新。`stylua --check` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play，真实装备高阶 Coin 后的 reroll 体感、结果文案和 AnalyticsService 实际写入仍需 Studio 验证。

### 2026-06-04 Lucky Coin perfect bonus

- Outcome: 执行 Lucky Coin perfect bonus 小步，不改手机端 UI、不新增 Coin 面板、不新增资产、不写持久字段。高阶 Coin `coin7` 到 `coin10` 的现有 `stats` 增加少量 `perfectRewardMultiplierBonus`，`EcoPresets.BuildLoadoutBonuses()` 汇总该字段，`CoinFlipSystem/Presets.GetRoundReward()` 只在 `comboKey == "perfect"` 或 `"jackpot"` 的成功轮把该 bonus 乘到奖励上。
- Decisions: 该词条只扩大高价值全正面组合奖励，不影响普通 Heads、Pair、Triple、Four Heads、round streak、Edge Stand、Table Jackpot 共享奖励或 fake player 触发语义。Tails reroll 仍保留为后续内容，避免当前小步引入二次 roll 和额外表现复杂度。
- Validation: `git diff --check -- docs/MULTI_COIN_FLIP_PLAN.md docs/PROJECT_LOGIC.md docs/TASK_STATE.md src/ReplicatedStorage/Systems/EcoSystem/Presets.lua src/ReplicatedStorage/Systems/CoinFlipSystem/Presets.lua` 通过；同批文件行尾空白扫描无命中；源码扫描确认 `perfectRewardMultiplierBonus / GetRoundReward / Lucky Coin / coin7 / coin10` 已接入文档与源码。Node sanity 覆盖 `heads / pair / triple / fourHeads / perfect / jackpot`，确认普通 Heads / Pair / Triple / Four Heads 不吃额外倍率，`perfect / jackpot` 会按 bonus 放大奖励。`stylua --check` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play，真实装备高阶 Coin 后的 Perfect / Jackpot 奖励体感仍需 Studio 验证。

### 2026-06-04 Lucky Coin trait foundation

- Outcome: 执行 Lucky Coin trait foundation 小步，不改手机端 UI、不新增 Coin 面板、不新增资产、不写持久字段。高阶 Coin `coin7` 到 `coin10` 的现有 `stats` 增加少量 `edgeStandChanceBonus`，`EcoPresets.BuildLoadoutBonuses()` 汇总该字段，`CoinFlipSystem/Presets.GetEdgeStandChance()` 把 loadout bonus 叠加到 Edge Stand 基础概率上。
- Decisions: 当前只是 Coin trait foundation：只影响已上线的 Edge Stand 特殊事件，仍受 `GameConfig.FlipACoin.EdgeStand.MaxChance` 上限约束；fake player 仍不触发 Edge Stand。Tails reroll、perfect bonus 和 Coin 面板词条展示保留为后续内容。
- Validation: `git diff --check -- docs/MULTI_COIN_FLIP_PLAN.md docs/PROJECT_LOGIC.md docs/TASK_STATE.md src/ReplicatedStorage/Systems/EcoSystem/Presets.lua src/ReplicatedStorage/Systems/CoinFlipSystem/Presets.lua src/ReplicatedStorage/Systems/CoinFlipSystem/init.lua` 通过；同批文件行尾空白扫描无命中；源码扫描确认 `edgeStandChanceBonus / GetEdgeStandChance / Lucky Coin / coin7 / coin10` 已接入文档与源码，且 Edge Stand chance 计算传入 `bonusStats`。`stylua --check` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play，真实装备高阶 Coin 后的 Edge Stand 触发率体感仍需 Studio 验证。

### 2026-06-03 Phase 5 Edge Stand small step

- Outcome: 执行多金币 Phase 5 的 Edge Stand 小步，不新增 UI、不新增资产、不改手机端布局、不写持久字段。`GameConfig.FlipACoin.EdgeStand` 新增连续失败压力下的低概率触发配置：真实玩家失败轮触发时，被选中的 Tails coin 会以竖立姿态落桌，当前 round streak 不清零，并给本人 `$8` bonus；客户端 `ResultLabel` 显示 `Edge Stand! Streak saved.`。
- Decisions: Edge Stand 不把失败轮改成成功、不增加 streak、不推进 best-streak，只保护当前 streak 不被清零；失败计数仍会递增，因此不会绕过 Bad Luck Pity 语义。fake player 不触发 Edge Stand，避免假玩家表演过度稳定。表现复用现有 coin settle 姿态和 highlight，不新增 VFX/SFX asset。
- Validation: `git diff --check -- docs/MULTI_COIN_FLIP_PLAN.md docs/PROJECT_LOGIC.md docs/TASK_STATE.md src/ReplicatedStorage/configs/GameConfig.lua src/ReplicatedStorage/Systems/AnalyticsSystem/init.lua src/ReplicatedStorage/Systems/CoinFlipSystem/Presets.lua src/ReplicatedStorage/Systems/CoinFlipSystem/init.lua src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua src/ReplicatedStorage/Systems/EffectSystem/init.lua` 通过；同批文件行尾空白扫描无命中；源码扫描确认 `EdgeStand / GetEdgeStandChance / edgeStandCoinIndex / buildEdgeStandCoinWorldRotation / coinflip_edge_stand` 已接入，且 fake player 不会触发 Edge Stand。`stylua --check` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play，Edge Stand 的触发率、竖立姿态、streak save、bonus 发放、ResultLabel 和 AnalyticsService 实际写入仍需 Studio 验证。

### 2026-06-03 Phase 5 Table Jackpot small step

- Outcome: 执行多金币 Phase 5 的 Table Jackpot 小步，不新增 UI、不新增资产、不改手机端布局、不写持久字段。`GameConfig.FlipACoin.TableJackpot` 新增 `5/5 Heads` 共享奖励配置：真实玩家触发 jackpot 时，本人原有 Jackpot 奖励和庆祝不变，同桌其他真实玩家各获得 `$15` Cash 和轻 notification；触发者 `ResultLabel` 在 Jackpot 文案后追加 Table bonus。
- Decisions: 共享奖励只在真实玩家结算后发放，fake player jackpot 不发 Cash、不写 Analytics。奖励发放逐个玩家走既有 `EcoSystem:AddResource()`，提示走 `GuiSystem:SetNotification()`；Analytics 新增 `coinflip_table_jackpot`，用 `triggered / received` 区分触发者和收奖者，保持低基数字段。
- Validation: `git diff --check -- docs/MULTI_COIN_FLIP_PLAN.md docs/PROJECT_LOGIC.md docs/TASK_STATE.md src/ReplicatedStorage/configs/GameConfig.lua src/ReplicatedStorage/Systems/AnalyticsSystem/init.lua src/ReplicatedStorage/Systems/CoinFlipSystem/Presets.lua src/ReplicatedStorage/Systems/CoinFlipSystem/init.lua src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua` 通过；同批文件行尾空白扫描无命中；源码扫描确认 `TableJackpot / GetTableJackpotAudienceReward / grantTableJackpotRewards / tableJackpotAudienceReward / coinflip_table_jackpot` 已接入，且 fake player 分支不会发共享奖励。`stylua --check` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play，Table Jackpot 的双客户端奖励、notification、ResultLabel 和 AnalyticsService 实际写入仍需 Studio Team Test / Roblox 后台确认。

### 2026-06-03 P3 celebration VFX/SFX polish

- Outcome: 执行 P3 庆祝表现收敛小步，不新增 UI、不新增资产、不改手机端布局。`AnnouncementSystem/Presets.lua` 继续复用现有 `streak5 / bestStreak` 资源，但让 Perfect / Jackpot 对本人触发轻量 camera shake；Triple / Four Heads 保持更低噪音，只播放现有落地 VFX/SFX payload。
- Decisions: 观察者仍能看到他人 milestone 的桌面 VFX / fallback pulse / highlight，但 `CoinFlipSystem/ui.lua` 在 clone celebration payload 时同时写入 `suppressSfx` 和 `suppressCameraShake`，`EffectSystem:PlayStreakMilestone()` 会跳过观察者 camera shake，避免他人高价值组合摇动本地相机。
- Validation: `git diff --check -- docs/PROJECT_LOGIC.md docs/TASK_STATE.md src/ReplicatedStorage/Systems/AnnouncementSystem/Presets.lua src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua src/ReplicatedStorage/Systems/EffectSystem/init.lua` 通过；同批文件行尾空白扫描无命中；源码扫描确认 Perfect / Jackpot camera shake 参数、`suppressCameraShake` 写入和 `EffectSystem:PlayStreakMilestone()` 跳过观察者 camera shake 已接入。`stylua --check` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play，Perfect / Jackpot 本人体感和双客户端观察者低噪音仍需 Studio Team Test 确认。

### 2026-06-03 P3 table reaction broadcast

- Outcome: 执行 P3 桌面轻互动 / cheer 小步，不新增 UI、不新增资产、不改手机端布局。`EffectSystem` 现在把已有本地 `TableTop` 点击反馈扩展为弱社交信号：本人点击桌面仍立即播放 `tableKnock` 和本地 ripple，同时调用 `RequestTableReaction()`；服务端确认玩家仍在座位上并按 `TableReactionCooldown = 0.55` 限频后，用 unreliable `AllClients:PlayTableReaction()` 广播给其他客户端，其他客户端在该座位硬币落点附近播放低噪音 ripple / SFX。
- Decisions: 广播只带服务端确认过的 `seatId` 和 `actorUserId`，不信任客户端点击坐标；origin 客户端跳过广播回放，避免本人看到 / 听到双份 table knock。不新增聊天、emote 面板、持久字段或 runtime-built UI。
- Validation: `git diff --check -- docs/PROJECT_LOGIC.md docs/TASK_STATE.md src/ReplicatedStorage/Systems/EffectSystem/init.lua src/ReplicatedStorage/Systems/EffectSystem/Presets.lua` 通过；同批文件行尾空白扫描无命中；源码扫描确认 `RequestTableReaction / PlayTableReaction / TableReactionCooldown / tableReactionCooldowns / PlayerRemoving` 已接入，且广播 payload 带 `unreliable = true`。`stylua --check` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play，双客户端 table reaction 观感仍需 Studio Team Test 确认。

### 2026-06-03 P3 gamepass analytics polish

- Outcome: 执行 P3 基础 gamepass 收敛小步，不改 UI、不新增商品、不改价格或效果。`EcoSystem` 的 Developer Product / GamePass 购买链路清掉调试 `print`，receipt 失败上下文改成单条 `warn`；gamepass 通过购买 prompt 或进服 ownership sync 发放后统一记录 `coinflip_gamepass_granted`。
- Decisions: 继续复用 `EcoPresets.GamePasses` 的 `vip / winsX2 / luckyCharm / quickFlip` 和现有 `GamePassEffects`。埋点 `source` 区分 `purchase` 与 `ownershipSync`，自定义字段记录 gamepass key、来源和展示名，value 使用配置 price。
- Validation: `git diff --check -- docs/PROJECT_LOGIC.md docs/TASK_STATE.md src/ReplicatedStorage/Systems/AnalyticsSystem/init.lua src/ReplicatedStorage/Systems/EcoSystem/init.lua` 通过；同批文件行尾空白扫描无命中；源码扫描确认 `LogGamePassGranted / coinflip_gamepass_granted / source = "purchase" / source = "ownershipSync"` 已接入，且 `EcoSystem/init.lua` 与 `AnalyticsSystem/init.lua` 无剩余 `print()`。`stylua --check` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play，Robux prompt 和 AnalyticsService 实际写入仍需 Studio / Roblox 后台验证。

### 2026-06-03 P3 core lifecycle analytics

- Outcome: 执行 P3 首发运营里的核心埋点小步，不改手机 UI、不新增持久字段。`AnalyticsSystem` 现在通过系统生命周期维护当服内存 session：真实玩家进服记录 `coinflip_session_start`，离服记录 `coinflip_session_end`；每次真实玩家 `coinflip_flip_resolved` 后累积当服 flip count，首次 Flip 额外记录 `coinflip_first_flip_latency`，达到 `10 / 25 / 50 / 100 / 250 / 500` 次 Flip 时记录 `coinflip_flip_count_milestone`。
- Decisions: 生命周期指标放在已注册的 `AnalyticsSystem` 内部，不新建 analytics wrapper，不接旧注释态 `analytics.server.lua`，fake player 不参与 session / milestone 统计。自定义字段继续保持低基数：时长 band、account age band、round outcome、装备 Coin id、当服 milestone。
- Validation: `git diff --check -- docs/PROJECT_LOGIC.md docs/TASK_STATE.md src/ReplicatedStorage/Systems/AnalyticsSystem/init.lua` 通过；同批文件行尾空白扫描无命中；源码扫描确认 `coinflip_session_start / coinflip_session_end / coinflip_first_flip_latency / coinflip_flip_count_milestone`、`FlipCountMilestones`、`_LogFlipProgress()`、`PlayerRemoving()` 清理和 `whiteList` 保护已接入。`stylua --check` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play，AnalyticsService 实际写入仍需 Studio / Roblox 后台验证。

### 2026-06-03 Lightweight daily goals

- Outcome: 执行 `P2` 首发成长补强的每日目标小步，不改手机 UI、不启用旧 `DailySystem / QuestSystem`。新增 `GameConfig.FlipACoin.DailyGoals` 三个目标：`Flip 10 times` 奖励 `$30`、`Flip 15 Heads` 奖励 `$60`、`Reach a 3 streak` 奖励 `$75`。真实玩家 Flip 结算后自动推进 `dailyClaim.flipACoinGoals`，按服务器日重置，达成即通过 `EcoSystem:AddResource()` 发 Cash，并用已有 `GuiSystem:SetNotification()` 做轻提示；fake player 不推进每日目标。
- Decisions: 本轮只做服务端权威追踪、自动领奖、客户端 `dailyClaim` 镜像同步和 Analytics，不新增 Daily 面板 / HUD 组件 / runtime-built UI。每日目标复用已有 `dailyClaim` 持久字段，因此不新增 DataKey / DefaultData schema；以后如果要展示进度面板，应走 Studio-authored prefab。
- Validation: `git diff --check -- docs/PROJECT_LOGIC.md docs/TASK_STATE.md src/ReplicatedStorage/configs/GameConfig.lua src/ReplicatedStorage/Systems/CoinFlipSystem/Presets.lua src/ReplicatedStorage/Systems/CoinFlipSystem/init.lua src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua src/ReplicatedStorage/Systems/AnalyticsSystem/init.lua` 通过；同批文件行尾空白扫描无命中；源码扫描确认 `DailyGoals / flipACoinGoals / ApplyDailyGoalProgress / LogDailyGoalCompleted / coinflip_daily_goal_completed` 已接入，且 fake player 分支不推进每日目标。Node sanity 模拟确认 `flip10 / heads15 / streak3` 都能达到目标并写入 `claimed`。`stylua --check` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play，目标重置、自动领奖和通知体感仍需 Studio 验证。

### 2026-06-03 Profile XP growth layer

- Outcome: 跳过手机端 UI 后执行 `P2` 首发成长补强中的 Profile XP 小步。复用已有持久字段 `level / exp` 和 `PlayerSystem:AddExp()`，真实玩家每次 Flip 后按 `GameConfig.FlipACoin.ProfileXp` 结算经验：基础 `2` XP、每个 Heads `+2`、round success `+3`、Perfect `+4`、Jackpot `+6`，单轮上限 `24`。`CoinFlipSystem` 在服务端权威结算和 Cash / runData 写入后发放 XP；fake player 不吃 XP。`AnalyticsSystem` 新增 `coinflip_profile_xp` 埋点。
- Decisions: 本轮不新增 HUD / mobile UI / growth panel prefab，只做持久化成长底层和客户端 `ClientData.level / exp` 同步。顺手修正 `PlayerSystem:AddExp()`：满级不再越界到表外等级，客户端没有 XP UI 时不再调用缺失函数报错。
- Validation: `git diff --check -- docs/PROJECT_LOGIC.md docs/TASK_STATE.md src/ReplicatedStorage/configs/GameConfig.lua src/ReplicatedStorage/Systems/CoinFlipSystem/Presets.lua src/ReplicatedStorage/Systems/CoinFlipSystem/init.lua src/ReplicatedStorage/Systems/PlayerSystem/init.lua src/ReplicatedStorage/Systems/PlayerSystem/ui.lua src/ReplicatedStorage/Systems/AnalyticsSystem/init.lua src/ServerStorage/classes/PlayerServerClass.lua` 通过；同批文件行尾空白扫描无命中；源码检查覆盖 `GameConfig.FlipACoin.ProfileXp`、`Presets.GetProfileXpReward()`、真实玩家 Flip 后 `PlayerSystem:AddExp()` 调用、fake player 路径无 XP、`LogProfileXp()` 埋点、`PlayerUi.AddExp()` 空实现和 `/exp` dev command 改走 `PlayerSystem`。Node 数值 sanity 覆盖 `1` 到 `5` 枚 coin 的 `0H..5H` XP 奖励，确认 Jackpot capped at `24`。`stylua --check` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；本机未发现 `selene` 命令；未执行 Studio Play，XP 运行态同步和 level-up 体感仍需 Studio 验证。

### 2026-06-03 Multi-coin Phase 5 Bad Luck Pity

- Outcome: 按 `docs/MULTI_COIN_FLIP_PLAN.md` 执行 Phase 5 的第一小步，只做 Bad Luck Pity，不做 Edge Stand / Table Jackpot / Lucky Coin，也不改手机 UI。`GameConfig.FlipACoin.BadLuckPity` 新增 `FailureThreshold = 3`、`ChanceBonusStep = 0.05`、`MaxChanceBonus = 0.18`、`MaxHeadsChance = 0.55`。真实玩家服务端内存状态新增 `badLuckPityFailures`，成功轮清零、失败轮递增；连续失败达到阈值后，下一轮 roll 获得隐藏正面率补偿。`Presets.GetRollHeadsChance()` 支持独立隐藏概率上限，保留首局保护 `45%` 上限，同时让 Bad Luck Pity 使用 `55%` 上限。Analytics compact outcome 末尾追加 `pity / normal`。
- Decisions: Bad Luck Pity 不写持久化、不显示 UI、不直接发奖励、不降低成功阈值，只影响服务端权威 roll 的隐藏正面率；fake player 暂不吃 pity，避免假玩家表现过度稳定。该补偿不会改变 round streak 语义，仍由 `headsCount >= successThreshold` 决定成功或重置。
- Validation: `git diff --check -- docs/PROJECT_LOGIC.md docs/TASK_STATE.md docs/MULTI_COIN_FLIP_PLAN.md src/ReplicatedStorage/configs/GameConfig.lua src/ReplicatedStorage/Systems/AnnouncementSystem/Presets.lua src/ReplicatedStorage/Systems/AnnouncementSystem/init.lua src/ReplicatedStorage/Systems/EffectSystem/Presets.lua src/ReplicatedStorage/Systems/CoinFlipSystem/Presets.lua src/ReplicatedStorage/Systems/CoinFlipSystem/init.lua src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua src/ReplicatedStorage/Systems/AnalyticsSystem/init.lua` 通过；同批文件行尾空白扫描无命中；源码扫描确认 `BadLuckPity / badLuckPityFailures / GetBadLuckPityBonus / pityActive / pityFailureStreak` 已接入；数值 sanity 确认连续失败 `0/1/2/3/4/5/6+` 对应 bonus 为 `0 / 0 / 0 / 0.05 / 0.10 / 0.15 / 0.18`。`stylua --check` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play，pity 体感仍需 Studio 验证。

### 2026-06-03 Multi-coin combo celebration Phase 4

- Outcome: 按 `docs/MULTI_COIN_FLIP_PLAN.md` 执行 Phase 4，不混入 Phase 5 特殊事件，也不改手机端 UI。`CoinFlipSystem/Presets.lua` 的 round outcome 新增 `comboKey / comboTier`，`CoinFlipSystem/init.lua` 同步到真实玩家、假玩家和 observed payload，并额外生成 `comboMilestone`。Triple / Four Heads / Perfect / Jackpot 复用现有 `streak3 / streak5 / bestStreak` VFX 路径，Jackpot 才 `announce = true` 发全桌低噪音通知；Jackpot / Perfect 在 HUD `ResultLabel` 上有更明确的一行结果文案。`AnalyticsSystem` 的 compact round outcome 末尾追加 combo key，例如 `c5_h5_success_s5_9_jackpot`。
- Decisions: `bestStreak` 仍是最高优先级；Jackpot / Perfect 这类高阶 combo 可以盖过普通 streak milestone，但不会盖过 best-streak。观察者播放 combo milestone 时 clone payload 并 `suppressSfx = true`，避免他人高价值结果播放自己的奖励 SFX。不新增 Studio-authored `CoinResultRow` 或新 VFX 资产，缺资源时继续走 `EffectSystem` fallback pulse / highlight。
- Validation: `git diff --check -- docs/PROJECT_LOGIC.md docs/TASK_STATE.md docs/MULTI_COIN_FLIP_PLAN.md src/ReplicatedStorage/Systems/AnnouncementSystem/Presets.lua src/ReplicatedStorage/Systems/AnnouncementSystem/init.lua src/ReplicatedStorage/Systems/EffectSystem/Presets.lua src/ReplicatedStorage/Systems/CoinFlipSystem/Presets.lua src/ReplicatedStorage/Systems/CoinFlipSystem/init.lua src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua src/ReplicatedStorage/Systems/AnalyticsSystem/init.lua` 通过；同批文件行尾空白扫描无命中；源码扫描确认 `comboKey / comboTier / comboMilestone / BuildComboMilestonePayload / ComboEffects` 和 Analytics combo key 已写入。`stylua --check` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play，Phase 4 观感和双客户端听感仍需 Studio 验证。

### 2026-06-03 Same-table weak social feedback polish

- Outcome: 跳过手机端 UI 任务，改做同桌弱社交反馈收敛。`AnnouncementSystem` 新增 `MinBestStreakAnnouncement = 5`，低 streak 新纪录不再生成全桌 best-streak 大通知，也避免截图中 `round streak: 2` 这类早期噪音；`BestStreakEffect` 不再触发 camera shake。`EffectSystem/Presets.lua` 稍微强化他人 Heads / Tails 落地 pulse、Heads streak ring 半径 / 持续时间，并把 observed Highlight 阈值从 `5` 降到 `4`，让反馈更多停留在桌面而不是顶部通知。
- Decisions: 不新增观战面板、不改手机端 UI、不增加新的 runtime UI；保留 milestone 通知，但把低 streak best-streak 降噪。桌面信号继续走已有 `ObservedFlip -> EffectSystem:PlayCoinFlipVisual()` 和 `PlayStreakMilestone()` 路径。
- Validation: `git diff --check -- src/ReplicatedStorage/Systems/AnnouncementSystem/Presets.lua src/ReplicatedStorage/Systems/AnnouncementSystem/init.lua src/ReplicatedStorage/Systems/EffectSystem/Presets.lua docs/PROJECT_LOGIC.md docs/TASK_STATE.md` 通过；同批文件行尾空白扫描无命中；源码扫描确认 `MinBestStreakAnnouncement = 5`、`args.streak < Presets.MinBestStreakAnnouncement`、`ObservedHighlightMinimum = 4` 和更新后的 observed pulse 参数已写入。`stylua --check` 仍因 Aftman shim 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play，双客户端观感仍需 Studio 验证。

### 2026-06-03 Rebirth options and fake multi-coin support

- Outcome: Rebirth 面板恢复 `Coin Spread / Chain Start / Quick Start / Lucky Start` 四个升级选项；服务端 `UpgradeOrder`、状态同步和购买绑定重新覆盖四张 Studio-authored perk card。升级卡 chip 和按钮都会标注当前消耗的 Rebirth Points；reset preview 文案改为 run stats 重置到 Rebirth upgrade baselines。FakePlayer 创建时会随机获得 `1` 到 `3` 级 `coinCountLevel`，因此 fake flip 也会通过现有 `coinCount / coinResults` observed payload 显示多 Coin 扇形表现。
- Decisions: 现有 Rebirth UI 刚好有 4 张 Studio-authored perk card，本轮不改成 ScrollingFrame。`Coin Spread` 继续复用原持久 key `polishedStart`，其他旧 key `chainStart / quickStart / luckyStart` 恢复为 Combo / Speed / Luck baseline 升级；重生次数本身仍不自动给 Luck。
- Validation: `git diff --check -- src/ReplicatedStorage/Systems/RebirthSystem/Presets.lua src/ReplicatedStorage/Systems/RebirthSystem/ui.lua src/ReplicatedStorage/Systems/FakePlayerSystem/Presets.lua src/ReplicatedStorage/Systems/FakePlayerSystem/init.lua docs/PROJECT_LOGIC.md docs/TASK_STATE.md` 通过；源码扫描确认 `UpgradeOrder` 包含四个升级、Rebirth UI 显示 `Cost {entry.cost} RP` / `Upgrade ({entry.cost} RP)`、FakePlayer 写入随机 `coinCountLevel`。行尾空白扫描仍命中 `RebirthSystem/Presets.lua` 旧 legacy tier 表既有空白，不是本次 diff 新增。未执行 Studio Play，Rebirth 面板文字是否挤压和 fake 多 Coin 观感仍需 Studio 里确认。

### 2026-06-03 Multi-coin persistence and rebirth stat reset

- Outcome: 多 Coin 结算后不再按固定秒数清理，也不会被普通座位刷新重摆成单 Coin；多枚结果会留在桌面上，直到该座位下一次 Flip、隐藏座位或换装清理。单 Coin / 多 Coin 下一轮开始前会先清理上一轮 transient coin，并恢复主持久 coin 的临时 scale。Rebirth 新 run baseline 收紧为只应用当前主线启用的 `Coin Spread -> coinCountLevel`，`Coin Spread` 不再顺带给起始 Value，重生次数本身不再自动给 Luck；Rebirth UI 隐藏旧 `chainStart / quickStart / luckyStart` 卡片，避免玩家购买不参与当前 reset 规则的 stats 起步卡。
- Decisions: 当前 Rebirth 主线只启用 `Coin Spread`。Value / Combo / Speed / Luck 属于本局 stats，`RequestRebirth()` 后回到 `0`；多 Coin 数量作为 Rebirth 永久能力保留在 `coinCountLevel`。
- Validation: `git diff --check -- src/ReplicatedStorage/Systems/EffectSystem/init.lua src/ReplicatedStorage/Systems/EffectSystem/Presets.lua src/ReplicatedStorage/Systems/RebirthSystem/Presets.lua src/ReplicatedStorage/Systems/RebirthSystem/ui.lua docs/PROJECT_LOGIC.md docs/MULTI_COIN_FLIP_PLAN.md docs/TASK_STATE.md` 通过；源码扫描确认 `MultiCoinResultHoldDuration` 固定秒数清理已移除，`EffectSystem` 只在下一次 Flip / hide / coin replace 清理 transient coins，`RebirthSystem` 当前 `UpgradeOrder` 只包含 `polishedStart` 且 `Coin Spread` 只写 `coinCountLevel`。`stylua --check` 仍因 Aftman 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行。未执行 Studio Play，多 Coin 桌面保留和 Rebirth 面板视觉仍需用户在 Studio 里确认。

### 2026-06-03 Multi-coin spread readability

- Outcome: 多 coin fan visual 更分散，结算结果更容易看清。`EffectSystem/Presets.lua` 将 `MultiCoinFanAngleStep` 从 `8°` 提高到 `13°`，`MultiCoinFanMaxAngle` 从 `18°` 提高到 `30°`，`MultiCoinResultHoldDuration` 从 `1.15s` 提高到 `1.8s`；新增 `MultiCoinScaleByCount`，3/4/5 枚 coin 分别临时缩放到 `0.94 / 0.90 / 0.86`。`EffectSystem/init.lua` 在多 coin 状态创建前应用临时 scale，并在清理临时 coin、隐藏座位或下一轮开始时恢复主持久 coin 的原始 scale / size。
- Validation: `git diff --check -- src/ReplicatedStorage/Systems/EffectSystem/init.lua src/ReplicatedStorage/Systems/EffectSystem/Presets.lua docs/PROJECT_LOGIC.md docs/MULTI_COIN_FLIP_PLAN.md docs/TASK_STATE.md` 通过；源码扫描确认 `MultiCoinFanAngleStep / MultiCoinFanMaxAngle / MultiCoinScaleByCount / MultiCoinResultHoldDuration` 和临时 scale restore helper 已接入。`stylua --check` 仍因 Aftman 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行。未执行 Studio Play，扇形角度、scale 观感和每枚结果可读性仍需在 Studio 里确认。

### 2026-06-02 Rebirth multi-coin unlock and fan visual

- Outcome: 恢复 guide `ripple` clone 的循环放缩效果，并保留上一轮 locked-parent 修复：`Elements.ripple` 继续作为模板，guide 高亮使用独立 clone / tween / token 清理；鼠标 ripple clone 也会重置初始尺寸。多金币数量从本局 `Value` 迁移到 Rebirth 永久升级 `Coin Spread`，新增 `runData.coinCountLevel` 默认值并由 `RebirthPresets.BuildFlipACoinRunBaseline()` 写入；`CoinFlipSystem/Presets.GetCoinCount()` 改为读取 `CoinCountByLevel`，`Value` 只影响 Heads Cash 倍率。`CoinFlipSystem/ui.lua` 把 `coinCount / coinResults` 传给 `EffectSystem`，并在 `Coin Spread` 提高 coin 数量时提示 `Coin Spread unlocked N coins per flip.`。`EffectSystem` 在 `coinCount > 1` 时克隆短生命周期 coin / shadow / pulse，以玩家到中心落点的线段为中轴生成扇形落点，落地后短暂保留并在下一轮、隐藏座位或换装路径清理。
- Decisions: 不新增 runtime-built Rebirth card；现有 Rebirth 面板只有 4 张 Studio-authored perk card，因此复用持久 key `polishedStart`，展示名改为 `Coin Spread`，同时提供 coin 数量 tier 和起始 Value 收益。
- Validation: `git diff --check -- src/StarterGui/Main/uiController.lua src/ReplicatedStorage/configs/GameConfig.lua src/ReplicatedStorage/configs/DefaultData.lua src/ReplicatedStorage/Systems/CoinFlipSystem/Presets.lua src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua src/ReplicatedStorage/Systems/RebirthSystem/Presets.lua src/ReplicatedStorage/Systems/EffectSystem/init.lua src/ReplicatedStorage/Systems/EffectSystem/Presets.lua docs/PROJECT_LOGIC.md docs/MULTI_COIN_FLIP_PLAN.md docs/TASK_STATE.md` 通过；旧符号扫描确认当前源和项目文档不再引用 `CoinCountByValueLevel` / `Value unlocked`。全文件行尾空白扫描命中 `RebirthSystem/Presets.lua` 旧 legacy tier 表的既有空白，不是本次 diff 新增。`stylua --check` 仍因 Aftman 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play，未命名 Studio 实例当前无可执行 place，另一个打开的是其他项目。

### 2026-06-02 Guide ripple destroyed instance bug

- Outcome: 修复 Rose Coin 装备引导切换时报 `The Parent property of ripple is locked` 的客户端错误。根因是 `uiController.SetGuideButton()` 把全局 `Elements.ripple` 直接 parent 到当前 guide button；Inventory item card / EquipButton 刷新销毁时，作为子节点的 ripple 也被销毁，后续 `SetGuideButton(nil)` 再尝试 `ripple.Parent = Elements` 就会触发 locked parent。现在 `Elements.ripple` 保持为模板，guide 高亮使用短生命周期 `guideRipple = rippleTemplate:Clone()`，清理时销毁 clone；如果旧 guide frame 已经被销毁，也不再尝试恢复它的 ZIndex。
- Validation: `git diff --check -- src/StarterGui/Main/uiController.lua docs/TASK_STATE.md` 通过；同批文件行尾空白扫描无命中；源码扫描确认 `SetGuideButton()` 不再执行 `ripple.Parent = Elements`，guide ripple 改为 clone / destroy。`stylua --check` 仍因 Aftman 未在仓库或用户 `aftman.toml` 注册 stylua 无法运行；未执行 Studio Play，Rose Coin 装备引导需在 Studio 里复测。

### 2026-06-02 Multi-coin Phase 2 HUD result copy

- Outcome: 按 `docs/MULTI_COIN_FLIP_PLAN.md` Phase 2 完成客户端 HUD 多金币结果文案。`CoinFlipSystem/ui.lua` 新增 `buildResultCopy()`，单金币仍显示 `Heads! +$ ...` / `Tails! +$ ...`，多金币使用 Phase 1 payload 显示 `headsCount/coinCount`、combo 名、streak reset 和奖励，例如 `2/3 Heads! Pair +$ ...`、`1/3 Heads. Streak reset. +$ ...`。`Value` 升级跨过 coin-count 阈值时会用现有 `ResultLabel` 提示 `Value unlocked N coins per flip.`；`Streak` stat 和 `Combo` upgrade tip 已改为 round streak 语义。未新增 Studio UI prefab，`CoinResultRow` 和多枚世界硬币表现仍留给后续。
- Validation: `git diff --check -- src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua docs/PROJECT_LOGIC.md docs/MULTI_COIN_FLIP_PLAN.md docs/TASK_STATE.md` 通过；同批文件行尾空白扫描无命中；源码扫描确认 `buildResultCopy()`、`Value unlocked`、round streak tips 和 docs 状态已写入；本地文案逻辑 sanity 覆盖 `1/1`、`0/1`、`2/3 Pair`、`3/3 Perfect Triple`、`1/3 reset`、`0/3 reset`，输出符合计划示例。`stylua --check` 无法运行，因为 Aftman 管理的 stylua 未在仓库或用户 `aftman.toml` 注册；按仓库规则未运行 `rojo build`，未执行 Studio Play。

### 2026-06-02 Multi-coin Phase 1 server settlement MVP

- Outcome: 按 `docs/MULTI_COIN_FLIP_PLAN.md` Phase 1 完成服务端多金币 round 结算 MVP。`GameConfig.FlipACoin` 新增 `CoinCountByValueLevel`、`SuccessThresholdByCoinCount`、`ComboMultiplierByHeadsCount` 和 `ComboNamesByHeadsCount`；`CoinFlipSystem/Presets.lua` 新增 `BuildRoundOutcome()` / `GetRoundReward()` 等 round helper；`CoinFlipSystem:init.lua` 的 actor 结算改为每轮 roll 多枚 coin，`currentStreak` 改成 round streak，`headsThisRun / lifetimeHeads` 按本轮 `headsCount` 累加，payload 保持旧 `result = Heads/Tails` 兼容并额外带 `coinResults / headsCount / roundSuccess / successThreshold / perfect / comboName / comboMultiplier`。`AnnouncementSystem` streak 文案改为 successful flips；`AnalyticsSystem` 用低基数字段记录 compact round outcome。第一版仍只播放一枚世界硬币，HUD 多金币文案留给 Phase 2。
- Validation: `git diff --check -- src/ReplicatedStorage/configs/GameConfig.lua src/ReplicatedStorage/Systems/CoinFlipSystem/Presets.lua src/ReplicatedStorage/Systems/CoinFlipSystem/init.lua src/ReplicatedStorage/Systems/AnnouncementSystem/Presets.lua src/ReplicatedStorage/Systems/AnalyticsSystem/init.lua docs/PROJECT_LOGIC.md docs/MULTI_COIN_FLIP_PLAN.md docs/TASK_STATE.md` 通过；同批文件行尾空白扫描无命中；关键字段扫描确认 payload / docs 已同步。本地公式 sanity 覆盖 Value `0 / 3 / 7 / 18`：Value 3 解锁 `2` 枚、Value 7 解锁 `3` 枚，`3` 枚时 `1H` 给基础奖励但 reset、`2H` 成功延续 round streak。`stylua --check` 无法运行，因为 Aftman 管理的 stylua 未在仓库或用户 `aftman.toml` 注册；按仓库规则未运行 `rojo build`，未执行 Studio Play。

### 2026-06-02 Multi-coin Phase 0 feedback tuning

- Outcome: 按 `docs/MULTI_COIN_FLIP_PLAN.md` Phase 0 增强早期 Flip 正反馈。`GameConfig.FlipACoin` 调整为 `BaseHeadsChance = 0.30`、`BaseReward = 10`、`BaseTailsReward = 2`、`ValueGrowth = 1.28`、`ComboBaseStep = 0.25`、`ComboStepPerLevel = 0.06`。本轮保持 Rebirth 门槛不变，避免把奖励反馈和重生节奏调整混在一起；`PROJECT_LOGIC.md` 和多金币计划文档已同步。
- Validation: `git diff --check -- src/ReplicatedStorage/configs/GameConfig.lua docs/PROJECT_LOGIC.md docs/MULTI_COIN_FLIP_PLAN.md docs/TASK_STATE.md` 通过；配置扫描确认新数值已写入；本地公式 sanity 显示初始每 Flip 期望从约 `2.38` 提高到约 `4.4`，新档全 Tails 时 `2` 次 Flip 可买首个 Value。按仓库规则未运行 `rojo build`；未执行 Studio Play。

### 2026-06-02 Markdown archive cleanup

- Outcome: 新增 `docs/archive/README.md` 和 `docs/archive/TASK_STATE_DONE_2026-05_TO_2026-06-01.md`，把 2026-06-01 及以前的完成记录从 live task state 压缩归档。`docs/TASK_STATE.md` 从长历史日志压缩为当前基线、决策、follow-up、backlog 和 2026-06-02 最近完成项；`README.md` 与 `docs/BOOTSTRAP.md` 补充 archive 入口。
- Validation: `git diff --check -- README.md docs/BOOTSTRAP.md docs/TASK_STATE.md` 通过；`rg -n "[ \t]+$" README.md docs/BOOTSTRAP.md docs/TASK_STATE.md docs/archive/README.md docs/archive/TASK_STATE_DONE_2026-05_TO_2026-06-01.md docs/MULTI_COIN_FLIP_PLAN.md` 无行尾空白命中。未改玩法代码，未执行 Studio Play。

### 2026-06-02 Multi-coin Flip plan doc

- Outcome: 新增 `docs/MULTI_COIN_FLIP_PLAN.md`，把多金币 Flip 拆成正反馈调参、服务端多金币结算、HUD 文案、世界表现、组合奖励和特殊事件等阶段。计划明确采用按轮次计算的 `Round Streak`，第一版从 `Value` 等级派生 `coinCount`，保留一键 `FLIP` 主循环且不把未来方案写入当前项目事实。
- Validation: `git diff --check -- docs/TASK_STATE.md` 通过；`rg -n "[ \t]+$" docs/MULTI_COIN_FLIP_PLAN.md docs/TASK_STATE.md` 无行尾空白命中。未改玩法代码，未执行 Studio Play。

### 2026-06-02 Onboarding v4 first Value upgrade

- Outcome: `CoinFlipSystem/Modules/Onboarding.lua` 已升级到 v4，引导链改为首次 Flip、首次 Value 升级、首次 Rebirth、购买 Coin、装备 Coin。新增 `firstUpgradeDone / firstUpgradeKey` 状态，`BuildState()` 输出固定 `valueLevel` 目标、成本和可购买状态；v3 已完成玩家、已有任意 run upgrade 或已有 rebirth 进度的玩家会自动视为完成首次升级。`BuyUpgrade()` 成功路径会推进 `buyUpgrade`，任意升级购买都可完成该步骤；客户端在 Cash 不足时高亮 `FLIP`，Cash 足够时隐藏 `GuideActionButton` 并高亮实际 `ValueButton`。
- Validation: 源码复核覆盖 `Onboarding.lua` v4 迁移 / live progress、`CoinFlipSystem:BuyUpgrade()` 成功路径和 `CoinFlipSystem/ui.lua` 引导高亮路径。`git diff --check -- src/ReplicatedStorage/Systems/CoinFlipSystem/Modules/Onboarding.lua src/ReplicatedStorage/Systems/CoinFlipSystem/init.lua src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua docs/PROJECT_LOGIC.md docs/TASK_STATE.md` 通过。`stylua --check` 无法运行，因为 Aftman 管理的 stylua 未在仓库或用户 `aftman.toml` 注册；本机未发现 `selene` 命令。未执行 Studio Play；Value 高亮层级、触屏 / 鼠标 / 手柄实际点击仍建议在 Studio 里确认。

### 2026-06-02 Guide zindex / upgrade tips

- Outcome: `CoinFlipSystem/ui.lua` 在引导刷新时显式提高 `GuidePrompt` 和子级 `ZIndex`，避免文字被 guide `MaskFrame` 压住。四个 Flip 属性升级按钮已绑定一行说明 tip：Value / Combo / Speed / Luck 分别说明 Cash、streak payout、flip cooldown 和 Heads chance。`uiController.SetOneLineTip()` 已补充触屏按下、gamepad `SelectionGained / SelectionLost` 显隐和旧 cloned tip 清理，因此鼠标、手指和 gamepad selection 都能显示说明。
- Validation: `git diff --check -- src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua src/StarterGui/Main/uiController.lua docs/PROJECT_LOGIC.md docs/TASK_STATE.md` 通过。`stylua --check` 无法运行，因为 Aftman 管理的 stylua 未在仓库或用户 `aftman.toml` 注册。未执行 Studio Play；gamepad selection / touch tip 仍建议在 Studio 里做一次交互观感确认。

### 2026-06-02 Alpha test data reset / fake head pitch

- Outcome: `GameConfig.isAlphaTest = true` 已加入；`DataManager` 在 alpha 测试阶段优先用 `DefaultData` 深拷贝覆盖载入 profile，确保玩家每次进服都是初始数据，且该路径优先于 Studio `IsDebug` 的 `DebugData`。fake player `ObservedFlip()` 本地看硬币表现保留左右与向下跟随，但把向上 pitch 上限收窄，避免硬币抛高时过度抬头。`PROJECT_LOGIC.md` 已同步 alpha 数据入口与 fake head pitch 口径。
- Validation: `git diff --check -- src/ReplicatedStorage/configs/GameConfig.lua src/ServerStorage/modules/DataManager.lua src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua docs/PROJECT_LOGIC.md docs/TASK_STATE.md` 通过。`stylua --check` 无法运行，因为 Aftman 管理的 stylua 未在仓库或用户 `aftman.toml` 注册；本机未发现 `luau` / `luau-analyze` / `selene`。未执行 Studio Play，fake player 最终观感仍建议在 Studio 单客户端看一眼。

### 2026-06-02 EffectSystem RenderStepped closure fix

- Outcome: 修复 `EffectSystem:PlayCoinFlipVisual()` 中 `RunService.RenderStepped:Connect(function()` 外层闭包缺失 `end)` 的解析错误，避免 `SystemMgr` require `EffectSystem` 失败。
- Validation: `git diff --check -- src/ReplicatedStorage/Systems/EffectSystem/init.lua docs/TASK_STATE.md` 通过；Studio MCP Play 后 `require(game.ReplicatedStorage.Systems.SystemMgr).systems.EffectSystem` 返回 table，控制台未再出现 `Expected ')'` 或 `Requested module experienced an error while loading`。

### 2026-06-02 PC flip input icon visual fix

- Outcome: 修复 PC 键鼠端 `FlipButton.gamepadKeyImg` 以白色大块浮在 `FLIP` 按钮上方的问题。运行时现在会按输入方式给 `gamepadKeyImg` 切换样式：键鼠端显示按钮内部左侧的紧凑 `SPACE` 键帽，手柄端显示 R2 图片，触屏端继续隐藏。Studio 预制同步改为默认隐藏、`RelativeXY`、紧凑 offset 尺寸，并把 `keyboardKeyText` 层级抬到父 ImageLabel 上方。顺手修复上一轮遗留的 `EffectSystem` 多余 `end)` 解析风险。
- Validation: `git diff --check -- src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua src/ReplicatedStorage/Systems/EffectSystem/init.lua docs/PROJECT_LOGIC.md docs/TASK_STATE.md` 通过；Studio MCP 确认 edit-time `gamepadKeyImg.Visible=false`、`Position={0.15,0},{0.5,0}`、`Size={0,54},{0,30}`、`SizeConstraint=RelativeXY`、`keyboardKeyText.ZIndex=3`。Play 模式未出现新增控制台脚本错误；本轮单客户端 Play 没有自动入座，故用运行态强制显隐截图确认键帽位于 `FLIP` 按钮内部且不再遮挡按钮外区域。

### 2026-06-02 Observed flip SFX / initial camera / flip input icon cleanup

- Outcome: 他人和 fake player 的 `ObservedFlip()` 仍播放 `coinToss` / `coinSpin` / `coinLand`，但不再播放本地 `headsWin` / `tailsLose` 或 streak milestone SFX；自己的 flip 仍播放结算和 `cashReward`。`FirstPersonCamera.RequestInitialTableLook()` 现在会等 loading screen 销毁且本地 Humanoid 已坐下后再消费首次桌面朝向请求，并延长初始强制看桌时间，避免 loading 消失后看到旧默认相机方向。`CoinFlipHUD` 不再显示旧 `InputHints` 文本提示，改用 `FlipButton.gamepadKeyImg` 按最后输入方式显示 R2 图片或 Space 键帽兜底，触屏端隐藏；Studio 预制里已补 `gamepadKeyImg.keyboardKeyText`。
- Validation: `git diff --check -- src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua src/ReplicatedStorage/Systems/EffectSystem/init.lua src/StarterPlayer/StarterPlayerScripts/Modules/FirstPersonCamera.lua src/StarterGui/Main/uiClient.client.lua docs/PROJECT_LOGIC.md docs/TASK_STATE.md` 通过；Studio MCP Play 单客户端确认 `InputHints=false`、`gamepadKeyImg=true`、键鼠兜底 `keyboardText=SPACE`、玩家已坐下、相机看向桌面 `lookDot=1.0000` 且 `CameraType=Custom`；控制台未见新增脚本错误，只剩既有 StyleRule `CornerRadius` 警告。`stylua --check` 无法运行，因为 Aftman 未在仓库或用户 `aftman.toml` 注册 stylua；本机未发现 `luau` 命令。多客户端听感仍建议用户在 Studio Team Test 中确认。

## Archived Done History

- 2026-06-01 及以前的完成记录已压缩归档到 `docs/archive/TASK_STATE_DONE_2026-05_TO_2026-06-01.md`。
