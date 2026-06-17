# TASK_STATE

最后更新：2026-06-18

> 目的：记录当前正在做什么、下一步是什么、关键决策、待验证项与后续想法。项目事实放 `PROJECT_LOGIC.md`，框架规则放 `FRAMEWORK.md`；已完成的历史日志放 `docs/archive/`。

## Active

- 当前没有进行中的实现任务。
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
- 2026-06-17 市场评审取舍：资源有限时，首发优先前 `3` 分钟留存、Flip 反馈层级、移动端首屏、合规变现和现有同桌弱社交验证；收集 / 图鉴 / 稀有度 / 套装 / 限时外观进入后续 Backlog。
- 2026-06-17 Rewarded Ads 因 Roblox 新游戏 eligibility / DAU 要求移出首发范围；首发只保留 Robux Developer Product / Game Pass 变现，广告奖励后续满足资格再评估。
- Timing Bonus / Power Flip / Buff Choice 等轻操作补充暂不进入首发必做，除非首轮测试明确暴露“一键 Flip”疲劳问题。
- 2026-06-01 及以前的详细完成日志已移入 `docs/archive/TASK_STATE_DONE_2026-05_TO_2026-06-01.md`；live task state 只保留最近完成项和当前交接信息。

## Launch Must-Do Task List

> Scope：首发版本只做能支撑上线留存、稳定性、移动端、合规变现和已有弱社交体验的事项。`Collection Book`、稀有度图鉴、套装完成奖励、限时外观和大规模新资产不作为首发阻塞；现有 Coin / Desk / Chair 仍需要完成运行态观感验证。

### P0 Release Blockers

- **生产配置与变现闭环**：`Products.flipACoin` 七个 Developer Product 和四个 Game Pass ID 已填入；源码侧已补齐付费发货后的 `gamePasses / loadout / rebirthState` 客户端同步；仍需真实 Roblox 购买 prompt、发货、HUD / Shop / Inventory / Rebirth / Boosts 刷新、`coinflip_gamepass_granted` 和 potion grant / use 埋点手动 QA。
- **Creator Dashboard 清理**：确认旧项目商品入口已隐藏；Rewarded Ads 不进首发，不再创建或填回广告专用 Developer Product；如果需要排行榜展示，再补回启动前存在的 `Workspace.RankingList` 实例树。
- **前 `3` 分钟首局体验**：源码侧已补齐新档默认 Cash `9`、首次 Flip 引导、v4 Value 升级高亮、Rebirth 不可用阶段的目标金额和 `Coin Spread` 首级价值曝光；仍需 Studio Play 确认 `2-3` 分钟内节奏与文案观感。
- **核心单客户端 Play QA**：确认 `8` 座自动分配、满员等待、空位释放再分配、重生回座、HUD `Seat --` 到真实座位稳定切换、HUD / `Space` / 手柄 `RT` 统一 Flip、桌面相机两态切换、Rebirth / Shop / Inventory / Boosts 顶栏打开关闭流程。
- **移动端首屏 QA**：覆盖手机 portrait / landscape、平板和安全区；确认默认移动 / 跳跃控件关闭，`FLIP`、Cash、Streak、Chance、Auto、当前目标和四个升级入口不互相遮挡，growth panels 与 Topbar 入口可点且不挤压。
- **合规语义检查**：玩家可见文案继续保持 simulator / luck / fortune / table bonus 方向；避免 `bet / wager / casino / payout / gambling / stake` 等包装；`Perfect Five / Table Bonus / Edge Stand` 不表现为下注或对赌。

### P1 Launch Polish

- **Flip 反馈层级验证与微调**：Tails 保底、Heads、Multi Heads、Triple / Four Heads、Perfect / Perfect Five、Edge Stand、Streak milestone、Table Bonus 要有可分辨的文案、VFX、SFX 和强度层级；高价值结果不能挤压移动端 ResultLabel。
- **多 Coin 与 Rebirth 体感**：确认 `Coin Spread` 购买后即时生效，primary coin 是视觉中位币并承载镜头 / 强落地 burst，多枚 coin 落点清晰且下一轮会清理；第一次 Rebirth 后能看到 unlock banner 和下一次多 coin 首秀。
- **Bad Luck / 稀有事件体感**：确认 Bad Luck Pity 不显得保送；Edge Stand 只由真实玩家失败轮低概率触发并保护 round streak；高阶 Coin `coin7` 到 `coin10` 的 Edge Stand bonus、Perfect reward bonus 和 Tails reroll 不让结果文案困惑。
- **同桌弱社交 QA**：双客户端确认他人落地 pulse / streak ring / highlight、table knock、Table Bonus 共享奖励和 notification；fake player 不触发共享奖励、Edge Stand 或真实玩家 analytics。
- **成长与埋点 QA**：确认 Profile XP、轻量每日目标、前 `3` 分钟短会话、首次入座 / Flip / Auto / run upgrade / growth panel、`10` 次 Flip、离服等 analytics 写入；Dashboard `Count` / `Sum value` 语义按批处理文档理解。
- **现有装扮资产观感**：确认 `coin1` 到 `coin10`、Desk Setup、Chair 的购买 / 装备 notification 与 SFX，座位刷新即时生效，落点不沉桌，桌搭 / 椅子不遮挡 Coin。

## Resource Needs

- Creator Dashboard 确认项：旧商品入口是否已隐藏；`cashPackSmall / cashPackMedium / cashPackLarge / rebirthShardSmall / rebirthShardLarge / apexLoadoutBundle / paidCash2x10m` 和 `vip / winsX2 / luckyCharm / quickFlip` 的 ID 已在配置中填入，首发不再需要 Rewarded Ads 专用 product。
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

### 2026-06-15 Launch readiness audit

- Outcome: 完成上线前源码、配置、Studio 实例和单客户端 Play sanity 审计；核心服务端权威路径成立，但上线前仍需处理生产日志、购买链路验证、排行榜缺失提示和旧商品 Dashboard 暴露风险；Rewarded Ads 后续已移出首发范围。

## Archived Done History

- 2026-06-14 的完成记录已压缩归档到 `docs/archive/TASK_STATE_DONE_2026-06-14.md`。
- 2026-06-13 的完成记录已压缩归档到 `docs/archive/TASK_STATE_DONE_2026-06-13.md`。
- 2026-06-05 的完成记录已压缩归档到 `docs/archive/TASK_STATE_DONE_2026-06-05.md`。
- 2026-06-02 到 2026-06-04 的较早完成记录已压缩归档到 `docs/archive/TASK_STATE_DONE_2026-06-02_TO_2026-06-04.md`。
- 2026-06-01 及以前的完成记录已压缩归档到 `docs/archive/TASK_STATE_DONE_2026-05_TO_2026-06-01.md`。
