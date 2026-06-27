# TASK_STATE

最后更新：2026-06-20

> 目的：记录当前正在做什么、下一步是什么、关键决策、待验证项与后续想法。项目事实放 `PROJECT_LOGIC.md`，框架规则放 `FRAMEWORK.md`；已完成的历史日志放 `docs/archive/`。

## Active

- 上线版本任务以 `Launch Must-Do Task List` 为准；收集 / 图鉴 / 套装完成奖励已降级为后续内容，不作为首发阻塞项。

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
- 2026-06-18 用户已手动修好手机端 UI；Codex 后续不再主动修改手机端 UI、布局或新增手机端逻辑，除非用户明确要求。
- 2026-06-17 市场评审取舍：资源有限时，首发优先前 `3` 分钟留存、Flip 反馈层级、移动端首屏、合规变现和现有同桌弱社交验证；收集 / 图鉴 / 稀有度 / 套装 / 限时外观进入后续 Backlog。
- 2026-06-17 Rewarded Ads 因 Roblox 新游戏 eligibility / DAU 要求移出首发范围；首发只保留 Robux Developer Product / Game Pass 变现，广告奖励后续满足资格再评估。
- Timing Bonus / Power Flip / Buff Choice 等轻操作补充暂不进入首发必做，除非首轮测试明确暴露“一键 Flip”疲劳问题。
- 2026-06-01 及以前的详细完成日志已移入 `docs/archive/TASK_STATE_DONE_2026-05_TO_2026-06-01.md`；live task state 只保留最近完成项和当前交接信息。

## Launch Must-Do Task List

> Scope：首发版本只做能支撑上线留存、稳定性、移动端、合规变现和已有弱社交体验的事项。`Collection Book`、稀有度图鉴、套装完成奖励、限时外观和大规模新资产不作为首发阻塞；现有 Coin / Desk / Chair 仍需要完成运行态观感验证。

### P0 Release Blockers

- **生产配置与变现闭环**：`Products.flipACoin` 七个 Developer Product 和四个 Game Pass ID 已填入；源码侧已补齐付费发货后的 `gamePasses / loadout / rebirthState` 客户端同步，并加固未知 product / 同服 receipt 重试处理；2026-06-19 用户已手动确认所有 UI、Game Pass 和 Developer Product 购买 / 发货 / 刷新链路，埋点因 Roblox 日活限制当前 Dashboard 暂不可查看。
- **Creator Dashboard 清理**：确认旧项目商品入口已隐藏；Rewarded Ads 不进首发，不再创建或填回广告专用 Developer Product；如果需要排行榜展示，再补回启动前存在的 `Workspace.RankingList` 实例树。
- **前 `3` 分钟首局体验**：源码侧已补齐新档默认 Cash `9`、首次 Flip 引导、v4 Value 升级高亮、Rebirth 不可用阶段的目标金额和 `Coin Spread` 首级价值曝光；Studio Play 单客户端已确认首屏、`Space` 首次 Flip、Value 升级后 Rebirth 目标曝光，2026-06-19 用户已确认 `Space` 可触发 Flip，最终 `2-3` 分钟手感可继续真人复核。
- **核心单客户端 Play QA**：确认 `8` 座自动分配、满员等待、空位释放再分配、重生回座、HUD `Seat --` 到真实座位稳定切换、HUD / `Space` / 手柄 `RT` 统一 Flip、桌面相机两态切换、Rebirth / Shop / Inventory / Boosts 顶栏打开关闭流程；2026-06-20 Studio Play/MCP 确认自动入座、`Space` Flip 结算、死亡重生回座和 `ButtonR2 / ButtonY` InputAction 绑定，手柄 `RT` 真实触发、Rebirth 成功链路和满员等待仍需真手柄 / 稳定多客户端复核。
- **移动端首屏 QA**：`StarterGui.ScreenOrientation = LandscapeSensor`，portrait 不适用于当前首发配置；2026-06-20 Studio Device Simulator 覆盖 iPhone 17 Pro、Samsung Galaxy A06、iPad Pro M5 横屏首屏，HUD / 四个升级入口无越界，Shop / Boosts / Inventory / Rebirth 根面板在 A06 小横屏内可见；Boosts 长文案已收短并复测 `TextNotFit=0`。最终真机触摸手感仍可由用户复核。

### P1 Launch Polish

