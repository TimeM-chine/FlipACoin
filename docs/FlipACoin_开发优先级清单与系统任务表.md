# FlipACoin 开发优先级清单与系统任务表

## 1. 拆分前提

这份拆分不是只按策划案做理想切块，而是结合当前仓库真实情况整理的执行版本。

当前工程的关键现实：

- `SystemMgr` 当前实际启用系统只有：
  - `AnimateSystem`
  - `CharacterSystem`
  - `GuiSystem`
  - `MusicSystem`
  - `PlayerSystem`
- 旧 `RebirthSystem`、`DailySystem`、`EcoSystem` 都还保留着较强的旧 simulator 依赖，不适合直接打开就用。
- 当前最可靠的底座仍然是：
  - `SystemMgr`
  - `PlayerServerClass`
  - `DataManager`
  - `ClientData`
  - `uiController`
  - `ScheduleModule`

因此这次拆分采用一个原则：

- 能复用底座就复用底座
- 能借旧系统结构就借结构
- 但不为了“省事”强行启用旧玩法系统

## 2. 关键判断

### 2.1 建议直接复用的底座

- `SystemMgr`
- `BaseSystem`
- `PlayerSystem`
- `CharacterSystem`
- `GuiSystem`
- `uiController`
- `ScheduleModule`
- `PlayerServerClass`
- `DataManager`

### 2.2 建议轻改后复用的系统

- `MusicSystem`
  - 需要先去掉或兜底 `SettingsSystem` 依赖
- `AnimateSystem`
  - 可用于抛币、庆祝、座位入座等通用动画调度

### 2.3 建议不要直接启用的旧系统

- `EcoSystem`
  - 旧商城、礼包、宠物、转盘、赛季耦合过重
- `RebirthSystem`
  - 逻辑围绕旧 `wins -> power` 体系，不适配当前 Fate Shards 设计
- `DailySystem`
  - 当前更像签到奖励，不是新方案里的日常任务

结论：

- `RebirthSystem` 和 `DailySystem` 可以保留系统名，但建议按新需求重写成轻量版本
- `EcoSystem` 不建议在首发主链路里启用，Cash 结算先由 `CoinFlipSystem + PlayerSystem` 处理

## 3. 数据层建议

为了最大程度减少存档迁移风险，建议首发采用下面的数据策略：

- 继续复用 `wins` 作为底层软货币存档字段
- UI 和文案统一对外展示为 `Cash`
- 继续复用 `rebirth` 作为累计 rebirth 次数
- 新增 `fateShards` 作为永久货币
- 新增独立的抛币玩法数据，不污染旧 simulator 字段

建议新增的数据字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `fateShards` | number | rebirth 永久货币 |
| `bestStreak` | number | 历史最佳连正面 |
| `lifetimeFlips` | number | 累计抛币次数 |
| `lifetimeHeads` | number | 累计正面次数 |
| `lifetimeCashEarned` | number | 累计获得 Cash |
| `equippedCoin` | string | 当前装备硬币 |
| `ownedCoins` | table | 已拥有功能硬币 |
| `rebirthTree` | table | 永久起始等级树 |
| `autoFlipUnlocked` | boolean | 是否已解锁自动抛币 |
| `runData` | table | 当前 run 的四项升级、最佳 streak、run 内统计 |
| `dailyTasksV2` | table | 新版每日任务进度 |
| `weeklyTasksV2` | table | 新版每周任务进度 |
| `emotesOwned` | table | 桌边表情解锁 |
| `cosmetics` | table | 椅子、桌面、抛币轨迹等外观 |

`runData` 建议结构：

| 字段 | 类型 |
| --- | --- |
| `valueLevel` | number |
| `comboLevel` | number |
| `speedLevel` | number |
| `biasLevel` | number |
| `bestStreakThisRun` | number |
| `cashEarnedThisRun` | number |
| `flipsThisRun` | number |
| `headsThisRun` | number |

## 4. 开发优先级清单

## 4.1 P0：玩法底座与数据闭环

目标：先让“玩家坐下后能在服务端权威地抛一枚硬币，并看到结果同步到客户端”成立。

包含内容：

