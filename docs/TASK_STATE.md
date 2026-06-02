# TASK_STATE

最后更新：2026-06-03

> 目的：记录当前正在做什么、下一步是什么、关键决策、待验证项与后续想法。项目事实放 `PROJECT_LOGIC.md`，框架规则放 `FRAMEWORK.md`；已完成的历史日志放 `docs/archive/`。

## Active

当前没有进行中的实现任务。

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
- Studio Play：填入真实 Developer Product / Game Pass id 后，确认 Boosts 入口能弹出 Robux 购买 prompt；购买 Cash / Rebirth Points / Apex bundle / VIP / 2x Cash / Lucky Charm / Quick Flip 后刷新 HUD、Shop、Inventory、Rebirth 和座位表现。
- Creator Dashboard：创建 `cashPackSmall / cashPackMedium / cashPackLarge / rebirthShardSmall / rebirthShardLarge / apexLoadoutBundle / paidCash2x10m` 七个付费 Developer Products、一个 Rewarded Ads 专用 Developer Product，以及 `vip / winsX2 / luckyCharm / quickFlip` 四个 Game Pass；把付费 product id 填回 `Products.flipACoin`，把广告奖励 product id 填回 `RewardedAds.DevProductId`。
- Studio Play：新档默认 Cash 为 `9`，入座后看到首次 Flip 引导；首次 Flip 后进入 v4 Value 升级阶段，Cash 不足时继续高亮 `FLIP`，Cash 达到 `12` 后高亮 HUD 内实际 `ValueButton`，点击升级后进入 Rebirth 引导。
- Studio Play：确认 Phase 0 正反馈调参后的首局节奏，重点看首次升级是否更有反馈、首次 Rebirth 是否过快；如果 Rebirth 明显过快，再单独调整 `RebirthPresets.FlipACoin.Rebirth.MinCash`。
- Studio Play：确认 Rebirth `Coin Spread` 购买后 `coinCountLevel` / `coinCount` 是否立即增长，round streak 是否按成功轮数增减，失败但有 Heads 的奖励是否能接受。
- Studio Play：确认 Phase 2 HUD 文案，重点看 `1/1`、`1/3`、`2/3`、`3/3` 等结果是否清楚，`Streak reset` 是否不会和有 Heads 奖励矛盾，移动端是否挤压底部 ResultLabel。
- Studio Play：确认 Phase 3 多金币扇形世界表现，重点看自己的相机是否能看清多枚硬币、扇形是否以玩家到中心落点为中轴、临时 coin / shadow / pulse 是否在下一轮或座位隐藏后清理。
- Studio Play 双客户端：确认他人 Heads / Tails 落地 pulse 更明显、Heads streak ring 按 streak 扩大、高 streak / milestone 有短 Highlight；`streak1` / `streak2` 资产缺失时 fallback pulse 不阻塞落地回调。
- Studio Play：确认 `coin1` through `coin10` 资产能按装备显示，新档默认 `Copper R Coin`，旧 Coin id 存档能 reconcile 到 `coin1`。
- Studio Play：确认启动后 HUD 从 `Seat --` 切到分配座位并保持稳定，立刻点击 `FLIP` 不会被客户端旧 seat state 错拦。
- Studio Play：确认不同 Coin 自己/他人 flip 视觉正常，落点在桌面上方，不沉入桌面。
- Studio Play：确认 Desk Setup 购买 / 装备后按座位刷新，模型坐在桌面上，离座 / 离服能清理。
- Studio 资产整理：如需永久 source-backed decoration 资产，把 live `Workspace.TableDecoration` 移到 `ReplicatedStorage.Systems.DecorationSystem.Assets.TableDecoration`，并按 `Tall Candle` / `Barrel Stein` / `Balance Scale` / `Quill Pot` / `Cosmic Globe` / `Miner Trophy` / `Crimson Hourglass` / `Amethyst Hourglass` 拆分命名。
- Studio Play：最终看一遍桌面版 Rebirth / Shop / Inventory 视觉比例、tab 状态、打开关闭流程；MCP synthetic click 对这些按钮不可靠。

## Backlog / Ideas

- `P0` 移动端首发剩余收敛：安全区、growth panels、Topbar 入口和真实设备观感 QA。
- `P1` 同桌弱社交补强：他人 flip pulse、streak 小高光、全桌 milestone 轻反馈。
- `P1` 多金币 Flip 后续：Phase 0 正反馈调参、Phase 1 服务端 round 结算、Phase 2 HUD 结果文案、Phase 3 扇形世界表现和 Rebirth `Coin Spread` 迁移已完成；下一步按 `docs/MULTI_COIN_FLIP_PLAN.md` 评估组合奖励细化和特殊事件。
- `P2` 首发成长补强：少量每日目标、Profile XP。
- `P3` 首发表现与运营：庆祝 VFX / SFX、桌面轻表情 / cheer、基础 gamepass、核心埋点。
- 可评估极简决策点：高 streak 后出现 `Cash Out` / `Double` / bonus choice，但不要破坏“一键 Flip”的主循环。

## Recent Done

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