- **Flip 反馈层级验证与微调**：源码侧已复核 Perfect / Perfect Five / Table Bonus 结果文案、Edge Stand 独立结果色和跳过普通 Tails 失败音、observed flip 低噪音 SFX、milestone 优先级与 announcement notification；仍需 Studio / 真机确认 VFX、SFX 听感强度和 ResultLabel 实际观感。
- **多 Coin 与 Rebirth 体感**：源码 / Edit 态已确认 `Coin Spread` 购买后即时生效、primary coin 中位视觉、下一轮清理路径、unlock banner / first multi-coin banner / `multiCoinReveal` / `CoinVisuals` 资源；真实多 Coin 首秀观感、镜头 / VFX / SFX 强度仍需稳定 Play 或真人复核。
- **Bad Luck / 稀有事件体感**：源码侧已确认 Bad Luck Pity 只加隐藏正面率且受 `MaxHeadsChance` 上限约束，Edge Stand 只对真实玩家失败轮按失败压力低概率触发并保护 round streak；高阶 Coin `coin7` 到 `coin10` 的 Edge Stand bonus、Perfect reward bonus 和 Tails reroll 均只进服务端 outcome / analytics 字段。真实稀有事件观感仍需稳定 Play 或真人复核。
- **同桌弱社交 QA**：源码侧已确认 observed flip 会给同桌其他玩家播放低噪音落地 / streak / highlight，Table Bonus 只由真实玩家 `5/5 Heads` 触发共享奖励和 notification，fake player 不触发共享奖励、Edge Stand 或真实玩家 analytics。双客户端真实观感仍需真人复核。
- **成长与埋点 QA**：源码侧已确认 Profile XP、轻量每日目标、前 `3` 分钟短会话、首次入座 / Flip / Auto / run upgrade / growth panel、`10` 次 Flip、离服、Table Bonus / Edge Stand / Rebirth 等 analytics 入口和批量 flush 路径；Dashboard `Count` / `Sum value` 语义及真实可见性需等 Roblox 日活条件满足后复核。
- **现有装扮资产观感**：源码侧已确认 `coin1` 到 `coin10`、Desk Setup、Chair 的购买 / 装备 notification 与 SFX，装备会刷新 `DecorationSystem` / audience / HUD；`Textures.FlipACoinItems` 覆盖当前 Coin / Desk / Chair 图标。真实座位刷新、落点不沉桌、桌搭 / 椅子不遮挡 Coin 仍需 Studio 稳定 Play 或真人观感复核。

## Resource Needs

- Creator Dashboard 确认项：旧商品入口是否已隐藏；`cashPackSmall / cashPackMedium / cashPackLarge / rebirthShardSmall / rebirthShardLarge / apexLoadoutBundle / paidCash2x10m` 和 `vip / winsX2 / luckyCharm / quickFlip` 的 ID 已在配置中填入并由用户手动验证，首发不再需要 Rewarded Ads 专用 product；analytics 当前受日活限制暂不可见。
- 上线商店资产：Roblox 游戏 icon、缩略图、截图 / 短视频素材和最终标题 / 描述文案；这些不影响源码，但影响发布页转化。
- 手动 QA 资源：至少一轮手机 portrait、手机 landscape、平板、桌面键鼠、手柄和双客户端同桌测试反馈；Codex 自动化不能可靠判断最终移动端观感。
- 可选表现资源：如果当前占位 VFX / SFX 分不清 Heads、Perfect、Edge Stand、Table Bonus，需要补短音效、光效或粒子资源；这属于首发 polish，不要求新增完整图鉴资产。
- 后续收藏资源：更多 Coin / Desk / Chair 美术、稀有度图标、Collection Book UI 和套装展示素材；已明确不作为首发必需。

## Backlog / Ideas

