# TASK_STATE

最后更新：2026-06-17

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
- Growth panels 保持 Studio-authored 结构但由运行时代码统一套黑底大面板布局；当前游戏具备基础触屏支持，默认移动 / 跳跃控件已关闭，但移动端布局、安全区和实机观感仍需专项收敛。
- `Main.Frames.noUse` 下的 legacy 透明 UI 保持不可交互，避免抢 Rebirth / Shop / Inventory hit test。
- 复杂客户端视觉、多客户端、移动端设备或 Studio-only 观感验证交由用户手动确认；Codex 只记录可自动覆盖的源码 / 单客户端 sanity 和用户回传结果。
- 2026-06-01 及以前的详细完成日志已移入 `docs/archive/TASK_STATE_DONE_2026-05_TO_2026-06-01.md`；live task state 只保留最近完成项和当前交接信息。

## Known Follow-Ups

- 上线前处理审计项：移除生产 profile / leaderboard / animation debug 输出；给 `RewardedAds.DevProductId` 填独立 Developer Product id；确认是否补回 `Workspace.RankingList` 或关闭排行榜启动 warn；Creator Dashboard 隐藏旧项目商品入口。
- Studio / device QA：按 `docs/ROBLOX_PLATFORM_IMPROVEMENT.md` 覆盖手机 portrait / landscape、平板、桌面键鼠、手柄和双客户端同桌，确认 HUD 响应式布局、安全区、growth panels、Topbar 入口与装扮刷新。
- Studio Play：填入真实 Developer Product / Game Pass id 后，确认 Boosts 入口能弹出 Robux 购买 prompt；购买 Cash / Rebirth Points / Apex bundle / VIP / 2x Cash / Lucky Charm / Quick Flip 后刷新 HUD、Shop、Inventory、Rebirth 和座位表现，并记录 `coinflip_gamepass_granted`。
- Creator Dashboard：创建 `cashPackSmall / cashPackMedium / cashPackLarge / rebirthShardSmall / rebirthShardLarge / apexLoadoutBundle / paidCash2x10m` 七个付费 Developer Products、一个 Rewarded Ads 专用 Developer Product，以及 `vip / winsX2 / luckyCharm / quickFlip` 四个 Game Pass；把付费 product id 填回 `Products.flipACoin`，把广告奖励 product id 填回 `RewardedAds.DevProductId`。
- Studio Play：新档默认 Cash 为 `9`，入座后看到首次 Flip 引导；首次 Flip 后进入 v4 Value 升级阶段，Cash 不足时继续高亮 `FLIP`，Cash 达到 `12` 后高亮 HUD 内实际 `ValueButton`，点击升级后进入 Rebirth 引导。
- Studio Play：确认 Phase 0 正反馈调参后的首局节奏，重点看首次升级是否更有反馈、首次 Rebirth 是否过快；如果后续 Rebirth 节奏仍明显过快，再单独调整 `RebirthPresets.FlipACoin.Rebirth.MinCashGrowth / CashPerPointGrowth`。
- Studio Play：确认 Rebirth `Coin Spread` 购买后的真实运行体感，重点看多 Coin 立即生效后的世界表现、round streak 是否按成功轮数增减、失败但有 Heads 的奖励是否能接受；源码层已确认购买后 `coinCountLevel` / `coinCount` 会即时同步增长。
- Studio Play 新档：确认第一次 Rebirth 后 `Coin Spread` 首级能在前 `3` 分钟内稳定买到，并且关闭 Rebirth 面板后能看到解锁 banner，下一次多金币 Flip 能看到首秀 banner / `multiCoinReveal`。
- Studio Play：确认 Phase 2 HUD 文案，重点看 `1/1`、`1/3`、`2/3`、`3/3` 等结果是否清楚，`Streak reset` 是否不会和有 Heads 奖励矛盾，移动端是否挤压底部 ResultLabel。
- Studio Play：确认 Phase 3 多金币扇形世界表现，重点看 primary 是否固定为视觉中位币、自己的相机是否跟随 primary coin、强落地 burst 是否只出现在 primary coin、多枚硬币是否仍都有轻落地 pulse、扇形是否以玩家到中心落点为中轴、临时 coin / shadow / pulse 是否在下一轮或座位隐藏后清理。
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

### 2026-06-17 Early multi-coin burst

- Outcome: `Coin Spread` 首级保持 `1 RP`、后续按 `3x` 增长并收束到 `4` 级；Studio/MCP 补了 `UnlockBanner`、`FirstMultiCoinBanner` 和 `multiCoinReveal` 占位 VFX，客户端绑定首次多金币解锁与下一次多金币 Flip 首秀。