- 梳理并补齐 `Keys.lua`、`DefaultData.lua`、`DebugData.lua`
- 明确 `wins = Cash` 的兼容策略
- 在 `SystemMgr.lua` 注册新系统骨架
- 建立 8 人圆桌的场景座位数据
- 完成 `CoinFlipSystem` 最小闭环：
  - 抛币
  - 正反判定
  - streak 计算
  - Cash 结算
  - 四类升级数据存储
- 完成最小 UI：
  - 抛币按钮
  - 当前概率
  - 当前 streak
  - 当前 Cash
  - 四项升级按钮

P0 完成标准：

- 1 名玩家进服能坐下并抛币
- 服务端权威生成结果
- 客户端能稳定看到自己的结果与数值变化
- 离开重进后 runData 能正确恢复

## 4.2 P1：多人圆桌闭环

目标：从“单人能抛”升级为“8 人同桌可见”。

包含内容：

- 完成 `TableSeatSystem`
- 完成其他玩家抛币结果的可视同步
- 完成桌边 Billboard 信息同步
- 完成基础旁观体验
- 完成 AFK 自动离座
- 完成热点播报的基础版：
  - 3 连
  - 5 连
  - 7 连
  - 9 连
  - 10 连

P1 完成标准：

- 同桌玩家能看到彼此抛币表现
- 座位占用和释放稳定
- 热门 streak 播报不会乱序或重复
- 服务器满 8 人时仍可正常同步

## 4.3 P2：首发成长闭环

目标：把“能玩”变成“能留人”。

包含内容：

- 重写轻量 `RebirthSystem`
- 完成 `CoinLoadoutSystem`
- 完成 6 枚首发功能硬币
- 完成 `TableHypeSystem`
- 完成 Auto Flip 解锁与控制
- 完成新版 `DailySystem`
- 完成 Profile XP 和基础奖励投放

P2 完成标准：

- 玩家完成 1 次 rebirth 后能明显感受到开局变强
- 同桌行为会推动 Table Fever
- 日常任务能稳定刷新、推进和领奖
- 功能硬币能改变起手体验，但不会压过四核心升级

## 4.4 P3：首发表现与运营层

目标：让首发版本具备足够的传播性、打磨度和数据监控。

包含内容：

- 完成庆祝 VFX / SFX
- 完成桌面表情系统
- 完成基础商城和 gamepass 接入
- 补齐核心埋点
- 调整头顶信息、leaderstats、通知文案
- 对移动端 UI、触屏操作做适配

P3 完成标准：

- 10 连正面的高光时刻足够强
- 常见埋点能支撑留存和转化分析
- 移动端能完整进行抛币、升级、rebirth

## 4.5 P4：v1.1 及以后

目标：在首发数据验证后再扩内容，不抢首发节奏。

包含内容：

- Fate Cards
- 更完整的个性化外观
- 私人桌主题
- 排行榜
- 赛季化内容

结论：

- `Fate Cards` 放在 `v1.1`
- 不建议在首发前做多世界
- 不建议在首发前扩成复杂 simulator

## 5. 推荐开发顺序

建议实际排期按下面顺序推进：

1. 数据结构改造
2. `CoinFlipSystem`
3. `TableSeatSystem`
4. `PlayerSystem` / `CharacterSystem` 配套改造
5. 核心主 UI
6. `AnnouncementSystem`
7. `TableHypeSystem`
8. 轻量 `RebirthSystem`
9. `CoinLoadoutSystem`
10. 新版 `DailySystem`
11. `MusicSystem` / `GuiSystem` / 表现层
12. 商业化与埋点

原因：

- 先保证权威结算
- 再保证多人可见
- 再上成长系统
- 最后再堆表现和运营层

## 6. 系统任务表

## 6.1 核心系统