- `Post-launch P1` 收集 / 图鉴 / 稀有度 / 套装完成奖励 / 限时外观：等美术资源更充足后再做，首发只验证现有 Coin / Desk / Chair 购买、装备和展示。
- `Post-launch P1` Rewarded Ads：等游戏满足 Roblox eligibility / DAU 要求后，再评估是否恢复广告奖励入口、独立 reward product 和冷却 / availability / analytics 流程。
- `Post-launch P1` 同桌玩法扩展：Table Streak、Friend Bonus、Cheer / React 和更强全桌事件，先根据首发弱社交数据决定是否投入。
- `Post-launch P2` 场景成长：同一张桌子的 Wooden / Bronze / Silver / Golden / Crystal / Space / Void 等阶段视觉升级，作为可见长期成长目标。
- `Post-launch P2` 轻操作补充：Timing Bonus、Power Flip、Buff Choice 或高 streak 后保留 / 继续挑战的轻选择；必须保持一键 Flip 主循环且避免博彩化文案。
- `Post-launch P2` 完整 Daily 面板：当前只保留轻量每日目标；如果要做完整 Daily UI，使用 Studio-authored prefab，不接回旧 `DailySystem / QuestSystem` 主线。

## Recent Done

### 2026-06-20 Remaining source-checkable launch QA sweep

- Outcome: 复核 P1 剩余可源码确认项：Bad Luck Pity / Edge Stand / Lucky Coin trait 均由服务端 outcome 控制并写入 compact analytics；Edge Stand 和 Table Bonus 不对 fake player 发奖或写真实玩家 analytics；observed flip 只给同桌其他玩家低噪音反馈；Profile XP、daily goal、first-session funnel、input、growth panel、flip milestone、Rebirth、Table Bonus 和 Edge Stand analytics 入口与批量 flush 路径存在；EcoSystem 购买 / 装备会通知、记录 analytics、同步 loadout，并在装备 Desk / Chair 时刷新 Decoration / audience / HUD。Studio 资产类观感仍因 Play 会话不稳定留真人或稳定会话复核。

### 2026-06-20 CentralRules shared rules sync

- Outcome: Synced managed shared rule files from sibling `../CentralRules` according to this project's `.rules-sync.json` (`AGENTS.md`, `.cursor/rules/*.mdc`, `docs/FRAMEWORK.md`), left project-local task / project-logic docs intact, and confirmed the managed files match CentralRules; `pwsh` is not installed, so verification used direct file comparison.

### 2026-06-20 P1 multi-coin and Rebirth source/resource validation

- Outcome: 复核 `RebirthSystem / CoinFlipSystem / EffectSystem` 链路，确认 `polishedStart` 玩家可见为 `Coin Spread`，升级后会扣 RP、更新 `rebirthTree`、立即把 `runData.coinCountLevel` baseline 应用到本局并通过 `rebirthUpgradePurchased` 同步 HUD；客户端会显示 unlock banner，并把下一次从 1 coin 到多 coin 的 Flip 标记为 first multi-coin 首秀。Edit 态确定性检查确认 `Coin Spread` level `0-4` 映射 `1-5` 枚 coin、成本 `1/3/9/27/81 RP`，`UnlockBanner`、`FirstMultiCoinBanner`、`ReplicatedStorage.Systems.EffectSystem.Assets.multiCoinReveal` 和 `Workspace.CoinFlipTable.CoinVisuals` 均存在。Studio Play 仍被 `Server Kick Message` / Server `Players=0` 中断，运行态多 Coin 首秀观感留稳定会话或真人 QA。

### 2026-06-20 P1 flip feedback source validation follow-up

- Outcome: 源码复核 `CoinFlipSystem / EffectSystem / AnnouncementSystem` 的反馈层级，确认 Perfect / Perfect Five 使用短结果文案，Table Bonus 只追加共享语义，Edge Stand 使用蓝色结果文本且不播放普通 Tails 失败音，observed flip suppress 本地结果音效，announcement 只做 notification 不重复播 VFX/SFX，fake player 不触发 Table Bonus / Edge Stand / 真实玩家 analytics。Studio Play 可见 HUD / CoinFlipTable / CoinVisuals 实例，但会话掉到 Server `Players=0`，未能稳定自动触发 Flip；真实 VFX/SFX 听感、rare event 观感和移动端 ResultLabel 仍留人工 QA。

### 2026-06-20 P0 mobile landscape HUD and Boosts QA

- Outcome: Studio Device Simulator 确认 `ScreenOrientation = LandscapeSensor`，portrait 不适用于当前首发配置；Play 模式覆盖 iPhone 17 Pro `748x361`、Samsung Galaxy A06 `705x338`、iPad Pro M5 `1373x1031` 横屏首屏，`FLIP`、Cash、Streak、Chance/Speed、Auto、引导条和四个升级入口无坐标越界。A06 小横屏打开 Shop / Boosts / Inventory / Rebirth 根面板均在 viewport 内；收短 Boosts 付费商品 / gamepass 文案后，A06 Boosts 面板可见文本 `TextNotFit` 从 `5` 降到 `0`。Studio 设备模拟器已还原默认 viewport；控制台未见新增 runtime error。

