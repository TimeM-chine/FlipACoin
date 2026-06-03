# Multi-Coin Flip Plan

日期：2026-06-03

状态：计划文档；Phase 0 正反馈调参、Phase 1 服务端多金币结算 MVP、Phase 2 HUD 结果文案、Phase 3 多金币世界表现、Rebirth coin 数量迁移和 Phase 4 组合庆祝强化已执行；Phase 5 已执行 Bad Luck Pity、Table Jackpot、Edge Stand 和 Lucky Coin trait 小步，其他深层特殊事件尚未实现。

目的：把玩家反馈中提到的“目标不够有吸引力、正反馈太低、体验太平常”拆成可逐步实现的调整。核心方向是保留当前 `Flip A Coin` 的一键桌面主循环，但让一次 `FLIP` 可以在成长后结算多枚金币、更多奖励组合和少量稀有事件。

## 0. 执行状态

- 2026-06-02：Phase 0 正反馈调参已执行。当前仅增强 `GameConfig.FlipACoin` 的早期概率、奖励和 Combo 曲线；尚未实现多金币结算、round streak 或特殊事件。
- 2026-06-02：Phase 1 服务端多金币结算 MVP 已执行。服务端 payload 已包含 `coinResults / headsCount / roundSuccess / successThreshold / perfect / comboName / comboMultiplier`，`currentStreak` 已切换为 round streak 语义。
- 2026-06-02：Phase 2 HUD 结果文案已执行。当前客户端用现有 `ResultLabel` 显示多金币结果，如 `2/3 Heads! Pair +$ 48`、`1/3 Heads. Streak reset. +$ 10`；仍未新增 `CoinResultRow` prefab。
- 2026-06-02：多金币数量已从本局 `Value` 迁移到 Rebirth 永久升级 `Coin Spread`。实际结算从 `runData.coinCountLevel` 派生 `coinCount`，`Value` 只影响 Heads Cash 倍率。
- 2026-06-02：Phase 3 世界多金币视觉已执行。`EffectSystem` 在 `coinCount > 1` 时克隆短生命周期 coin / shadow / pulse，并按玩家到中心落点轴线生成左右对称扇形落点。
- 2026-06-03：多金币扇形表现加宽。相邻扇形角度从 `8°` 提到 `13°`，半角上限从 `18°` 提到 `30°`，3/4/5 枚 coin 分别临时缩放到 `0.94 / 0.90 / 0.86`。
- 2026-06-03：多金币结算后不再按固定秒数恢复成 1 枚 Coin；多枚结果会留在桌面上，直到该座位下一次 Flip、隐藏或换装清理。
- 2026-06-03：Phase 4 组合庆祝强化已执行。服务端 outcome / payload 新增 `comboKey / comboTier / comboMilestone`；Triple 及以上组合复用现有 streak/bestStreak VFX 路径做落地庆祝，Jackpot 才发全桌低噪音文字通知；HUD 对 Jackpot / Perfect 使用更明确的一行结果文案；Analytics compact round outcome 末尾追加 combo key。
- 2026-06-03：Phase 5 先执行 Bad Luck Pity。真实玩家连续 round 失败达到阈值后，下一轮获得隐藏正面率加成；该补偿只影响服务端 roll，不改变 round streak 阈值，不新增 UI，也不写持久化。
- 2026-06-03：Phase 5 Table Jackpot 小步已执行。真实玩家 `5/5 Heads` 时，会给同桌其他真实玩家发小额 Cash 和轻提示；fake player 不触发共享奖励，不新增 UI / 资产 / 持久字段。
- 2026-06-03：Phase 5 Edge Stand 小步已执行。真实玩家失败轮在连续失败压力下有低概率触发立币，保护当前 round streak 不清零并给小额 bonus；fake player 不触发，不新增 UI / 资产 / 持久字段。
- 2026-06-04：Lucky Coin trait foundation 小步已执行。高阶 Coin `coin7` 到 `coin10` 在现有 `stats` 中提供少量 `edgeStandChanceBonus`，通过 loadout bonus 汇总后提高真实玩家 Edge Stand chance；不新增 Coin 面板、不改手机端 UI、不新增持久字段。
- 2026-06-04：Lucky Coin perfect bonus 小步已执行。同一批高阶 Coin 额外提供 `perfectRewardMultiplierBonus`，只提高 `perfect` / `jackpot` 组合奖励，不影响普通 Heads、round streak、UI 或持久字段。
- 2026-06-04：Lucky Coin Tails reroll 小步已执行。同一批高阶 Coin 额外提供低概率 `tailsRerollChance`，服务端每轮最多把 1 个 Tails 重掷一次；最终结果再参与成功、奖励和特殊事件判定。