| 系统 | 处理方式 | 优先级 | 主要职责 | 核心任务 | 依赖 | 验收标准 |
| --- | --- | --- | --- | --- | --- | --- |
| `CoinFlipSystem` | 新建，建议基于 `BaseSystem` | P0 | 抛币核心循环、RNG、四类升级、Cash 结算、runData 存档 | 实现抛币请求、权威 RNG、收益公式、升级购买、Auto Flip 控制、runData 持久化、客户端结果回放 | `PlayerServerClass`、`ClientData`、`PlayerSystem` | 玩家可稳定完成抛币、升级、结算、离线恢复 |
| `TableSeatSystem` | 新建，建议基于 `BaseSystem` | P1 | 座位占用、坐下离开、AFK 踢座、旁观逻辑、桌面广播范围 | 维护 8 个座位状态、入座交互、离座处理、相机切换、桌边玩家列表、同桌同步范围 | 场景座位 Part/Attachment、`CharacterSystem` | 同桌可见、座位不串人、离开时资源能正确释放 |
| `AnnouncementSystem` | 新建，建议基于 `BaseSystem` | P1 | streak 播报、10 连全桌高光、事件节奏控制 | 监听 `3/5/7/9/10` streak、广播桌内提示、播放高光音效与动画、去重和节流 | `CoinFlipSystem`、`GuiSystem`、`MusicSystem` | 播报顺序正确，不重复刷屏 |
| `TableHypeSystem` | 新建，建议基于 `BaseSystem` | P2 | 桌面 Hype 累积、Table Fever 触发、共享收益 buff | 管理每桌 Hype 值、处理正反面与 streak 加成、触发 Fever、广播剩余时间、同步 HUD | `TableSeatSystem`、`CoinFlipSystem`、`AnnouncementSystem` | Hype 增长与 Fever 触发稳定、多人收益一致 |
| `CoinLoadoutSystem` | 新建，建议基于 `BaseSystem` | P2 | 功能硬币持有、装备、被动结算 | 定义硬币配置、装备切换、解锁条件校验、被动数值接入、客户端展示 | `CoinFlipSystem`、`PlayerSystem` | 6 枚硬币均可正常解锁和生效 |

## 6.2 复用并改造的现有系统

| 系统 | 处理方式 | 优先级 | 主要职责 | 核心任务 | 风险点 | 验收标准 |
| --- | --- | --- | --- | --- | --- | --- |
| `PlayerSystem` | 复用并扩展 | P0 | 玩家数据初始化、leaderstats、ClientData 首次同步 | 下发新数据字段、把 `wins` 继续作为 Cash 来源、补 fateShards/Profile XP 同步、更新头顶和排行榜字段 | 当前还残留旧 `power / rebirth` 逻辑 | 玩家进服后客户端数据完整，leaderstats 正确 |
| `CharacterSystem` | 复用并精简 | P1 | 角色头顶信息、坐姿表现、碰撞处理 | 头顶改成 coin 玩法信息、兼容座位状态、为坐下镜头/动画预留接口、清理旧依赖 | 当前引用 `RebirthSystem.Presets`，需去耦 | 坐下后角色和头顶信息表现稳定 |
| `GuiSystem` | 直接复用，小幅扩展 | P0-P3 | 服务端驱动客户端通知、通用提示入口 | 扩展通知类型，支持 streak 播报、rebirth 提示、任务提示、奖励提示 | 功能简单，但要避免业务系统各自直改 PlayerGui | 所有系统消息都能统一走通知通道 |
| `MusicSystem` | 复用前先修依赖 | P1-P3 | 抛币音效、播报音效、庆祝音效、桌面气氛音效 | 去掉或兜底 `SettingsSystem` 依赖、补桌面播报音效接口、支持本地/广播播放 | 当前依赖未启用 `SettingsSystem` | 音效调用不报 unloaded system warning |
| `AnimateSystem` | 按需复用 | P1-P3 | 入座、抛币、庆祝等统一动画入口 | 补 coin toss、celebrate、seat idle 等动画调度接口 | 需要和角色 rig、硬币模型表现对齐 | 动画调用统一，不在业务里散放 |

## 6.3 建议重写的旧系统

| 系统 | 处理方式 | 优先级 | 建议方案 | 不直接启用原因 | 验收标准 |
| --- | --- | --- | --- | --- | --- |
| `RebirthSystem` | 保留系统名，按新玩法重写 | P2 | 重写成 Fate Shards、rebirthTree、Auto Flip 解锁的轻量系统 | 旧逻辑绑定 `wins -> power`、还串旧训练体系 | rebirth 流程清晰，和当前玩法完全一致 |
| `DailySystem` | 保留系统名，按新任务结构重写 | P2 | 改为 3 个每日任务 + 周任务 + 奖励领取 | 旧逻辑偏签到奖励，不等于任务系统 | 每日/每周任务可刷新、推进、领奖 |