### 2026-06-20 P0 core QA source and Studio smoke

- Outcome: 源码复核 `ButtonR2` / `ButtonY` 绑定、等待座位队列、释放 fake 座位、重生与 Rebirth 同步路径；Studio Play 单客户端确认 `profileLoaded`、自动入座 `Seat02`、HUD 可见、`CoinFlipGameplayInputContext` 启用且 `FlipCoin = Space / ButtonR2`、`ToggleAutoFlip = ButtonY`，`Space` 完成一次 `Tails! +$ 4` 结算并保持入座，死亡重生后自动回到 `Seat02`。MCP `ButtonR2` 自动输入未触发结算但源码和 HUD 绑定存在，记录为工具模拟不可判定；Rebirth 成功链路探测被 Studio `Server Kick Message` / Server `Players=0` 中断，保留真人或稳定会话复核。

### 2026-06-19 P0 user QA confirmation

- Outcome: 用户手动确认所有 UI、Game Pass 和 Developer Product 均已验证，`Space` 可以触发 Flip；Roblox analytics / 埋点因日活限制当前 Dashboard 不可查看，后续满足可见条件后再复核，不再作为当前源码阻塞。

### 2026-06-19 P1 multi-coin primary visual alignment follow-up

- Outcome: 修正 `EffectSystem` 多金币 visual 分配，让持久硬币绑定到视觉中位 primary index，确保 3/5 枚多金币时镜头跟随、强落地 burst、streak pulse 与下一轮保留状态都落在中位币；源码确认 `Coin Spread` 购买后会即时应用 `runData.coinCountLevel` baseline 并同步 `rebirthUpgradePurchased` 触发 unlock / first multi-coin UI。Studio Play 单客户端确认自动入座 `Seat02`、HUD / `FLIP` 按钮存在且客户端桥接请求无新增 runtime error；`git diff --check` 通过，`stylua --check` 仍因 Aftman 未声明 stylua 无法运行。真实多金币首秀观感、真机 VFX/SFX 和多客户端仍需手动 QA。

### 2026-06-18 P0 core single-client Play QA sweep

- Outcome: 单客户端 Studio smoke 已复核自动入座、HUD 首屏、`Space` Flip 结算、`Main.Frames.Shop / Boosts / Inventory / Rebirth` 打开关闭时 HUD 隐藏与恢复；客户端确认 `Seat02`、`profileLoaded`、`ClientData.initialized`、Cash `$9` 起始值和一次 `Tails! +$4` 结算均正常，控制台未出现新的 runtime error。`git diff --check` 通过，`stylua --check` 仍因 Aftman 未注册 stylua 无法运行；真实移动端 / 手柄 / 购买 prompt / 多客户端仍留给后续手动 QA。

### 2026-06-18 P0 bridge lifecycle hardening follow-up

- Outcome: `SystemMgr` remote dispatch now preserves nil payload slots while rejecting client-to-server calls for lifecycle methods (`Init / PlayerAdded / PlayerRemoving`); server-to-client `PlayerAdded` startup payloads remain allowed because `PlayerSystem` uses them to initialize `ClientData`. Studio Play smoke confirmed `ClientData.initialized` appears after startup and the previous infinite-yield warning no longer recurs; MCP module-cache proxy probes were inconsistent, so final proxy truth was source-reviewed. `git diff --check` passed; `stylua --check` still cannot run because Aftman has no stylua registration.

### 2026-06-18 P0 remote payload bridge QA

- Outcome: Studio Play 单客户端确认自动入座、HUD 首屏和 `Space` Flip 结算仍可走通，并修复 `SystemMgr` remote 分发依赖 nil 占位时可能截断 payload 的问题；框架文档同步 `SystemMgrRuntime` 与显式 `sender / player / payload` 槽位语义。`git diff --check` 通过，`stylua --check` 仍因 Aftman 未注册 stylua 无法运行；MCP 鼠标点击 ValueButton 不稳定，真实 HUD 点击 / 手柄 RT / 多客户端仍需真人 QA。

### 2026-06-18 P0 core single-client Play QA follow-up