## 1. 设计目标

- 保留当前首发定位：单桌 `8` 人、弱社交、高频一键 Flip。
- `FLIP` 仍然只有一个主入口：HUD 点击、`Space`、手柄 `RT` 继续走统一 Flip 请求。
- 多金币是“单次 Flip 的开奖内容升级”，不是新增复杂操作。
- 服务端先权威结算，再做客户端表现。
- `Streak` 改成按“一轮 Flip”计算，不按每枚金币计算。
- 首轮实现优先让玩家感到奖励变大、变化变多，再考虑复杂牌型构筑。
- UI 和复杂视觉结构继续以 Studio-authored prefab 为目标；Luau 负责读取、绑定、显隐和动态数值。

## 2. 非目标

- 不把项目改成完整卡牌构筑游戏。
- 不新增主动选择、换牌、留牌、现金退出等复杂操作。
- 不在第一阶段新增多桌大厅、手动切桌或强社交系统。
- 不用代码运行时创建可编辑 UI prefab。
- 不在没有验证的情况下重写整个经济曲线。

## 3. 当前基线

当前主线配置和结算集中在：

- `src/ReplicatedStorage/configs/GameConfig.lua`
- `src/ReplicatedStorage/Systems/CoinFlipSystem/Presets.lua`
- `src/ReplicatedStorage/Systems/CoinFlipSystem/init.lua`
- `src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua`
- `src/ReplicatedStorage/Systems/EffectSystem/init.lua`
- `src/ReplicatedStorage/Systems/RebirthSystem/Presets.lua`

当前重要数值：

- `BaseHeadsChance = 0.23`
- `MaxHeadsChance = 0.60`
- `BaseReward = 7`
- `BaseTailsReward = 1`
- `BaseFlipInterval = 1.60`
- `ValueGrowth = 1.19`
- `ComboBaseStep = 0.18`
- `ComboStepPerLevel = 0.04`
- `BiasStep = 0.025`

当前 `currentStreak` 是连续 Heads 的语义。多金币上线后，建议保留字段名以减少改动面，但把项目语义更新为 `Round Streak`：连续多少轮达到成功条件。

## 4. 核心规则方案

### 4.1 一轮 Flip

一轮 Flip 是玩家按一次 `FLIP` 后发生的完整结算。

- 单金币阶段：一轮只有 `1` 枚金币。
- 多金币阶段：一轮有 `2` 到 `5` 枚金币。
- 每枚金币独立 roll `Heads` / `Tails`。
- 一轮最终产生：
  - `coinCount`
  - `headsCount`
  - `tailsCount`
  - `coinResults`
  - `roundSuccess`
  - `roundStreak`
  - `perfect`
  - `comboName`
  - `reward`

### 4.2 多金币数量来源

当前实现不新增第五个 run upgrade 卡片，也不再从本局 `Value` 升级派生 `coinCount`。多金币数量由 Rebirth 面板第一张永久升级 `Coin Spread` 控制；持久 key 仍沿用旧 `polishedStart`，购买后通过 baseline 写入 `runData.coinCountLevel`，不再顺带提高起始 `valueLevel`。

当前阈值：

```lua
CoinCountByLevel = {
	{ minLevel = 0, count = 1 },
	{ minLevel = 1, count = 2 },
	{ minLevel = 2, count = 3 },
	{ minLevel = 3, count = 4 },
	{ minLevel = 4, count = 5 },
}
```

### 4.3 Round Streak

推荐定义：

`Round Streak = 连续多少轮达到成功条件。`

成功条件按金币数量变化：