## 6.4 不建议首发启用的旧系统

| 系统 | 建议 | 原因 |
| --- | --- | --- |
| `EcoSystem` | 首发不启用主链路 | 旧商城、礼包、宠物、赛季依赖太重 |
| `QuestSystem` | 首发不作为主依赖 | 旧任务定义偏旧玩法，容易把新任务做复杂 |
| `SeasonSystem` | 首发不启用 | 会把项目拖进运营壳层，干扰核心打磨 |
| `TradeSystem` | 首发不启用 | 当前玩法不需要可交易核心资源 |
| `PetSystem` | 不启用 | 会直接把题材拉回旧 simulator 路线 |

## 7. 模块级任务拆分

## 7.1 配置与数据

| 模块/文件 | 任务 |
| --- | --- |
| `src/ReplicatedStorage/configs/Keys.lua` | 新增抛币玩法相关 DataKey |
| `src/ReplicatedStorage/configs/DefaultData.lua` | 加入 `fateShards`、`runData`、`ownedCoins` 等默认结构 |
| `src/ReplicatedStorage/configs/DebugData.lua` | 补调试数据，方便快速测试高阶内容 |
| `src/ReplicatedStorage/configs/GameConfig.lua` | 放全局玩法常量，例如桌子人数、AFK 时长 |
| `各系统 Presets.lua` | 放系统私有数值，不往全局配置乱塞 |

## 7.2 场景与资源

| 模块/资源 | 任务 |
| --- | --- |
| 圆桌场景 | 制作 8 个座位锚点、桌中心、旁观区域、特效挂点 |
| StarterGui 模板 | 补抛币 HUD、升级面板、桌面 Hype、播报条 |
| Billboard 模板 | 玩家名、当前 streak、装备硬币、状态图标 |
| 音效资源 | 抛币、正面、反面、接近 10 连、10 连成功、Table Fever |
| 动画资源 | 入座、等待、抛币、庆祝、失落反应 |

## 8. 建议的里程碑定义

### 里程碑 M1：单人可玩

包含：

- 数据字段补齐
- `CoinFlipSystem`
- 最小 HUD
- runData 存档

成功标志：

- 1 名玩家单人循环完整

### 里程碑 M2：8 人同桌

包含：

- `TableSeatSystem`
- 同桌共视
- `AnnouncementSystem`
- 头顶与座位表现

成功标志：

- 8 人同时抛币体验稳定

### 里程碑 M3：首发闭环

包含：

- `TableHypeSystem`
- `RebirthSystem`
- `CoinLoadoutSystem`
- 新版 `DailySystem`
- Auto Flip

成功标志：

- 玩家能从进入服务器一路体验到成长、rebirth 和回流

### 里程碑 M4：首发打磨

包含：

- 音画反馈
- 商业化
- 埋点
- 移动端适配

成功标志：

- 达到可上线测试的完成度

## 9. 推荐的 SystemMgr 启用顺序

最终建议启用顺序参考：

1. `PlayerSystem`
2. `CharacterSystem`
3. `GuiSystem`
4. `MusicSystem`
5. `CoinLoadoutSystem`
6. `CoinFlipSystem`
7. `TableSeatSystem`
8. `AnnouncementSystem`
9. `TableHypeSystem`
10. `RebirthSystem`
11. `DailySystem`

说明：

- 只有确实依赖前置数据初始化的系统才进 `LoadOrder`
- `CoinFlipSystem` 不应早于 `PlayerSystem`
- `TableHypeSystem` 要晚于 `TableSeatSystem` 和 `CoinFlipSystem`
- `RebirthSystem`、`DailySystem` 建议在核心循环稳定后再启用

## 10. 一句话执行建议

这个项目最合理的推进方式，不是“先把所有系统都搭出来”，而是：

`先做服务端权威的抛币闭环，再做 8 人同桌共视，再做 rebirth 和硬币成长。`

这样节奏最稳，也最符合当前工程的真实成熟度。