- Outcome: Studio Play 单客户端复核自动入座、HUD 首屏、`Space` Flip 成功 / 失败结算、桌面硬币视觉、相机回到桌面视角，以及 Shop / Boosts / Inventory / Rebirth 打开隐藏 HUD、关闭恢复 HUD；修复 `CoinFlipSystem` 远端入口早于 `Init()` 时 `SystemMgr` 为 nil 的 runtime error，并修复 growth panel 打开后 `Mask` 被隐藏的问题。`git diff --check` 通过，`stylua --check` 仍因 Aftman 未注册 stylua 无法运行；MCP 鼠标 / 手柄模拟未能可靠触发 HUD 点击 / ButtonR2，真实桌面鼠标、手柄 RT、多客户端仍需真人 QA。

### 2026-06-18 P0 monetization purchase chain source QA

- Outcome: 审计 `Products.flipACoin`、`GamePasses`、receipt 发货、gamepass ownership sync、Potion/Buff、客户端 `gamePasses / loadoutState / rebirthState` 刷新和 analytics 链路；修复未知 Developer Product 不再静默 `PurchaseGranted`、发货后 `PurchaseHistory` 写失败时同服重试不重复发货、`BuffSystem:GetLuckyBoost()` 兼容当前 `luckyCharm` gamepass 字段。`git diff --check` 通过，`stylua --check` 仍因 Aftman 未注册 stylua 无法运行；真实 Roblox prompt / receipt / Dashboard analytics 仍需手动 QA。

### 2026-06-18 P1 flip feedback source polish

- Outcome: 源码审计 `CoinFlipSystem`、`EffectSystem`、`AnnouncementSystem` 的结果层级后，收短 Perfect / Perfect Five / Table Bonus ResultLabel 文案，把触发者 Table Bonus 文案改成共享语义，并让 Edge Stand 使用独立蓝色结果反馈且不播放普通 Tails 失败音；`git diff --check` 通过，`stylua --check` 因 Aftman 未注册 stylua 无法运行，VFX / SFX 体感仍需 Studio / 真机 QA。

### 2026-06-18 P0 first-3-minutes Studio Play QA

- Outcome: Studio Play 单客户端确认首屏 Cash `$9`、首次 `Space` Flip 结算、Value `$12` 升级、Rebirth 目标 `Need $231 more... 1 RP buys Coin Spread: +1 coin/flip.` 均能走通；修复 `PlayerSystem:AddExp` 客户端先于 `PlayerAdded` 初始化到达时 `ClientData` 为 nil 的 runtime error，复测控制台未再出现该错误。MCP 鼠标点击命中不稳定，最终鼠标手感仍建议用户真人复核。

### 2026-06-18 P0 first-3-minutes source/state sanity

- Outcome: 核对首局默认 Cash `9`、Value 首级 `$ 12`、Rebirth 门槛 `$ 250`、`Coin Spread` 首级 `1 RP` 与 Onboarding 状态机；Studio 首屏确认 Cash / GuidePrompt / FLIP / Value / Rebirth 目标可见，Play 输入结算链路因会话出现 `Server Kick Message` / 断连日志未能自动判定通过，完整 `2-3` 分钟节奏和真实点击仍需用户手动 QA。

### 2026-06-18 Core single-client Play QA pass

- Outcome: 源码确认 `SystemMgr` 首发注册链、`TableSeatSystem` 自动入座、`CoinFlipSystem` 统一 Flip 入口和 growth panel 绑定；Studio Play 单客户端确认玩家会坐到桌边、HUD / 引导 / TopbarPlus 图标和四个 growth frame 实例存在，控制台未见 Luau runtime error；MCP 对 Topbar 点击、服务端模块 state 和远端结算观察不稳定，`Space` / HUD / 真 Topbar 点击、完整 FlipResolved 和多客户端仍需用户手动 QA。

### 2026-06-18 Mobile HUD profile follow-up

- Outcome: `CoinFlipSystem/ui.lua` 保留触屏 / 窄屏 mobile HUD profile 与安全区计算代码，但运行态仍不启用该分支；用户随后已手动修好手机端 UI，Codex 后续不再主动修改手机端 UI、布局或新增手机端逻辑，除非用户明确要求。

### 2026-06-18 Compliance wording pass