```lua
SuccessThresholdByCoinCount = {
	[1] = 1,
	[2] = 1,
	[3] = 2,
	[4] = 2,
	[5] = 3,
}
```

结算规则：

- 如果 `headsCount >= threshold`，本轮成功，`currentStreak += 1`。
- 如果 `headsCount < threshold`，本轮失败，`currentStreak = 0`。
- 每枚 Heads 可以给基础奖励，但不能让 streak 逐枚增加。
- `perfect = headsCount == coinCount`，只用于额外爆点和桌面高光。

这样可以避免一次 `5` 枚全正面直接把 streak 加 `5`，也能保留玩家对“连胜”的直觉理解。

### 4.4 Partial Win

多金币后需要区分“有钱拿”和“连胜成功”。

例子：一次投 `3` 枚，阈值是 `2`。

- `H H H`：成功，streak +1，Perfect，大奖。
- `H H T`：成功，streak +1，Pair，小爆奖。
- `H T T`：有一个 Heads 的基础奖励，但 round 失败，streak reset。
- `T T T`：失败，streak reset，只给 Tails 保底或触发 pity 机会。

这能减少多金币失败时的挫败感，同时让 streak 仍然有压力。

### 4.5 Perfect Streak

建议新增可选字段 `perfectStreakThisRun`，用于记录连续全 Heads 轮数。

- 普通 `currentStreak` 负责主奖励倍率。
- `perfectStreakThisRun` 只负责稀有庆祝、桌面广播和特殊事件概率。
- 如果第一版想控制改动面，可以先不持久化 perfect streak，只在单次 payload 中表现 `perfect`。

如果新增字段，需要同步：

- `CoinFlipSystem/Presets.lua` 的 `RunDataDefaults`
- `RebirthSystem/Presets.lua` 的 `RunDataDefaults`
- `DefaultData.lua` 中 FlipACoin runData 默认值
- `DebugData.lua` 或测试夹具中相关默认数据
- `PROJECT_LOGIC.md` 当前事实说明，等实现完成后再更新

## 5. 奖励模型

### 5.1 第一版公式

推荐先保持公式简单：

```text
perHeadReward = BaseReward * ValueMultiplier * CoinMultiplier
headsReward = perHeadReward * headsCount
streakMultiplier = 1 + max(roundStreak - 1, 0) * ComboStep
comboMultiplier = ComboMultiplierByHeadsCount[headsCount]
reward = round(headsReward * streakMultiplier * comboMultiplier)
```

失败轮：

```text
reward = round(BaseTailsReward * tailsCount * PremiumCoinMultiplier)
```

说明：

- 成功轮使用递增后的 `roundStreak` 计算倍率，延续当前单金币逻辑的体感。
- 失败轮保留小额奖励，降低全 Tails 或低 Heads 轮的空转感。
- `Combo` 升级继续提升 streak payout，不要第一版就把它改成牌型系统。

### 5.2 组合奖励

第一版只按 `headsCount` 做组合，不引入金币花色或符号。

建议表：

```lua
ComboMultiplierByHeadsCount = {
	[0] = 0,
	[1] = 1.00,
	[2] = 1.20,
	[3] = 1.75,
	[4] = 2.60,
	[5] = 4.00,
}
```

显示名：

- `1` Heads：Heads
- `2` Heads：Pair
- `3` Heads：Triple
- `4` Heads：Four Heads
- `5` Heads：Royal Sweep 或 Jackpot
- `perfect` 且 `coinCount >= 3`：追加 Perfect 文案和更强表现

### 5.3 早期数值爆发

在多金币之前，可以先做一个独立调参阶段，让 alpha 玩家立即感到反馈增强。

建议第一轮实验值：

- `BaseHeadsChance`: `0.23` -> `0.30`
- `BaseReward`: `7` -> `10`
- `BaseTailsReward`: `1` -> `2`
- `ValueGrowth`: `1.19` -> `1.28`
- `ComboBaseStep`: `0.18` -> `0.25`
- `ComboStepPerLevel`: `0.04` -> `0.06`
- `Rebirth.MinCash`: 如果 30 秒内过快达到，可从 `250` 调到 `350` 或 `500`