### 2026-06-15 Mobile touch controls removal

- Outcome: 移动端默认摇杆 / 跳跃控件改为通过 `StarterPlayer.DevTouchMovementMode = Scriptable`、`GuiService.TouchControlsEnabled = false` 和 PlayerModule controls disable 三层关闭，保留相机转向和玩法 UI 点击。

### 2026-06-15 Multi-coin primary VFX alignment

- Outcome: 多金币 Flip 现在用视觉中位币作为 primary coin，并只让 primary coin 承载强落地 burst 和镜头跟随；非 primary 硬币只保留轻落地反馈。

### 2026-06-15 Launch readiness audit

- Outcome: 完成上线前源码、配置、Studio 实例和单客户端 Play sanity 审计；核心服务端权威路径成立，但上线前仍需处理生产日志、Rewarded Ads id、排行榜缺失提示和旧商品 Dashboard 暴露风险。

### 2026-06-14 Analytics custom event batching

- Outcome: `AnalyticsSystem` custom events now batch by player, event name, and the three custom fields, flush every `15` seconds under a soft `120 + 20 * CCU` per-minute AnalyticsService budget, and force flush on player leave / server close; docs now clarify that Dashboard `Count` is batch count and `Sum value` keeps the original value semantics.

### 2026-06-14 Growth panel preview polish

- Outcome: Studio/MCP 已把 Shop 和 Boosts 右侧 Preview 子元素重新居中并统一标题、图标框、描述和底部状态的纵向层级；运行态 sanity 确认 Shop / Boosts 填充真实文本后不再向左溢出。

### 2026-06-14 Boosts panel split

- Outcome: `Frames.Boosts` is now a standalone Studio-authored growth panel, `EcoSystem/ui.lua` renders Boosts separately from Shop, shared HUD / close / analytics paths recognize Boosts, and legacy catch-all `*Button` frame binding no longer overrides system-owned growth panel buttons.

### 2026-06-13 Docs rules cleanup

- Outcome: 按新 rules 把 live `TASK_STATE.md` 的旧完成记录轮转到 archive，并同步 `PROJECT_LOGIC.md` / archive 索引的文档分工口径。

### 2026-06-13 CentralRules sync

- Outcome: 同步 `../CentralRules` 的共享规则到 `AGENTS.md`、`.cursor/rules` 和 `docs/FRAMEWORK.md`，并把 `.rules-sync.json` 改到新 central 路径。

### 2026-06-05 Coin landing burst and Rebirth cost curve

- Outcome: `coinLandingBurst` 按每枚落地 coin 绑定到对应 visual，Rebirth 门槛和每点 RP 成本改为随 rebirth 次数温和递增。

### 2026-06-05 Non-UI follow-up pass

- Outcome: 源码 sanity 覆盖 XP、daily goals、analytics、Table Bonus、Edge Stand 和高阶 Coin bonus 路径，并修正相关事实文档漂移。

### 2026-06-04 Studio MCP remaining verification pass

- Outcome: 通过 Studio MCP 覆盖 Coin / Desk / Chair 资产、座位 anchor、growth prefab、Shop 配置和单客户端 Play sanity。

### 2026-06-04 Rebirth Coin Spread sync sanity

- Outcome: 源码核对确认购买 `Coin Spread` 后会即时抬升 run baseline 并同步新的 `coinCount` 到客户端。

### 2026-06-04 Coin landing geometry sanity

- Outcome: Studio / 源码 sanity 确认所有 seat 与 coin 组合的落点按 `TableTop` raycast 和 bounds lift 放在桌面上方。

### 2026-06-04 Seat HUD immediate flip guard

- Outcome: `CoinFlipSystem/ui.lua` 在本地 seat id 尚未同步时不再提前发 flip 或锁住本地 HUD 状态。

### 2026-06-04 Desk and Chair runtime loadout sanity

- Outcome: `DecorationSystem` 改为通过 `EcoSystem:GetLoadoutState()` 读取已归一化 Desk / Chair 装备，再刷新座位装饰。

### 2026-06-04 Coin runtime loadout sanity

- Outcome: 源码和 Studio 资产 sanity 确认旧 / 无效 `equippedCoin` 会归一到 `coin1`，并覆盖运行态 flip visual / loadout sync 路径。

## Archived Done History

- 2026-06-02 到 2026-06-04 的较早完成记录已压缩归档到 `docs/archive/TASK_STATE_DONE_2026-06-02_TO_2026-06-04.md`。
- 2026-06-01 及以前的完成记录已压缩归档到 `docs/archive/TASK_STATE_DONE_2026-05_TO_2026-06-01.md`。