- Outcome: 执行首发合规语义扫描，运行态源码未发现玩家可见 `bet / wager / casino / payout / gambling / stake` 包装；首局引导文案从 `Heads pay Cash` / `Heads pay more` 收紧为 `Heads give Cash` / `earn more from Heads`，并清理项目文档里的 casino 风描述。

### 2026-06-18 Early Rebirth goal exposure

- Outcome: `Onboarding.BuildState()` 现在同步 Rebirth 目标金额和 `Coin Spread` 首级成本 / 名称，HUD 在首次 Value 升级后、Rebirth 尚未可用时继续高亮 `FLIP` 并提示还差多少 Cash 以及首个 `1 RP` 的 `Coin Spread` 价值；同时把首局 / 多金币文案里的 `payout` 改成 Cash reward 语义。

### 2026-06-17 Monetization refresh sync

- Outcome: 源码侧审计 Developer Product / Game Pass 发货刷新链路，并让 `CoinFlipSystem` 全量状态同步携带 `gamePasses`、`EcoSystem.SyncLoadoutState` 写回客户端 `gamePasses`，避免 gamepass 购买 / ownership sync 后 Boosts 面板短暂读旧状态。

### 2026-06-17 Rewarded Ads launch removal

- Outcome: 首发移除 Rewarded Ads 入口、`AdService` 调用、广告奖励 Developer Product 配置、`adCash2x5m` potion 和 `coinflip_rewarded_ad` 埋点；Boosts 面板只保留 Robux products / gamepasses，文档同步为后续满足资格再评估广告。

### 2026-06-17 Monetization ID status correction

- Outcome: 核对 `EcoSystem/Presets.lua` 后确认 `Products.flipACoin` 七个 Developer Product 和四个 Game Pass 均已填入非 `0` ID；后续首发范围已移除 Rewarded Ads，因此剩余变现工作收窄为实际购买链路验证。

### 2026-06-17 Production output cleanup

- Outcome: 清理活跃启动链上的生产 profile dump、排行榜缺失启动 warn / 30 秒等待、排行榜刷新 print、动画 track 销毁 print、玩家实例创建 print 和空动画 ID print；`Workspace.RankingList` 缺失时现在立即安静降级为 no-op。

### 2026-06-17 Launch task list consolidation

- Outcome: 阅读 `docs/GAMEPLAY_MARKET_REVIEW.md` 后把首发上线任务收敛为 P0 / P1 必做清单；收集、图鉴、稀有度、套装和限时外观降为后续 Backlog，并补充首发需要的 Creator Dashboard、商店素材、手动 QA 和可选表现资源清单。

### 2026-06-17 Early multi-coin burst

- Outcome: `Coin Spread` 首级保持 `1 RP`、后续按 `3x` 增长并收束到 `4` 级；Studio/MCP 补了 `UnlockBanner`、`FirstMultiCoinBanner` 和 `multiCoinReveal` 占位 VFX，客户端绑定首次多金币解锁与下一次多金币 Flip 首秀。

### 2026-06-15 Mobile touch controls removal

- Outcome: 移动端默认摇杆 / 跳跃控件改为通过 `StarterPlayer.DevTouchMovementMode = Scriptable`、`GuiService.TouchControlsEnabled = false` 和 PlayerModule controls disable 三层关闭，保留相机转向和玩法 UI 点击。

### 2026-06-15 Multi-coin primary VFX alignment

- Outcome: 多金币 Flip 现在用视觉中位币作为 primary coin，并只让 primary coin 承载强落地 burst 和镜头跟随；非 primary 硬币只保留轻落地反馈。

## Archived Done History

- 2026-06-15 的完成记录已压缩归档到 `docs/archive/TASK_STATE_DONE_2026-06-15.md`。
- 2026-06-14 的完成记录已压缩归档到 `docs/archive/TASK_STATE_DONE_2026-06-14.md`。
- 2026-06-13 的完成记录已压缩归档到 `docs/archive/TASK_STATE_DONE_2026-06-13.md`。
- 2026-06-05 的完成记录已压缩归档到 `docs/archive/TASK_STATE_DONE_2026-06-05.md`。
- 2026-06-02 到 2026-06-04 的较早完成记录已压缩归档到 `docs/archive/TASK_STATE_DONE_2026-06-02_TO_2026-06-04.md`。
- 2026-06-01 及以前的完成记录已压缩归档到 `docs/archive/TASK_STATE_DONE_2026-05_TO_2026-06-01.md`。