这一步应该单独提交和验证。不要和多金币代码混在一起，否则很难判断是数值变好还是规则变好。

## 6. 服务端实现计划

### 6.1 Presets

目标文件：`CoinFlipSystem/Presets.lua`

新增或调整函数：

- `GetCoinCount(runData, bonusStats)`
- `GetRoundSuccessThreshold(coinCount)`
- `RollCoinResults(runData, bonusStats, hiddenChanceBonus)`
- `BuildRoundOutcome(runData, bonusStats, hiddenChanceBonus, hiddenChanceMax)`
- `GetComboMultiplier(headsCount)`
- `GetComboName(headsCount, coinCount, perfect)`
- `GetRoundReward(runData, bonusStats, outcome)`

保留或兼容：

- `GetHeadsChance()`
- `GetRollHeadsChance()`
- `GetFlipInterval()`
- `GetComboStep()`
- `GetValueMultiplier()`

### 6.2 CoinFlipSystem

目标文件：`CoinFlipSystem/init.lua`

改动方向：

- `resolveFlip()` 从单次 `isHeads` 改为生成 `outcome`。
- 先计算 `coinResults`、`headsCount`、`roundSuccess`。
- 如果成功，更新 `currentStreak` 和 `bestStreakThisRun`。
- 如果失败，重置 `currentStreak`。
- 根据 outcome 计算 `reward`。
- 更新 `cashEarnedThisRun`、`flipsThisRun`、`headsThisRun`。
- `lifetimeHeads` 增加 `headsCount`，不是只加 `1`。
- `result` 保持兼容：成功时仍给 `"Heads"`，失败时给 `"Tails"`。
- 新增详细 payload 字段供客户端使用。

建议 payload：

```lua
{
	result = roundSuccess and "Heads" or "Tails",
	reward = reward,
	streak = runData.currentStreak,
	coinCount = coinCount,
	coinResults = { "Heads", "Tails", "Heads" },
	headsCount = headsCount,
	tailsCount = tailsCount,
	roundSuccess = roundSuccess,
	successThreshold = successThreshold,
	perfect = perfect,
	comboName = comboName,
	comboMultiplier = comboMultiplier,
}
```

### 6.3 Announcement and Analytics

需要检查并调整：

- `AnnouncementSystem:BuildBestStreakPayload()` 是否仍以 `streak` 字段工作。
- `AnalyticsSystem` 的 Flip 埋点是否需要新增多金币字段。

建议埋点字段：

- `coinCount`
- `headsCount`
- `tailsCount`
- `roundSuccess`
- `successThreshold`
- `perfect`
- `comboName`
- `comboMultiplier`
- `reward`
- `currentStreak`
- `valueLevel`
- `comboLevel`
- `speedLevel`
- `biasLevel`

## 7. 客户端 UI 计划

目标文件：`CoinFlipSystem/ui.lua`

第一版尽量少改 Studio UI 结构，只改文案和现有 result/stat 显示。

### 7.1 Result 文案

单金币仍显示：

- `Heads! +$ 10`
- `Tails! +$ 2`

多金币显示：

- `2/3 Heads! Pair +$ 48`
- `3/3 Heads! Perfect Triple +$ 120`
- `1/3 Heads. Streak reset. +$ 10`
- `0/3 Heads. Streak reset. +$ 6`

### 7.2 Stat 文案

当前右侧 `Streak` 可以保留，但 tooltip 或短说明要改为 round 语义：

- `Streak`: 当前连续成功轮数。
- `Combo`: Bigger payouts as your round streak grows.

### 7.3 多金币小展示

如果只做第一版文案，可以不新增 UI prefab。

如果要加可视小结果条，应在 Studio 创建 HUD 内的 `CoinResultRow` prefab，再由代码绑定：

- 每枚小金币一个预制节点。
- 运行时只切换 `Visible`、`Image`、`Text` 或颜色。
- 不在 `ui.lua` 里用 `Instance.new` 创建可编辑 UI。

### 7.4 引导

第一版不改 onboarding 步骤。

只需要确认：

- 初始单金币仍能完成首次 Flip。
- Rebirth `Coin Spread` 升级提高多金币阈值时，短文案提示 `Coin Spread unlocked 2 coins per flip`。
- 如果新增 toast，走现有 `GuiSystem` / notification 路径，不手写并行 UI。

## 8. 视觉与音效计划

目标文件：

- `EffectSystem/init.lua`
- `EffectSystem/Presets.lua`
- Studio-owned assets under `ReplicatedStorage.Systems.EffectSystem.Assets`

### 8.1 第一版表现

已执行：多金币结果仍用 UI 文案结算，同时世界里会显示多枚硬币。

HUD 不新增 `CoinResultRow` prefab，避免先改 Studio UI 结构。

### 8.2 多金币世界表现

当前多金币视觉：

- 每枚金币从玩家前方中心附近抛出。
- 落点在当前座位前方桌面，以玩家到中心落点的线段为中轴，按 `13°` 间隔左右对称展开成扇形，最多使用 `30°` 半角。
- 3/4/5 枚 coin 会轻微临时缩放到 `0.94 / 0.90 / 0.86`，降低落地结算时互相遮挡的概率。
- 自己 Flip 时相机继续跟随主硬币，后续 Studio 观感如果偏离中心，再单独改成跟随整组中心。
- 他人 Flip 保持低噪音，只显示多金币落地 pulse，不播放 observed result SFX。
- `coinLandingBurst` 当前按每枚金币播放一次短 burst。

当前落点计算：

```text
center = dynamic coin landing surface position
axis = center - actorSurfacePosition
angleOffset = (index - (coinCount + 1) / 2) * cappedFanAngleStep
landingPosition = actorSurfacePosition + rotate(axis, tableNormal, angleOffset)
```

### 8.3 SFX

需要避免 `5` 枚金币同时播放 `coinLand` 造成噪音。

建议：

- Toss 使用一条更厚的 `coinToss` 或略变速播放。
- Spin 仍按一轮播放一次。
- Land 对多金币用短间隔 sequence，最多 `3` 次 audible tick。
- Perfect / Jackpot 使用单独高光 SFX。
- 他人和 fake player 继续 suppress 高价值结算音，保留低噪音桌面反馈。

## 9. Fake Player 计划

Fake player 应该用同一套服务端结算规则。

需要确认：

- fake actor 的 runData 能派生 `coinCount`。
- fake `ObservedFlip()` payload 包含 `coinCount` 和 `coinResults`。
- fake 不读取真实玩家 potion / buff。
- fake 高 coinCount 时不要全桌频繁大特效。

第一版可以让 fake 仍保持较低 coinCount，避免玩家刚进服就看到桌上大量高阶结果，破坏新手节奏。

## 10. Rebirth 和长期成长

当前实现从 Rebirth 永久升级 `Coin Spread` 派生 `coinCount`。持久 key 沿用 `polishedStart`，但展示名改为 `Coin Spread`；购买后提高 `runData.coinCountLevel`，不再提高起始 `valueLevel`。

需要平衡：

- 如果 `Coin Spread` 太快让新 run 直接多金币，Rebirth 后开局反馈会很强，但经济可能膨胀。
- 如果 Rebirth Points 获取太慢，多金币会太晚出现，无法解决早期体验太平常的问题。

建议：

- 第一次多金币应在首次 Rebirth 后第一次购买 `Coin Spread` 时立即出现。
- 第二次多金币应在后续 `Coin Spread` 购买中有清晰目标感。
- `5` 枚金币可以作为高等级或 Rebirth 后中期目标，不需要新手马上体验。

如果后续把 `Coin Spread` 拆成独立新 Rebirth 卡或 run upgrade，需要同步：

- `GameConfig.FlipACoin.UpgradeConfigs`
- `CoinFlipSystem/Presets.lua` upgrade order and aliases
- `CoinFlipSystem/ui.lua` upgrade card binding
- Studio HUD upgrade button prefab
- `RebirthSystem/Presets.lua` permanent upgrade tree
- `DefaultData.lua`
- `Onboarding.lua` 如需引导
- `PROJECT_LOGIC.md`

## 11. 特殊事件计划

特殊事件应在多金币 MVP 稳定后做，不要第一版混入。

候选事件：

### 11.1 Edge Stand

硬币立起来。

- 触发：低概率，或连续失败后的 pity。
- 当前小步触发：真实玩家失败轮，且连续失败达到配置门槛后按低概率触发；pity active 时触发率略高。
- 当前小步效果：不把失败改成成功、不增加 streak，但保护当前 round streak 不清零，并给小额 bonus。
- 当前小步表现：被选中的 Tails coin 以竖立姿态落桌，并复用现有 highlight / ResultLabel；不新增 VFX 资产。

### 11.2 Table Jackpot

全桌共享小奖励。

- 触发：`5/5 Heads` 或连续 perfect。
- 当前小步触发：真实玩家 `5/5 Heads`。
- 当前小步效果：本人大奖走原有 jackpot reward；同桌其他真实玩家获得小 Cash。
- 当前小步表现：复用现有 Jackpot 组合庆祝、ResultLabel 和轻 notification，不新增桌面中心 VFX 资产。
- 注意：视觉 / 公告必须走既有系统路径，不新增并行 remote 或强噪音表现。

### 11.3 Bad Luck Pity

失败补偿。

- 触发：连续多轮失败。
- 效果：下一轮 hidden chance bonus、保底 bonus、或降低成功阈值一轮。
- 目的：减少多金币后低 roll 的挫败。
- 注意：不要让 UI 明示太复杂，保持体感即可。

### 11.4 Lucky Coin

装备金币词条扩展。

- 当前小步触发：装备高阶 Coin `coin7` 到 `coin10` 后，`EcoPresets.BuildLoadoutBonuses()` 汇总其 `edgeStandChanceBonus`、`perfectRewardMultiplierBonus` 和 `tailsRerollChance`。
- 当前小步效果：`edgeStandChanceBonus` 提高 Edge Stand 触发率，仍受 `GameConfig.FlipACoin.EdgeStand.MaxChance` 上限约束；`perfectRewardMultiplierBonus` 只提高 `comboKey == "perfect"` 或 `"jackpot"` 的成功轮奖励；`tailsRerollChance` 低概率把一个 Tails 重掷一次，最终结果再进入 round success / reward / special event 判定。
- 注意：当前只是 trait 小步，不新增 Coin 面板、不改手机端 UI、不新增持久字段；更复杂的符号、花色或可视化词条仍是后续内容。

## 12. 分阶段实施拆分

### Phase 0: 正反馈调参

目标：不改规则，只提高早期爽感。

改动范围：

- `GameConfig.lua`
- 必要时调整 `RebirthSystem/Presets.lua`
- 可选：`CoinFlipSystem/ui.lua` result 文案更强

验证：

- 新档 1 分钟内至少能买到首次 Value。
- 3 到 5 分钟内能看到明显 cash 增长和 Rebirth 目标。
- `git diff --check`。
- 纯 Luau 数值改动不跑 `rojo build`。

### Phase 1: 多金币服务端结算 MVP

目标：一轮 Flip 能结算多枚金币，payload 可表达详细结果。

状态：2026-06-02 已执行。

改动范围：

- `GameConfig.lua`
- `CoinFlipSystem/Presets.lua`
- `CoinFlipSystem/init.lua`
- `AnalyticsSystem` 如需埋点字段
- `DefaultData.lua` 仅在新增字段时修改

验证：

- 单金币玩家行为保持兼容。
- `Coin Spread` 购买后 `coinCountLevel` 正确进入 run baseline，并让 `coinCount` 增加。
- `currentStreak` 按 round success 增减。
- `lifetimeHeads` 按 `headsCount` 增加。
- reward 不出现负数或异常爆炸。
- fake player 不报错。

### Phase 2: 客户端文案和 HUD 表达

目标：玩家能理解多金币结果。

状态：2026-06-02 已执行；当前只用现有 `ResultLabel` 和一行 tip，不新增 Studio-authored `CoinResultRow`。

改动范围：

- `CoinFlipSystem/ui.lua`
- 可选 Studio-authored `CoinResultRow`

验证：

- `1/1`、`1/3`、`2/3`、`3/3` 等文案清楚。
- Streak reset 文案不会和有 Heads 奖励矛盾。
- 移动端文本不挤出按钮或面板。
- 引导高亮不被新增显示挡住。

### Phase 3: 多金币世界表现

目标：桌面上真的看到多个金币落下。

状态：2026-06-02 已执行；多金币扇形落点已接入 `EffectSystem`，仍需 Studio 观感验证。

改动范围：

- `EffectSystem/init.lua`
- `EffectSystem/Presets.lua`
- Studio-owned VFX / SFX assets

验证：

- 自己 Flip 的相机能看清整组金币。
- 其他玩家 Flip 不造成桌面视觉噪音。
- `8` 人同桌，最多 `5` 枚金币表现不会明显掉帧。
- cleanup 后 workspace 不残留大量 coin / particle / sound 实例。
- 双客户端同桌看到的 observed flip 信息一致。

### Phase 4: 组合奖励和庆祝强化

目标：让多金币结果有“开奖感”。

状态：2026-06-03 已执行；本轮不新增 Studio UI prefab 或新 VFX 资产，复用现有 `streak3 / streak5 / bestStreak` 资源与 fallback pulse/highlight。

改动范围：

- `CoinFlipSystem/Presets.lua`
- `CoinFlipSystem/init.lua`
- `CoinFlipSystem/ui.lua`
- `EffectSystem`
- `AnnouncementSystem`

验证：

- Pair / Triple / Perfect / Jackpot 奖励符合表。
- 高价值结果触发桌面弱社交反馈。
- 他人高光不播放自己的高价值 SFX。
- Analytics 能看出不同组合的出现率和奖励规模。

### Phase 5: 特殊事件

目标：加入少量低频记忆点。

状态：2026-06-04 部分执行；已上线 Bad Luck Pity、Table Jackpot、Edge Stand 和 Lucky Coin trait 小步，其他深层特殊事件仍保留为候选。

改动范围：

- `GameConfig.lua`
- `CoinFlipSystem/Presets.lua`
- `CoinFlipSystem/init.lua`
- `EffectSystem`
- `AnnouncementSystem`
- `AnalyticsSystem`

验证：

- Edge Stand / Jackpot / Pity / Lucky Coin trait 触发率和奖励倍率可控。
- 事件不会破坏 round streak 语义。
- 事件奖励不会绕过服务端权威结算。
- 事件表现不会影响 `FLIP` 冷却和 Auto Flip。

## 13. 推荐第一轮执行顺序

1. 做 Phase 0 数值爆发，先确认“反馈太低”能否被快速改善。
2. 做 Phase 1 服务端多金币结算，但世界表现仍可先用单金币。
3. 做 Phase 2 文案和 HUD 结果表达。
4. Studio Play 单客户端验证新档路径和 Rebirth `Coin Spread` 解锁多金币。
5. Studio Play 双客户端验证 observed payload 和同桌弱反馈。
6. 复测 Phase 3 多金币世界表现。
7. 多金币表现稳定后，再做 Phase 4 和 Phase 5。

## 14. 风险与处理

- 数值膨胀：先用独立 Phase 0 验证，再引入多金币，避免混淆。
- Streak 语义混乱：所有 UI 文案统一为 round streak，不写“每个 Heads 加连胜”。
- 多金币视觉过载：先文案 MVP，再做世界表现；他人 Flip 必须低噪音。
- Rebirth 节奏被压扁：多金币上线后重新测首次 Rebirth 时间。
- Mobile HUD 挤压：新增 UI 必须在手机 portrait / landscape 看过。
- Auto Flip 过快刷大量 VFX：多金币视觉阶段必须检查 cleanup 和音效节流。

## 15. 实现后必须同步的文档

规则或系统真正实现后，再同步：

- `docs/TASK_STATE.md`：记录进度、验证、后续问题。
- `docs/PROJECT_LOGIC.md`：更新当前项目事实，包括 multi-coin 规则、streak 语义和运行入口。
- `docs/FRAMEWORK.md`：只有框架机制变化时才更新；多金币玩法本身不写进框架文档。
