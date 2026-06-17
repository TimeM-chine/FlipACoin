# PROJECT_LOGIC

更新时间：2026-06-17

## 1. 这份文档的定位

这份文档是给“新开 agent 窗口 / 新协作者”快速接管项目用的运行地图，不是策划案，也不是理想化架构说明。

新窗口建议先走轻量启动路由：

1. `docs/BOOTSTRAP.md`
2. `docs/TASK_STATE.md` 的 `## Active`
3. 按任务类型再读本文相关章节或 `docs/FRAMEWORK.md` 相关章节
4. 需要落代码时，再回到对应系统源码核实

如果文档和代码冲突：

- 以当前代码为准
- 再顺手把本文档更新掉

---

## 2. 当前项目一句话总结

这是一个基于旧 `SystemMgr + Systems` 框架持续改造中的 `Flip A Coin` 项目。

当前主玩法目标已经校准为 **单桌 8 人、弱社交、高频 Flip 的桌面运气游戏**：

- 每个服务器只有一张主桌，最大 `8` 人同桌
- 玩家进服后自动分配到 `CoinFlipTable` 的空座位并坐下
- 玩家面前有一个非常明确的 `FLIP` 主按钮，并可切换 `Auto:Off / Auto:On`
- 正面给主要 `wins` 奖励，反面给少量保底 `Cash`，但会打断 streak
- `wins` 在 UI 和 `leaderstats` 中对外展示为 `Cash`
- 用 `Cash` 升级本局四项 run 属性
- 冲更高 streak
- 同桌玩家能感到彼此存在，但不走强社交 / 大厅 simulator 路线
- 桌面只保留低噪音的他人 Flip、streak、全桌高光反馈

这份仓库里仍保留很多旧 simulator/战斗项目遗留目录，所以不要按“目录里有什么”理解项目，而要按下面两条判断：

1. `src/ReplicatedStorage/Systems/SystemMgr.lua` 里当前注册了哪些系统
2. 当前启动链真正会 require 哪些脚本

---

## 3. 新窗口最容易被误导的地方

先记住这些事实：

- `default.project.json` 当前项目名是 `Flip A Coin`
- `src/ReplicatedStorage/Systems` 下很多系统目录目前没有启用
- `src/ReplicatedStorage/Systems/SystemMgr Fail.lua` 是旧版本，不是当前入口
- `BaseSystem.lua` 是新基类尝试，但当前活跃系统大多仍是手写风格
- `analytics.server.lua` 整个文件仍是注释状态；当前主线埋点走已注册的 `AnalyticsSystem` + Roblox `AnalyticsService`
- `Excels/` 和大部分 `ExcelConfig/` 更像数据工具或旧数据沉淀，不等于都在当前玩法链路里生效

结论：

- 当前项目是“旧框架 + 新玩法主线”
- 理解项目时，先认主线，再认遗留

---

## 4. 仓库结构与职责

### 4.1 顶层目录

```text
FlipACoin
├─ src
│  ├─ ReplicatedFirst
│  ├─ ReplicatedStorage
│  │  ├─ Systems
│  │  ├─ configs
│  │  ├─ ExcelConfig
│  │  └─ modules
│  ├─ ServerScriptService
│  ├─ ServerStorage
│  ├─ StarterGui
│  └─ StarterPlayer
├─ Packages
├─ Excels
├─ docs
├─ windowsSettings
└─ default.project.json
```

### 4.2 这些目录今天各自干什么

- `src/ReplicatedStorage/Systems`
  - 当前运行时系统主目录
  - 双端入口、Remote 桥接、系统生命周期都围绕这里
- `src/ReplicatedStorage/configs`
  - 全局配置、数据 key、默认存档、调试存档
- `src/ReplicatedStorage/modules`
  - 通用工具模块
  - 当前最常用的是 `ScheduleModule`、`Util`、`TableModule`
- `src/ReplicatedStorage/ExcelConfig`
  - 当前明确仍在主链路使用的是 `PlayerLevel.lua`
  - 由 `PlayerSystem/Presets.lua` 读取等级表
- `src/ServerStorage/modules`
  - 服务端数据层、排行榜、全局数据等私有模块
- `src/ServerStorage/classes`
  - `PlayerServerClass` 服务端玩家包装层
- `src/ServerScriptService`
  - 服务端启动入口和少量非系统脚本
- `src/StarterGui/Main`
  - 当前主 UI 容器和 `uiController`
- `src/StarterPlayer`
  - 客户端启动脚本
- `src/ReplicatedFirst`
  - 最早执行的加载/入场体验
- `Excels`
  - 表格和导表脚本，偏离线工具，不是直接运行时入口

---

## 5. Rojo 映射与真实启动链

### 5.1 `default.project.json`

当前 DataModel 映射：

- `src/ReplicatedFirst` -> `ReplicatedFirst`
- `src/ReplicatedStorage` -> `ReplicatedStorage`
- `src/ServerScriptService` -> `ServerScriptService`
- `src/StarterPlayer` -> `StarterPlayer`
- `src/StarterGui` -> `StarterGui`
- `src/ServerStorage` -> `ServerStorage`
- `Packages` -> `ReplicatedStorage.Packages`

### 5.2 客户端启动链

最早阶段：

- `src/ReplicatedFirst/Loading.client.lua`
  - 移除默认 Loading Screen
  - 把 `ReplicatedFirst.LoadingScreen` 作为模板 clone 到 `PlayerGui`，并由 `Loading.client.lua` 直接启动 clone 内的 `Loader`
  - 这是最早可见的加载体验：全屏 Coin Flip 主题硬币上抛翻面动画、首发相关图片资源预加载、时间驱动的虚拟横向进度条、50% 后可点击 Skip，满足最短展示时间并完成预加载后淡出销毁，或到最长展示时间强制淡出
  - `ReplicatedFirst.RobStar` 仍可作为旧资源保留，但不再接入当前启动链

玩家脚本阶段：

- `src/StarterPlayer/StarterPlayerScripts/client.client.lua`
  - `require(Replicated.Systems.SystemMgr)`
  - 启动 `Modules/FirstPersonCamera.lua`
  - 然后 `SystemMgr.Start()`
  - 注意：`FirstPersonCamera.lua` 是旧文件名；当前首发语义是“两态第一人称相机”，不是固定封闭第一人称

主 UI 阶段：

- `src/StarterGui/Main/uiClient.client.lua`
  - 关闭默认背包
  - 做手柄适配；少量触屏样式兼容仍留存但不是当前目标平台
  - 将 `Main.DisplayOrder` 提高，避免引擎 / legacy 覆盖层挡住主 UI 点击
  - 隐藏当前主线不用的 legacy `OpeningUI.Frame`、`Notifications.TipFrame`，并禁用 `Main.Frames.noUse` 下旧 UI 的交互，避免它们覆盖主 UI hit test
  - 把主界面的按钮统一绑到 `uiController`
  - 关闭默认重置按钮

结论：

- 客户端主逻辑不是从某个单独 UI 系统开始，而是从 `SystemMgr.Start()` 开始拉起各系统

### 5.3 服务端启动链

服务端入口：

- `src/ServerScriptService/server.server.lua`

启动顺序：

1. `require(Replicated.Systems.SystemMgr)`
2. `SystemMgr.Start()`
3. `GlobalDataModule.Init()`
4. `BillboardManager.initBillboard()`
5. `ScheduleModule.AddSchedule(60, ...)` 每分钟刷新排行榜展示并保存在线玩家 `wins` 排行数据

注意：

- `SystemMgr.Start()` 会在服务端内部延迟 require `DataManager` 与 `PlayerServerClass`
- `GlobalDataModule` 和排行榜逻辑不属于 `Systems` 主框架，但确实在当前服端启动时执行

---

## 6. `SystemMgr.lua` 是运行时真相

当前最重要的架构文件：

- `src/ReplicatedStorage/Systems/SystemMgr.lua`

### 6.1 当前真正启用的系统

以 `systems = { ... }` 当前注册表为准，活跃系统是：

- `AnimateSystem`
- `AnalyticsSystem`
- `AnnouncementSystem`
- `BuffSystem`
- `CharacterSystem`
- `CoinFlipSystem`
- `EcoSystem`
- `EffectSystem`
- `FakePlayerSystem`
- `GuiSystem`
- `MusicSystem`
- `PlayerSystem`
- `PotionSystem`
- `RebirthSystem`
- `SettingSystem`
- `TableSeatSystem`
- `DecorationSystem`

没有在这里注册的系统，即使目录还在，也默认不参与运行时主链路。

当前主线不使用 Roblox Team 分队；Studio 中不保留 legacy `red / blue / white` Team 实例，避免默认玩家列表按队伍分组显示。

### 6.2 当前加载顺序

`LoadOrder` 里显式优先加载：

1. `PlayerSystem`
2. `CharacterSystem`

其余已注册系统随后加载。

所以新功能如果依赖：

- `ClientData` 初始化
- 头顶 UI 模板挂载

优先假设它们由 `PlayerSystem` 和 `CharacterSystem` 先铺底。

### 6.3 桥接机制

`SystemMgr` 会自动给系统生成这些代理：

- 服务端：
  - `self.Client:Method(...)`
  - `self.AllClients:Method(...)`
- 客户端：
  - `self.Server:Method(...)`

也就是说，项目通常不是手写一堆 RemoteEvent，而是靠系统函数自动桥接。

当前还要额外记住：

- 运行时桥接实例现在统一放在 `ReplicatedStorage.Systems.SystemMgrRuntime`
- 不要再假设 `RemoteEvent / UnreliableRemoteEvent` 会直接挂在 `SystemMgr.lua` 这个 `ModuleScript` 下面
- 这样做是为了避免 Studio Play 补测时客户端卡在 `WaitForChild("RemoteEvent")`

### 6.4 `whiteList` 的真实语义

`whiteList` 不是“允许远端调用”的名单，实际含义相反：

- 被加入 `whiteList` 的函数不会自动桥接
- 若远端尝试调用白名单函数，`SystemMgr` 会拦截并警告
- 白名单通常用于：
  - 系统内部方法
  - 服务端权威方法
  - 不希望暴露给另一端的逻辑

### 6.5 生命周期管理

`SystemMgr.Start()` 在服务端会统一处理：

- `PlayerAdded`
- `PlayerRemoving`

并且 `PlayerRemoving` 顺序是当前项目的重要约定：

1. 先跑所有系统的 `PlayerRemoving`
2. 再 `DataManager:ReleaseProfile(player)`
3. 最后 `PlayerServerClass.RemoveIns(player)`

这个顺序保证：

- 系统清理时玩家数据仍可写
- Profile 释放前可以做最后同步/结算

### 6.6 安全与兼容处理

`SystemMgr` 里还有几条对协作很重要：

- 远端调用会检查玩家是否还在 `Players` 中
- 未加载系统会返回安全代理并警告，而不是直接炸掉
- 客户端收到 Remote 后，如果目标系统还没 `IsLoaded`，会等待对应 `IsLoaded` 标记

---

## 7. 活跃系统职责图

### 7.1 `PlayerSystem`

文件：

- `src/ReplicatedStorage/Systems/PlayerSystem/init.lua`
- `src/ReplicatedStorage/Systems/PlayerSystem/Presets.lua`

当前职责：

- 服务端在 `PlayerAdded` 时把整份玩家数据发给客户端
- 客户端初始化 `ClientData`
- 创建 `leaderstats`
- 当前把 `wins` 展示成 `Cash`
- 负责刷新头顶 UI 信息
- 等级经验仍保留旧框架能力，等级表来自 `ExcelConfig/PlayerLevel.lua`

重要事实：

- `PlayerSystem` 现在既承担“数据镜像初始化”，也承担“Cash 和头顶展示刷新”
- 头顶 UI 文案已经被改造成服务当前玩法
- 玩家 / 假玩家头顶第一行显示当前 `Streak N`，不显示座位号；下一行通常显示当前装备 Coin，首局引导未完成时会切到引导动作文案
- 但内部仍残留一些旧字段/旧逻辑痕迹，例如 `Rebirth` 路径和某些旧命名

### 7.2 `CharacterSystem`

文件：

- `src/ReplicatedStorage/Systems/CharacterSystem/init.lua`

当前职责：

- 玩家角色生成后挂载 `StarterGui.Templates.onPlayerHead`
- 关闭 Roblox 默认角色显示名
- 设置玩家碰撞组
- 角色出生/重生后刷新头顶展示

对新窗口最重要的理解：

- “头顶信息为什么会出现”不是 `PlayerSystem` 单独完成的，而是 `CharacterSystem` 负责挂模板，`PlayerSystem` 负责填内容

### 7.3 `TableSeatSystem`

文件：

- `src/ReplicatedStorage/Systems/TableSeatSystem/init.lua`
- `src/ReplicatedStorage/Systems/TableSeatSystem/Presets.lua`

当前职责：

- 维护唯一 `CoinFlipTable` 的 `8` 个座位
- 玩家进服 / 重生后自动分配空座位并坐下；调用 `Seat:Sit()` 前会确认 Humanoid 仍活着且角色仍在 Workspace，避免重生 / 离场竞态把无效 Humanoid 传给座位
- 当前同桌有人数变化时，已入座玩家的座位世界位置按当前活跃人数均分 `360` 度并 tween 到桌边；seat id / ownership / UI label 仍沿用原来的 `Seat01` 到 `Seat08`
- 暂时禁止主动离座、换座、切桌
- 满桌时进入等待 / 降级处理
- 同步座位状态给客户端
- 为同桌轻量桌面反馈提供座位状态
- 通知 `CoinFlipSystem` 当前座位态变化
- 通知 `DecorationSystem` 在入座 / 离座时刷新或清理玩家装饰模型
- 支持 `FakePlayerSystem` 提供的 fake actor 占座；真实玩家需要座位时会优先释放假玩家座位
- `seatDisplayEntries` 会把假玩家输出为 `isFake = true` 的 occupied entry，客户端硬币 idle/flip 表现可复用同一座位快照
- `CoinFlipSystem:PlayerAdded()` 会在进服后做数次延迟 run-state 重同步，用来兜住自动入座完成晚于 CoinFlip 初始同步的时序，确保 HUD 和桌面硬币最终进入 seated 状态

依赖的场景约定：

- `Workspace.CoinFlipTable`
- 其下 `Seats` 文件夹
- 每个 `Seat` 需要有 `SeatId` 属性或用座位名作为 seat id，目标是 `Seat01` 到 `Seat08`

一个非常重要的当前实现细节：

- 旧 `ProximityPrompt`、`RequestStand`、AFK 踢座、`SeatInfoBillboard`、featured seat 逻辑仍可能残留在代码里
- 新方向下这些都不是首发主路径：玩家不需要找座位、不需要离座按钮、不需要切桌
- `GetAudiencePlayers()` 现在直接返回 `Players:GetPlayers()`；在单桌 `8` 人服务器口径下可以暂时接受，但语义应理解为“全桌 / 全服同一批玩家”
- `seatDisplayEntries` 旧字段可能仍会附带：
  - `isFeatured`
  - `featuredBadgeText`
  - `featuredBadgeColor`
  - `featuredDetailText`
- `buildSeatState()` 顶层还会额外给客户端：
  - `featuredSeatId`
  - `featuredSeatPlayerName`
  - `featuredSeatLabel`
  - `featuredSeatStreak`
  - `featuredSeatReason`
- 这些旧字段后续不要继续扩展成复杂观战系统；若保留，只应收敛为低噪音桌面高光，例如当前最高 streak 座位轻微发光

### 7.3a `DecorationSystem`

文件：

- `src/ReplicatedStorage/Systems/DecorationSystem/init.lua`
- `src/ReplicatedStorage/Systems/DecorationSystem/Presets.lua`
- `src/ReplicatedStorage/Systems/DecorationSystem/Assets/TableDecoration`
- `src/ReplicatedStorage/Systems/DecorationSystem/Assets/Chairs`

当前职责：

- 服务端通过 `EcoSystem:GetLoadoutState()` 读取已归一化的 `equippedDeskSetup`，再克隆座位桌搭模型到 `Workspace.CoinFlipTable.Assets.DecorationsRuntime`
- 每个座位运行时模型命名为 `{rawSeatId}Decoration`
- 服务端通过同一份归一化 loadout 读取 `equippedChair`，再克隆座位椅子模型到同一 `DecorationsRuntime`
- 每个座位椅子运行时模型命名为 `{rawSeatId}Chair`
- 桌搭模型按座位显示，不是全桌共享装饰
- `EcoSystem` 在 Desk Setup / Chair 购买或装备成功后刷新该玩家座位装饰；旧 / 无效 Desk Setup 或 Chair id 会先回落到默认 `"1"` 并补 owned，避免旧存档在入座刷新时生成空装饰
- `TableSeatSystem` 在入座、离座、离服时刷新或清理该玩家座位装饰
- 假玩家装饰通过 `RefreshFakeActorDecoration()` / `ClearFakeActorDecoration()` 读取 fake actor 的随机 loadout，不读写 profile
- 系统名保持通用，因为后续玩家凳子等可视装饰也应由该系统承接

资产约定：

- 桌搭资产长期应放在 `ReplicatedStorage.Systems.DecorationSystem.Assets.TableDecoration`
- 椅子资产长期应放在 `ReplicatedStorage.Systems.DecorationSystem.Assets.Chairs`
- 如果运行时仍存在 `Workspace.TableDecoration`，服务端启动时会迁移到 `DecorationSystem.Assets.TableDecoration`
- Desk Setup 商品 id 为字符串 `"1"`–`"8"`（见 `EcoSystem/Presets.lua` 的 `GrowthShopItems.desk`），`TableDecoration` 下子 Model 名与之相同
- Chair 商品 id 为字符串 `"1"`–`"11"`（见 `EcoSystem/Presets.lua` 的 `GrowthShopItems.chair`），`Chairs` 下子 Model 名与之相同
- 如果 `Workspace.TableDecoration` 只有一整套模型而不是同名商品子模型，会作为 `Default` 资产供所有 Desk Setup 临时复用
- 摆放优先读取 `Workspace.CoinFlipTable.Attachments/<SeatId>Decoration`、`<SeatId>DecorationAnchor`、`<SeatId>DeskSetup`，再回退到 `<SeatId>Marker` 或桌面位置
- 动态座位布局激活时，桌搭和椅子会优先按 `TableSeatSystem:GetSeatTargetCFrame()` 推导目标位并 tween；动态桌搭位于座位前方偏玩家左侧，给正前方硬币落点让位；静态 anchor 仍作为 fallback
- 当前 Studio 资源使用 `<SeatId>DecorationAnchor` 作为每个座位的桌搭定位块，位于玩家左前方桌面
- 当前 Studio 资源使用 `<SeatId>ChairAnchor` 作为每个座位椅子的定位块，位于玩家座位锚点后方
- 摆放后会按模型实际包围角点沿桌面法线抬升，让桌搭最低点落在 `TableTop` 表面上方一点，避免沉入桌面
- 缺少精确商品模型但有 `Default` 时不报错；精确外观后续通过补同名子模型覆盖

### 7.3b `FakePlayerSystem`

文件：

- `src/ReplicatedStorage/Systems/FakePlayerSystem/init.lua`
- `src/ReplicatedStorage/Systems/FakePlayerSystem/Presets.lua`

当前职责：

- 服务端低人数补位：服务器已有 `1` 到 `2` 名真实玩家时维持 `1` 到 `3` 个假玩家入座，真实玩家变多或需要座位时释放假玩家；空服不预生成模型
- 假玩家不是 Roblox `Player`，只是不写存档的服务端 actor；不创建 leaderstats，不进入排行榜，不写真实 analytics
- 假玩家模型从 `ReplicatedStorage.Systems.PlayerSystem.Assets.Rig` 克隆，随机使用 `PlayerPresets.FakeUserIds` 的 avatar description 和 `PlayerPresets.FakeNames` 的显示名
- 假玩家随机装备 Coin / Desk Setup / Chair，并在创建时随机获得 `0` 到 `5` 级表演用 `biasLevel` 和 `1` 到 `3` 级表演用 `coinCountLevel`；模型放在 `Workspace.CoinFlipTable.Assets.FakePlayersRuntime`
- 假玩家人数目标只在 `10` 到 `20` 分钟级别随机刷新，真实玩家需要座位时仍会立即让座；不会通过短 tick 频繁进出
- 假玩家 director 防重入，并在 avatar / rig / head GUI 准备期间用 pending create 计入目标人数；准备期间 rig 会先 parent 到高空 runtime staging 位置再应用 avatar description，避免未 parent rig 丢外观且不触发 `FallenPartsDestroyHeight` 清理，同时不提前入座；开局补位批量抑制 fake 座位广播，全部处理完后只刷新一次座位状态，避免真实玩家随 `1`、`2`、`3` 个 fake 逐个出现而连续重排
- 假玩家接近真实玩家节奏持续 Flip，只有小概率在 Flip 后暂停几秒；每个 fake 的下一次动作时间独立随机，因此通常错开，少量情况下会一起 Flip
- 假玩家非 Flip 动作主要模拟真实玩家相机移动：左右短摆表示“摇头”，上下短摆表示“点头”；不再持续盯着真实玩家；当前 rig 使用 `AnimationConstraint` 时写 `Transform`，旧 `Motor6D` rig 仍写 `C0`
- 假玩家 Flip 调 `CoinFlipSystem:RequestFakeFlip()`，和真实玩家共享 actor 级结算逻辑，但只更新 fake actor 内存状态

### 7.4 `CoinFlipSystem`

文件：

- `src/ReplicatedStorage/Systems/CoinFlipSystem/init.lua`
- `src/ReplicatedStorage/Systems/CoinFlipSystem/Modules/Onboarding.lua`
- `src/ReplicatedStorage/Systems/CoinFlipSystem/Presets.lua`
- `src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua`

这是当前首发主玩法系统。

服务端当前负责：

- 检查玩家是否已入座
- 处理 `RequestFlip`
- 处理 `RequestFakeFlip`，让假玩家复用同一套 actor flip 结算、结果 payload、best-streak / streak / combo milestone 优先级和桌面广播
- 按 `GameConfig.FlipACoin` 计算正面概率、每轮金币数、成功阈值、奖励、速度
- 从 `runData.coinCountLevel` 派生本轮 `coinCount`：`0 -> 1`、`1 -> 2`、`2 -> 3`、`3 -> 4`、`4+ -> 5`；`coinCountLevel` 由 Rebirth 永久升级 `Coin Spread` 写入本局 baseline，`Value` 只影响每个 Heads 的 Cash 倍率
- 每轮独立 roll `coinResults`，payload 会带 `coinCount / headsCount / tailsCount / roundSuccess / successThreshold / perfect / comboKey / comboTier / comboName / comboMultiplier`；高价值组合还会带 `comboMilestone` 供落地弱反馈使用；旧 `result` 字段继续兼容，成功轮为 `"Heads"`，失败轮为 `"Tails"`
- `currentStreak` 当前语义是 `Round Streak`：连续多少轮达到成功阈值；多金币 Heads 数不会逐枚增加 streak
- 真实玩家有服务端内存级 `BadLuckPity`：连续失败达到阈值后，下一轮 roll 获得隐藏正面率加成；成功轮清零，失败轮递增，不写持久化、不显示 UI，也不改变 round streak 成败阈值
- 从 `EcoSystem` 读取当前 Coin / Desk Setup / Chair 加成，用于修正正面概率、Cash 倍率和 Edge Stand 触发率
- 真实玩家额外叠加 `BuffSystem:GetWinsBoost()` 到 Cash multiplier；`cash2x` 只影响 Cash 奖励，不改变 Heads 概率、streak 判定或 flip interval
- 写入 `runData`
- 维护首局 `coinFlipOnboarding` 引导状态
- 累积 `wins / bestStreak / lifetimeFlips / lifetimeHeads / lifetimeCashEarned`；`lifetimeHeads` 按本轮 `headsCount` 增加，真实玩家的 `bestStreak` 写入存档，假玩家只维护内存 `bestStreak`
- 刷新 `leaderstats` 与头顶 UI
- 广播本次 flip 给同桌玩家，用于低噪音桌面反馈
- 假玩家 flip 只广播 observed payload 和更新 fake run state，不写 `wins / lifetime* / onboarding / analytics`，也不读取 potion / buff
- 客户端收到假玩家 `ObservedFlip` 时会仅在本机临时驱动该 fake Rig 的头部看向硬币，复用真实玩家 Flip 期间看硬币的表现意图，但不改变真实玩家相机；向上 pitch 使用较低上限，避免抛硬币阶段过度抬头；当前 rig 使用 `AnimationConstraint.Transform`，旧 `Motor6D` rig 使用 `C0`
- 驱动 best-streak / streak / combo 播报与落地庆祝；同一次 flip 同时命中新纪录和普通 milestone 时只播放 `bestStreak`，Perfect Five / Perfect 这类高阶 combo 高于普通 streak milestone，但不盖过 `bestStreak`
- 处理升级购买
- 编排 `SyncPlayerState()`，把 HUD 状态同步给自己，同时把 loadout / rebirth 状态推给对应系统 UI

客户端当前负责：

- 显示 Flip HUD
- 隐藏旧 `CoinFlipOnboarding` 面板；使用 Studio-owned `GuidePrompt` + `uiController.SetGuideButton()` 轻强制高亮当前引导目标
- 响应式布局
- 让玩家面前的 `FLIP` 主按钮足够明确
- 展示 Cash、streak、chance、speed、四项升级
- 提供 Auto Flip 切换：客户端按当前 flip 间隔复用同一 `RequestFlip` 入口循环请求，服务端仍负责座位和冷却校验
- 优先用 Input Action System 建 `CoinFlipGameplayInputContext`：`FlipCoin = Space / ButtonR2`、`ToggleAutoFlip = ButtonY`；打开 Shop / Inventory / Rebirth 时禁用 gameplay context。Input Action 实例不可用时回退到既有 `ContextActionService`
- 展示同桌玩家的轻量状态 / streak / flip 结果
- 请求 `EffectSystem` 播放 coin flip 可视表现，并在落地回调里更新结果文案；结果文案会对 Perfect Five / Perfect 组合给更明确的一行反馈，但不新增 HUD prefab

关键玩法数据：

- 本局成长写入 `dataKey.runData`
- 重生点复用 `dataKey.fateShards`，UI 文案显示为 Rebirth Points
- Coin 装配写入 `equippedCoin / ownedCoins`
- Desk Setup 装配写入 `equippedDeskSetup / ownedDeskSetups`
- Chair 装配写入 `equippedChair / ownedChairs`
- 永久重生升级写入 `rebirthTree`
- 装备 Coin 的外观用于每座位持久桌面硬币；idle 时硬币留在桌面，单金币 flip 时同一个实例垂直抛起并落回桌面，多金币 flip 时复用持久硬币作为主硬币并克隆短生命周期 coin / shadow / pulse 来显示其余硬币
- 四项升级：
  - `valueLevel`
  - `comboLevel`
  - `speedLevel`
  - `biasLevel`

当前玩法核心配置都集中在：

- `GameConfig.FlipACoin`
- `CoinFlipSystem/Presets.lua`
- `EcoSystem/Presets.lua`
- `RebirthSystem/Presets.lua`
- `EffectSystem/Presets.lua`

当前首发成长配置按职责拆分：

- `EcoSystem/Presets.lua`：首发 Coin / Desk Setup / Chair 商品、价格、稀有度 / 角色、Cash 倍率、luck 加成，以及当前 Lucky Coin 词条小步的 Edge Stand chance / Perfect reward / Tails reroll 加成；FlipACoin Developer Product / Game Pass 已配置 id 与付费效果配置
- `RebirthSystem/Presets.lua`：重生最低 Cash、Cash 到点数换算、单次点数上限、重生后 Cash，以及当前 Rebirth 面板启用的 `Coin Spread / Chain Start / Quick Start / Lucky Start` 四个永久升级；重生次数本身不再自动给起始 Luck，`Coin Spread` 只提高多 Coin 数量，不再顺带提高起始 Value，首级保持 `1 RP`，后续按 `3x` 成本增长且最高 `4` 级。Rebirth 执行门槛和每点 RP 所需 Cash 会按当前 rebirth 次数轻量递增，避免永久升级叠加后重生节奏越来越短。
- `EffectSystem/Presets.lua`：桌面硬币飞行、水平轴翻面、多金币扇形落点角度、落地随机平铺朝向收敛、自己 / 他人落地脉冲、落地短促粒子 burst、streak ring、milestone fallback 和上次结果保留表现

硬币资产约定：

- 硬币外观资产放在 `ReplicatedStorage.Systems.CoinFlipSystem.Assets.Coins`
- 资产子模型 / Part 名称与 Coin 商品 id 完全一致：`coin1` 到 `coin10`
- 玩家默认装备 `coin1`，界面展示名为 `Copper R Coin`
- `EffectSystem` 支持 `Model` 或 `BasePart` 硬币资产；Model 资产以 Studio-authored `PrimaryPart` 作为 pivot / 相机跟随 focus，缺少精确资产时回退 `CoinVisual.Coin` 并警告
- `EffectSystem` 在动态座位布局下按当前 `TableSeatSystem:GetSeatTargetCFrame()` 推导硬币落点，让 fake player / 真实玩家当前座位、桌搭和硬币跟随同一套动态排位；单金币动态硬币落点位于座位正前方，不带左右偏移。多金币视觉会以玩家到中心落点的线段为中轴，在桌面平面上按 `MultiCoinFanAngleStep = 13° / MultiCoinFanMaxAngle = 30°` 旋转出左右对称的扇形落点，并按 coin 数对多 coin 模型做轻微临时缩放以减少结算重叠。没有动态座位目标时才读取 `Workspace.CoinFlipTable.Attachments/<SeatId>CoinLandingAnchor`，再回退到 `EffectSystem/Presets.lua` 的 `LandingRadius`，当前默认半径为 `5.4`
- 当前 Studio 资源使用 `<SeatId>CoinLandingAnchor` 作为每个座位的静态 fallback 硬币落点定位块，位于玩家侧且在桌搭锚点相反侧，避免 Coin 与 Desk Setup 重合
- Flip 落点按硬币最终姿态的真实包围角点和 `TableTop` 表面法线计算；落地高度来自一次桌面 raycast 命中点加一次 bounds lift，不能再用固定 `coin.Size.X * 0.5` 或重复叠加 lift
- Flip 落地时除程序化 pulse 外，会从 Studio-owned `EffectSystem.Assets.coinLandingBurst` 克隆短促粒子 burst；Heads 偏金色，Tails 偏橙红，缺失该资产时静默跳过。Burst anchor 会挂到当前落地的硬币对象下并焊到该 Coin visual 的 focus part / PrimaryPart / Part，跟随对应 `CoinModel` 生命周期；临时 burst holder 带 `IgnoreCoinBounds`，避免干扰下一次落点 bounds lift。
- 每次 Flip 开始时决定该次落桌的随机桌面 yaw；空中翻转只绕水平轴旋转，接近桌面时平滑收敛到 Heads / Tails 与最终平铺朝向，避免硬币落桌后再突兀拧转
- 每个座位的持久硬币记录上一轮落地结果和桌面随机 yaw；seat state 刷新、idle 重摆或换装后仍展示上一轮 Heads / Tails 和落地方向，不重置成默认正面
- Phase 3 世界多金币视觉已上线：`CoinFlipSystem/ui.lua` 把 `coinCount / coinResults` 传给 `EffectSystem:PlayCoinFlipVisual()`；`coinCount > 1` 时本地显示多枚硬币扇形抛出，落地后多枚硬币会继续留在桌面上，直到该座位下一次 Flip、隐藏或换装清理，让玩家看清每枚 coin 的 Heads / Tails 结果。首次 `Coin Spread` 从单币升到多币时，HUD 会用 Studio-authored `GuidePrompt.UnlockBanner` 做解锁提示，下一次多金币 Flip 会用 `FirstMultiCoinBanner` 和 `EffectSystem.Assets.multiCoinReveal` 做一次性首秀。
- Phase 0 正反馈调参后，`GameConfig.FlipACoin` 当前关键数值为：`BaseHeadsChance = 0.30`、`BaseReward = 10`、`BaseTailsReward = 2`、`ValueGrowth = 1.28`、`ComboBaseStep = 0.25`、`ComboStepPerLevel = 0.06`；Phase 1 新增 `CoinCountByLevel`、`SuccessThresholdByCoinCount`、`ComboMultiplierByHeadsCount` 和 `ComboNamesByHeadsCount`；多金币数量现由 Rebirth `Coin Spread` 控制。
- 多金币奖励当前规则：成功轮使用本轮 Heads 基础奖励乘以 round streak 倍率和 heads-count combo 倍率，combo 倍率表为 `1H = 1.00`、`2H = 1.20`、`3H = 1.75`、`4H = 2.60`、`5H = 4.00`；失败但 `headsCount > 0` 时发放 Heads 基础奖励并重置 streak；全 Tails 时按 `BaseTailsReward * tailsCount * premiumCoinMultiplier` 发放保底。玩家可见 combo 名称为 Heads / Pair / Triple / Four Heads / Perfect / Perfect Five；内部 `comboKey` 仍分为 `heads / pair / triple / fourHeads / perfect / jackpot`，其中 `jackpot` 是历史 schema key，不作为玩家文案。Triple 及以上可生成 combo milestone，Perfect Five 才发全桌文字通知。`TableJackpot` 小步已接入但对玩家显示为 Table Bonus：真实玩家 `5/5 Heads` 时，服务端给同桌其他真实玩家各发 `$15` Cash 和轻 notification，fake player 不触发共享奖励，不新增 UI / 资产 / 持久字段；触发者 ResultLabel 会在 Perfect Five 文案后追加本轮 Table bonus。`EdgeStand` 小步已接入：真实玩家失败轮在连续失败压力下低概率触发，被选中 Tails coin 竖立落桌，当前 round streak 不清零并获得 `$8` bonus；该事件不把失败改成成功、不增加 streak、不写持久化，fake player 不触发。Lucky Coin trait 小步已接入：当前配置贡献者是高阶 Coin `coin7` 到 `coin10`，通过 `EcoPresets.BuildLoadoutBonuses()` 汇总 `edgeStandChanceBonus`、`perfectRewardMultiplierBonus` 与 `tailsRerollChance`；`edgeStandChanceBonus` 叠加到 `Presets.GetEdgeStandChance()` 且仍受 `GameConfig.FlipACoin.EdgeStand.MaxChance` 上限约束；`perfectRewardMultiplierBonus` 只在 `comboKey == "perfect"` 或 `"jackpot"` 的成功轮提高奖励；`tailsRerollChance` 在服务端 outcome 构建阶段每轮最多重掷 1 个 Tails 一次，重掷后的最终结果再参与 round success、reward、Table Bonus 和 Edge Stand 判断。Lucky Coin 词条不新增 UI / 资产 / 持久字段，也不改变 round streak 语义。
- 新档默认 `wins = 9`（UI 展示为 Cash）；首个 `Value` 升级成本是 `12`，`BaseTailsReward = 2`，所以完成 `2` 次 Flip 后即使全是 Tails 也能买第一次升级；老玩家现金不迁移
- `rebirth == 0` 且 Cash 未达到首个 rebirth 门槛的真实玩家有服务端隐形首局保护：实际 flip 正面率额外获得 `+7%`，连续 Tails 后每次再加 `+4%`，实际保护上限 `45%`；HUD `Chance` 仍显示不含该隐形保护的正常概率
- Phase 5 第一小步已上线 `BadLuckPity`：当前配置为 `FailureThreshold = 3`、`ChanceBonusStep = 0.05`、`MaxChanceBonus = 0.18`、`MaxHeadsChance = 0.55`。该补偿只影响服务端 roll 的隐藏正面率，payload 用 `pityActive / pityFailureStreak` 标记本轮是否吃到补偿，Analytics compact outcome 末尾追加 `pity / normal`
- Profile XP 已接入 Flip 主循环：真实玩家每次 Flip 后按 `GameConfig.FlipACoin.ProfileXp` 获得持久化 `exp / level` 进度，当前数值为 `BasePerFlip = 2`、`PerHead = 2`、`RoundSuccessBonus = 3`、`PerfectBonus = 4`、`JackpotBonus = 6`、`MaxPerFlip = 24`。`JackpotBonus` 是内部配置字段，对应玩家可见 Perfect Five。该成长层复用 `PlayerSystem:AddExp()` 和 `PlayerLevel` 升级表，不新增手机 UI、不影响 Cash、round streak、Rebirth 或 fake player 表演；Analytics 记录 `coinflip_profile_xp`。
- Flip 专属轻量每日目标已接入主循环，不启用旧 `DailySystem / QuestSystem`。真实玩家每日按服务器日自动重置 `dailyClaim.flipACoinGoals`，当前目标为 `Flip 10 times` 奖励 `$30`、`Flip 15 Heads` 奖励 `$60`、`Reach a 3 streak` 奖励 `$75`；达成即自动通过 `EcoSystem:AddResource()` 发 Cash、用 `GuiSystem:SetNotification()` 做轻提示，并记录 `coinflip_daily_goal_completed`。fake player 不推进每日目标。
- P3 首发核心埋点已补一层内存 session 追踪：真实玩家进服记录 `coinflip_session_start`，离服记录 `coinflip_session_end`，首次真实 Flip 记录 `coinflip_first_flip_latency`，并在单次会话达到 `10 / 25 / 50 / 100 / 250 / 500` 次 Flip 时记录 `coinflip_flip_count_milestone`。这层不新增 profile 字段，fake player 不参与。

当前额外要记住：

- 服务端维护 v4 首局引导链，状态写在 `guideData.coinFlipOnboarding`，漏斗仍写 `onboardingFunnelStep`。引导阶段为：
  - 首次 Flip：客户端高亮 `FLIP`，`GuidePrompt` 文案为 `Heads pay Cash. Streaks boost Cash rewards.`，不承诺固定 `2x`
  - 首次 Value 升级：第一次 Flip 后进入 `buyUpgrade`；Cash 不足时继续高亮 `FLIP` 并提示攒到 Value，Cash 足够时高亮 HUD 内实际 `ValueButton`，玩家点击该按钮完成步骤；目标固定为 `valueLevel`，但玩家手动先买任意其他 run upgrade 也会完成首次升级，避免卡住
  - 首次 Rebirth：未达到门槛时 `GuidePrompt` 继续高亮 `FLIP`，展示还差多少 Cash 以及首个 `1 RP` 的 `Coin Spread` 会让每次 Flip 多一枚 coin；当 `RebirthSystem` 判定 `canRebirth` 后，引导打开 Rebirth 面板并高亮 `ConfirmButton`
  - Coin 购买 / 装备：首次 Rebirth 后，Cash 足够购买第一枚未拥有非默认 Coin 时引导 Shop 的 Coin 页购买；购买后自动转到 Inventory 的 Coin 页并高亮对应 `EquipButton`
- 引导采用“持续到完成”的轻强制高亮；不恢复旧大 guide 面板，不发教学 / 建议类 toast。玩家手动打开与当前引导目标无关的 Shop / Inventory / Rebirth 面板时，会临时清理旧 HUD 高亮并保留普通面板遮罩，避免旧 `MaskFrame` 覆盖成长面板；关闭面板后再恢复当前步骤高亮。
- HUD `GuidePrompt` 会在引导刷新时显式提高自身和子级 `ZIndex`，保证文字显示在 guide `MaskFrame` 之上。
- 四个 Flip 属性升级按钮绑定 `uiController.SetOneLineTip()`：鼠标、触屏和 gamepad selection 都会显示一行说明。
- 桌面沉浸视角当前由 `StarterPlayerScripts/Modules/FirstPersonCamera.lua` 负责：
  - 平时是头部第一人称：镜头以 `Head.Position` 为基准，再叠加 `BODY_VIEW_CAMERA_OFFSET` 配置（当前略向角色正前方并下移），保留默认相机输入，所以玩家可自由转头且低头更容易看到身体
  - 客户端首次收到已入座 seat state 后只做一次初始对准，但会等 `LoadingScreen` 销毁且本地 `Humanoid.SeatPart` 存在后才消费该请求；对准时优先看向 `TableTop.TableCenterAttachment`，没有该 Attachment 时看向 `TableTop` 中心，并短暂把相机切到 `Scriptable` 以种入默认相机方向，随后回到 `Custom`；之后不再因 seated 事件反复重置玩家视角
  - 镜头相对 `HumanoidRootPart` 的左右转向被限制在 `-90° ~ 90°`，避免玩家坐在桌边时回头穿帮
  - `Head` 和配件本地透明，身体可见，玩家低头能看到自己身体
  - 自己手动 Flip 时由 `EffectSystem:PlayCoinFlipVisual()` 调 `FirstPersonCamera.FollowCoin()`，相机临时切到 `Scriptable` 并从头部视角看向硬币；`Auto:On` 连续 Flip 不接管相机
  - 硬币落下或视觉被清理后调 `ReturnToFirstPerson()`，回到可自由转向的第一人称
  - `FirstPersonCamera` 会采样本地相机 pitch / yaw，经 `CharacterSystem:HeadPoseChanged()` 走 unreliable 桥上报给服务端
  - 服务端只信任发送者本人，校验 / clamp / 限频后在 Heartbeat 平滑改该角色的 `Neck` 与可选 `Waist.C0`，利用 Character 复制让其他客户端和服务端都看到轻微摇头 / 点头
  - `StarterCharacterScripts/char.client.lua` 会拦截默认 `idle` 动画轨道，避免玩家长时间不动时自动播放默认 idle 摆动
  - 其他玩家的 `ObservedFlip()` 不触发相机接管，只播放桌面硬币表现
  - fake player 的 `ObservedFlip()` 会在本客户端临时驱动 fake Rig 的 `Neck` / 可选 `Waist` 看向该座位硬币 focus；向上 pitch 使用较低上限，避免抛硬币阶段过度抬头；`AnimationConstraint` rig 写 `Transform`，`Motor6D` rig 写 `C0`；这是纯本地表现，不新增服务端状态
  - 文件名仍沿用旧名，当前暂不重命名，避免扩大启动链改动
- Auto Flip 不使用持久化 `autoFlipUnlocked`，当前对所有玩家开放；离座、打开 Shop / Inventory / Rebirth 或手动切回 `Auto:Off` 会停止自动请求
- `SeatInfoBillboard`、`CoinFlipTableOverview`、`CoinFlipSpectatorFeed`、旧 `CoinFlipOnboarding` 面板、复杂 featured seat 表现都不再是首发主路径，当前代码级退场首版已把它们保持隐藏
- 但“弱社交”不等于完全无同桌反馈：保留或重做低噪音桌面信号，让玩家知道另外 7 个座位也在发生 Flip
- `PlayerSystem:UpdatePlayerHeadGui()` 现在也会在引导期间把头顶文案切到当前下一步动作
- 引导细状态写在 `guideData.coinFlipOnboarding`；v4 字段包括 `firstFlipDone / firstUpgradeDone / firstUpgradeKey / rebirthDone / coinPurchased / coinPurchasedItemId / coinEquipped / completed`
- 漏斗埋点仍继续沿用 `onboardingFunnelStep`
- 这两个字段现在是“引导状态”和“分析节点”两条线，不要再混写

### 7.4a `EcoSystem`

当前在 Flip A Coin 主线里负责：

- `wins` / Cash 的统一加减入口仍走 `EcoSystem:AddResource()`
- `RequestShopPurchase()` 处理 Coin / Desk Setup / Chair 购买，只写入 owned；已拥有商品在 Shop 只显示 `Owned`，装备切换与 Shop 解耦
- `RequestEquipItem()` 处理 Inventory 装备切换，不重复扣 Cash
- Shop 购买成功和 Inventory 装备成功后会通过 `GuiSystem:SetNotification()` 给本人短反馈；客户端 `EcoSystem/ui.lua` 仍按 `purchasedItem / equippedItem` 播放本地 `shopPurchase / equipItem` SFX
- `GetLoadoutState()` 同步 owned / equipped 数据给 Shop / Inventory UI
- `GetLoadoutBonuses()` 给 `CoinFlipSystem` 计算正面概率、Cash 倍率和 flip 间隔倍率；当前会合并 Coin / Desk / Chair 装备和已拥有的 FlipACoin gamepass 加成
- Desk Setup 装备成功后通知 `DecorationSystem` 刷新座位可视化
- `EcoSystem/ui.lua` 管理 `Frames.Shop / Boosts / Inventory`；Boosts 是独立付费面板，只展示 `Products.flipACoin` 和 `GamePasses`，不复用 Shop 的 Coin / Desk / Chair 侧栏
- `MarketplaceService.ProcessReceipt` 处理 `EcoPresets.Products.flipACoin` 下的 Developer Product：Cash 包、Rebirth Points 包、Apex 外观礼包和购买后立即使用的 `paidCash2x10m`
- `PromptGamePassPurchaseFinished` / 进服 ownership 检查处理 `EcoPresets.GamePasses` 下的 `vip / winsX2 / luckyCharm / quickFlip`；发放后统一记录 `coinflip_gamepass_granted`，`source` 为 `purchase` 或 `ownershipSync`
- `CoinFlipSystem` 全量状态同步会携带 `gamePasses / loadoutState / rebirthState`，确保付费发货后 Boosts、Inventory、Rebirth 与 HUD 刷新读同一份客户端数据
- Rewarded Ads 因 Roblox 新游戏 eligibility / DAU 要求移出首发范围；当前没有 `AdService` 路径、广告奖励 product 或广告 potion

当前 Coin / Desk / Chair 商品配置在 `EcoSystem/Presets.lua` 的 `GrowthShopItems`。FlipACoin 付费配置在同文件：

- `Products.flipACoin`：`cashPackSmall / cashPackMedium / cashPackLarge / rebirthShardSmall / rebirthShardLarge / apexLoadoutBundle / paidCash2x10m`，当前均已填入非 `0` product id
- `GamePasses`：`vip / winsX2 / luckyCharm / quickFlip`，当前均已填入非 `0` game pass id
- `GamePassEffects`：VIP 小幅 Cash / Luck 和外观解锁、`winsX2` 的 flip Cash 倍率、`luckyCharm` 的 Heads 概率加成、`quickFlip` 的 flip 间隔倍率

付费 id 为 `0` 时运行时 UI 会禁用未配置的购买按钮。当前 FlipACoin 首发付费 product / gamepass id 已填入，剩余工作是 Roblox 实际购买 prompt、receipt 发货和 UI / analytics 刷新验证。

### 7.4aa `PotionSystem` / `BuffSystem`

当前在 Flip A Coin 主线里负责：

- `PotionSystem` 复用持久字段 `potions`；`GrantAndUsePotion()` 统一执行“入库存 -> 立即扣库存使用 -> AddBuff -> 客户端同步”
- `BuffSystem` 复用持久字段 `equippedBuff`；同名 buff 重复使用时累加 duration，并重排服务端清理倒计时
- 当前 potion 只保留 Robux product 使用的 `paidCash2x10m`，映射到 `cash2x`
- `cash2x` 配置为 `boostType = wins`、`boost = 1`；`GetWinsBoost()` 从 `1` 起加，因此最终总倍率为 `2x`
- 旧 simulator 的 Quest progress 和 Store / Buffs UI 依赖不再接回主线；两个系统的客户端 `ui.lua` 只保留轻量同步占位

### 7.4b `RebirthSystem`

当前在 Flip A Coin 主线里负责：

- `RequestRebirth()`：按当前 Cash 计算 Rebirth Points，重置 Cash 与 `runData`，保留永久树；本局 Value / Combo / Speed / Luck 会回到新 run baseline
- `RequestRebirthUpgrade()`：消耗 `fateShards` 升级永久 `rebirthTree`
- `GetRebirthState()`：同步 Rebirth 面板需要的点数、预览和升级卡状态
- `BuildRunBaseline()` / `ApplyRunBaseline()`：把当前启用的永久升级应用到本局 `runData` baseline；重生次数本身不再自动给 Luck，`Coin Spread` 写入 `coinCountLevel`，`Chain Start / Quick Start / Lucky Start` 分别写入 `comboLevel / speedLevel / biasLevel`；Rebirth 后本局 stats 先清零再应用这些永久升级 baseline

旧 legacy rebirth tier 表仍保留在同一个 presets 文件里，但当前 Flip A Coin 主线使用 `RebirthPresets.FlipACoin` 配置。

### 7.4c `EffectSystem`

当前在 Flip A Coin 主线里负责：

- `PlayCoinFlipVisual()` 播放本地桌面硬币飞行、落地、阴影和 streak pulse；多金币 payload 会额外克隆短生命周期 coin / shadow / pulse 并按扇形落点播放；`edgeStand` payload 会让对应 coin 以竖立姿态 settle，并复用现有 highlight 做轻表现
- 每个座位维护一个持久硬币实例；换装会替换该实例，若换装发生在 flip 中则等动画落地后替换
- 单金币 flip 视觉为基于桌面落点的垂直抛掷；多金币 flip 视觉从玩家侧起点飞向扇形落点，扇形以玩家到中心落点的线段为中轴。空中只绕水平翻面轴旋转，落桌阶段收敛到最终 Heads / Tails 与随机平铺朝向
- 持久硬币 idle 显示上一轮 flip 结果和随机桌面 yaw，新入座 / 未翻过时默认显示 Heads
- 自己 flip 时接管并释放 `FirstPersonCamera`；装备硬币为 Model 时跟随该 Model 的 `PrimaryPart`
- 其他玩家 flip 时只播放桌面表现，不接管相机；观察者看到的 Heads / Tails 落地 pulse 使用更醒目的独立参数，Heads 更大更亮，Tails 更短促偏橙红
- 硬币落地后会播放 `EffectSystem.Assets.coinLandingBurst` 短促粒子 burst，作为现有落地 pulse 的小型金属/赌场风反馈
- 观察者看到他人 Heads streak 达到阈值时，会在落地 pulse 外追加第二层 streak ring，并按 streak 增大半径；`streak >= 4` 或 milestone 会给对应硬币 / 座位创建短生命周期 `Highlight`
- `PlayInsideEffects()` 使用 `SettingSystem:GetParticleRateFactor()` 决定粒子倍率
- `PlayStreakMilestone()` 按 `AnnouncementSystem/Presets.lua` 的 `BestStreakEffect`、`StreakEffects` 或 `ComboEffects` 配置，在硬币本地落地回调后通过 `MusicSystem` 播放 SFX、播放 `EffectSystem.Assets` VFX，并可选触发本地 camera shake；观察者分支会显式抑制他人 milestone 的 SFX 和 camera shake，只保留桌面 VFX / fallback pulse / highlight；如果 milestone VFX 资产缺失或类型无效，会 fallback 到程序化 streak pulse + `Highlight`
- `RefreshPersistentSeatCoins()` 也会按 seat-state snapshot 维护头顶热 streak spotlight：`entry.streak >= 5` 时从 `EffectSystem.Assets.hotStreakSpotlight` 克隆到真实玩家或假玩家的 `Head`，streak 失败、座位清空或角色消失时销毁
- 客户端监听鼠标 / 触屏点击场景射线，当前用 `InputObject.Position` 配合 `Camera:ScreenPointToRay()` 消化输入事件坐标，避免桌面鼠标和移动端触点与桌面命中点偏移；命中 `DecorationsRuntime` 下 `{SeatId}Decoration` / `{SeatId}FakeDecoration` 时只在本机按模型底部接触点为支点抖动桌搭并短暂高光。命中 `TableTop` 时本地立即播放 `tableKnock` SFX 和短生命周期小尺寸桌面 ripple，并通过 `EffectSystem:RequestTableReaction()` 让服务端确认玩家仍在座位上、按 `TableReactionCooldown = 0.55` 限频后广播给其他客户端；广播只带 `seatId / actorUserId`，各客户端按本地桌面和座位数据计算 ripple 落点，不写持久化状态。

### 7.4d `SettingSystem`

当前在 Flip A Coin 主线里负责：

- 进服补齐 `settingsData` 默认值，且只在字段为 `nil` 时补齐，不覆盖合法的 `false / 0`
- `ChangeSetting()` 仍同步 BGM / SFX 设置
- `GetSettingValue()` / `GetParticleRateFactor()` 给其他系统读取本地设置
- `Frames.Settings` 是 Studio-authored 主面板，当前只展示并绑定 BGM / SFX 两个 row；关闭按钮仍走 `Settings.X`，TopbarPlus `Settings` 入口只负责打开 / 关闭该 Frame

### 7.5 `AnnouncementSystem`

文件：

- `src/ReplicatedStorage/Systems/AnnouncementSystem/init.lua`
- `src/ReplicatedStorage/Systems/AnnouncementSystem/Presets.lua`
- `src/ReplicatedStorage/Systems/AnnouncementSystem/ui.lua`

当前职责：

- 当 `CoinFlipSystem` 出现正面且刷新足够高的 `bestStreak`、命中 `Presets.StreakEffects` 或触发高价值 combo 时，生成 celebration payload 和轻量播报；达到 best-streak 阈值时优先于普通 milestone，低 streak 新纪录只保留桌面 pulse / ring，不发全桌大通知
- 当前默认配置是：
  - `MinBestStreakAnnouncement = 5`
  - `BestStreakEffect`：`sfx = "bestStreak"`，`vfx = "bestStreak"`，不触发 camera shake
  - `3`：`sfx = "streak3"`，`vfx = "streak3"`，无 camera shake
  - `5`：`sfx = "streak5"`，`vfx = "streak5"`，无 camera shake
  - `10`：`sfx = "streak10"`，`vfx = "streak10"`，带 camera shake 参数
  - `20`：`sfx = "streak20"`，`vfx = "streak20"`，带 camera shake 参数
- `ComboEffects` 复用现有资源：`triple -> streak3`，`fourHeads / perfect -> streak5`，`jackpot -> bestStreak`；Perfect / Perfect Five 对本人带轻量 camera shake，Triple / Four Heads 只做落地 VFX/SFX payload，Perfect Five 额外 `announce = true` 走全桌低噪音文字通知；观察者播放 milestone 时会 suppress SFX 和 camera shake
- 客户端不再动态创建顶部 banner；当前通知只通过 `uiController.SetNotification` 做低噪音反馈，SFX / VFX / camera shake 由 `EffectSystem:PlayStreakMilestone()` 在硬币落地后播放

当前依赖关系：

- `CoinFlipSystem:RequestFlip()` / `RequestFakeFlip()` -> `AnnouncementSystem:BuildBestStreakPayload()` / `BuildStreakMilestonePayload()` / `BuildComboMilestonePayload()` / `HandleFlipResolved()`

### 7.5a `AnalyticsSystem`

文件：

- `src/ReplicatedStorage/Systems/AnalyticsSystem/init.lua`

当前职责：

- 作为 Roblox `AnalyticsService` 的服务端内部门面；绝大多数公开记录方法都在 `whiteList`，不暴露给客户端 remote。例外是 `ReportDeviceProfile()` 这类客户端只能上报自身低基数设备画像、且服务端会清洗字段的一次性入口。
- `coinflip_flip_resolved` 的三个自定义字段当前是：兼容 `result`、压缩 round outcome（形如 `c3_h2_success_s2_4_pair`，末尾带 combo key）、当前装备 Coin id
- Custom events 先按 `player + eventName + CustomField01/02/03` 在内存队列聚合同字段 value，再定时发送；不新增 batch size 字段，避免抬高字段组合基数
- 发送节奏按 Roblox 官方 `120 + 20 * CCU` / min AnalyticsService 全局限制留 `20%` 余量，每 `15` 秒 flush；`PlayerRemoving` 与关服会强制 flush pending bucket
- Creator Dashboard 里的 custom event `Count` 代表批次数；真实次数或总数看 `Sum value`，其中 reward / cost / duration 事件的 `Sum value` 保留原数值语义
- 维护每个真实玩家当服内存 session，用于记录会话开始/结束、首 Flip 延迟和当服 Flip 次数里程碑；该 session 在 `PlayerRemoving` 清理，不写入持久化数据
- 记录核心 Flip A Coin 玩法节点：
  - `coinflip_session_start`
  - `coinflip_session_end`
  - `coinflip_device_profile`
  - `coinflip_early_session_end`
  - `coinflip_first_seat_assigned_latency`
  - `coinflip_first_flip_latency`
  - `coinflip_first_auto_toggle`
  - `coinflip_first_run_upgrade`
  - `coinflip_first_growth_panel_open`
  - `coinflip_flip_count_milestone`
  - `coinflip_seat_assigned`
  - `coinflip_flip_resolved`
  - `coinflip_streak_milestone`
  - `coinflip_run_upgrade`
  - `coinflip_shop_purchase`
  - `coinflip_item_equip`
  - `coinflip_gamepass_granted`
  - `coinflip_potion_granted`
  - `coinflip_potion_used`
  - `coinflip_buff_active`
  - `coinflip_input_action`
  - `coinflip_profile_xp`
  - `coinflip_daily_goal_completed`
  - `coinflip_table_jackpot`
  - `coinflip_edge_stand`
  - `coinflip_rebirth`
  - `coinflip_rebirth_upgrade`
- 自定义字段只放低基数维度，例如 result、streak band、装备 id、商品 category、rarity、来源、cash band、device class、viewport band 和 input type
- 首局漏斗埋点只用当服内存 session 去重，不写持久字段：session 设备画像、前 `3` 分钟短会话结束、首次 seat assigned latency、首次 Flip latency、首次 Auto Toggle、首次 run upgrade、首次打开 `Shop / Inventory / Rebirth` 各记录一次；设备画像事件会带 `touch / keyboard / gamepad / hybrid` 设备分类、`small_portrait / phone_landscape / tablet / desktop` viewport 档位和最近输入类型；短会话结束事件会带设备分类、viewport 档位和 `joined_no_seat / seated_no_flip / flipped_no_upgrade / upgraded_run / opened_growth_panel` 进度阶段；growth panel 打开事件会带 panel、入口 source 和最近输入类型
- Cash 来源 / 消耗数量继续走 `EcoSystem:AddResource()` 中的 `LogEconomyEvent`；首局漏斗继续走 `PlayerServerClass:LogOnboarding()` 的 `LogOnboardingFunnelStepEvent`

### 7.6 `GuiSystem`

文件：

- `src/ReplicatedStorage/Systems/GuiSystem/init.lua`

当前职责很纯：

- 提供系统级通知入口
- 最终走到 `StarterGui/Main/uiController.lua` 的 `SetNotification()`

当别的系统只是想给玩家发提示时，优先走这里，不要直接绕开系统层去摸 UI。

### 7.7 `MusicSystem`

文件：

- `src/ReplicatedStorage/Systems/MusicSystem/init.lua`

当前职责：

- 播放 2D / 3D 音效
- 提供本地 SFX helper，Flip / Shop / Inventory / Rebirth / notification 等活跃 UI 音效统一经这里读取当前 `SoundService.SFX.Volume`
- 维护 BGM 淡入淡出
- 提供 `SetBgmVolume` / `SetSfxVolume`

当前注意点：

- 这个系统已经启用
- 它依赖 `SoundService` 下的分组和资源命名，以及 `workspace.BGSoundsFolder`
- 当前主玩法音效在 Studio-owned `SoundService.SFX`：`flipPress`、`coinToss`、`coinSpin`、`coinLand`、`headsWin`、`tailsLose`、`cashReward`、`bestStreak`、`streak3`、`streak5`、`streak7`、`streak10`、`streak20`、`shopPurchase`、`equipItem`、`rebirth`、`notification`、`tableKnock`
- 他人 / fake player 的 `ObservedFlip()` 保留 `coinToss` / `coinSpin` / `coinLand`，但不播放本地 `headsWin` / `tailsLose` / streak milestone SFX；自己的 flip 仍播放结算与奖励相关 SFX。
- UI 通用按钮仍使用 `SFX.hoverBtn` / `SFX.clickBtn`，BGM 使用 `SoundService.bgm`
- `MusicSystem` 仍会跳过空 `SoundId`，但当前 Studio 主线 SFX 已填入第一版候选 id；最终听感仍需人工试听确认

### 7.8 `AnimateSystem`

文件：

- `src/ReplicatedStorage/Systems/AnimateSystem/init.lua`

当前职责：

- 统一播放角色或模型动画
- 缓存 `AnimationTrack`
- 支持服务端和客户端播放

当前在首发主线里不是最核心，但它是共用底座，后续加庆祝动作、座位表现、角色动画时很可能会继续复用。

---

## 8. 当前真实主玩法调用链

### 8.1 玩家进入游戏

1. `DataManager` 在 `Players.PlayerAdded` 时加载 Profile
2. 成功后给玩家挂 `profileLoaded`
3. `SystemMgr.Start()` 里的 `HandlePlayerAdded()` 通过 `PlayerServerClass.GetIns(player, true)` 等待数据就绪
4. 各系统的 `PlayerAdded` 才开始真正执行

玩家“刚进服过一会儿才能上桌”的服务端硬等待主要在第 3 步：`PlayerServerClass:WaitForDataLoaded()` 最多等 `profileLoaded` `15` 秒；数据没准备好前 `TableSeatSystem:PlayerAdded()` 不会排自动入座。客户端视觉上还叠加 `ReplicatedFirst.LoadingScreen` 的首发图片预加载进度与淡出时间；玩家在进度达到 50% 后可以 Skip 提前进入。

### 8.2 玩家数据下发

1. `PlayerSystem:PlayerAdded()` 读取完整数据
2. 服务端通过系统桥接把数据发给客户端
3. 客户端 `ClientData.InitData(args.data)`
4. 客户端各系统 UI 再读取 `ClientData`

所以：

- 客户端大多数读数据场景都不是实时请求服务器
- 而是读 `ReplicatedStorage/Systems/ClientData.lua` 里的本地镜像

### 8.3 入座开始玩法

1. 玩家进服后由服务端自动选择唯一 `CoinFlipTable` 的空座位
2. `TableSeatSystem:RequestSit()` 占座并让 Humanoid 坐下
3. 座位状态广播给所有客户端
4. `CoinFlipSystem` 收到座位态后显示主玩法 HUD，并让玩家立即进入可 Flip 状态
5. 客户端 `requestFlip()` 只有在本地已有 `currentSeatId` 时才会发 `CoinFlipSystem.Server:RequestFlip()`；如果座位状态尚未同步，只显示等待座位文案，不进入本地 flip 等待 / 冷却态，避免玩家刚入座时被旧 seat state 锁住按钮

### 8.4 翻硬币结算

1. 客户端请求 `CoinFlipSystem.Server:RequestFlip()`
2. 服务端检查：
   - 玩家还在不在
   - 是否已入座
   - flip 冷却是否结束
3. 计算本轮 `coinResults / headsCount / roundSuccess / reward`
4. 更新 `wins` 与 `runData`；`currentStreak` 按 round success 增加或归零，`headsThisRun / lifetimeHeads` 按本轮 `headsCount` 累加
5. 刷新：
   - `leaderstats.Cash`
   - 头顶 UI
   - 座位 / 桌面轻量状态
6. 发回本人 HUD 结果
7. 发给其他玩家观察结果
8. 若达到阈值，驱动 `AnnouncementSystem`

### 8.4a 付费 potion boost

1. Boosts 面板展示 `paidCash2x10m` 和其他已配置 Robux products / gamepasses
2. `MarketplaceService.ProcessReceipt` 处理 `paidCash2x10m` receipt
3. receipt 调用 `PotionSystem:GrantAndUsePotion()`，最终写入或延长 `equippedBuff.cash2x`
4. 真实玩家后续 Flip 通过 `BuffSystem:GetWinsBoost()` 获得 `2x Cash`；概率、streak 和 flip interval 不变

### 8.5 离开时清理

1. 所有系统先执行 `PlayerRemoving`
2. `TableSeatSystem` 清理占座
3. `CoinFlipSystem` / 其他系统清空本地缓存
4. `DataManager:ReleaseProfile()`
5. `PlayerServerClass.RemoveIns()`

---

## 9. 数据层与存档结构

### 9.1 数据主入口

文件：

- `src/ServerStorage/modules/DataManager.lua`
- `src/ServerStorage/classes/PlayerServerClass.lua`
- `src/ReplicatedStorage/configs/DefaultData.lua`
- `src/ReplicatedStorage/configs/DebugData.lua`

### 9.2 `DataManager`

职责：

- 基于 `ProfileService` 读取/写入 `PlayerData`
- 默认模板来自 `DefaultData.lua`
- 提供读整份、读单键、改单键、离线读写

一个关键现实：

- `GameConfig.isAlphaTest` 当前为 `false`
- alpha 测试阶段如果重新打开，`DataManager` 每次玩家进服都会把已加载 profile 的 `Data` 替换为 `DefaultData` 深拷贝，确保每次进入都是初始数据
- `isAlphaTest` 优先于 Studio `IsDebug`；关闭 alpha 后，Studio debug 才会继续使用 `DebugData`
- `GameConfig.IsDebug` 当前也为 `false`，因为 `GameConfig.lua` 内部本地 `IsDebug = false`
- 所以当前 Studio 测试不会自动用 `DefaultData` 或 `DebugData` 覆盖 profile；需要重置数据时应显式打开 alpha / debug 配置或用专门测试账号

当前 `DebugData` 特点：

- `wins` 被设成超大值
- 方便开发期间快速测试升级与展示

### 9.3 `PlayerServerClass`

当前是服务端玩家对象统一入口。

职责：

- 等待 `profileLoaded`
- 代理 `GetOneData / SetOneData / AddOneData / GetAllData`
- 提供少量开发聊天命令

当前建议：

- 服务端系统不要直接到处摸 `ProfileService`
- 先拿 `PlayerServerClass.GetIns(player)`

### 9.4 当前和首发主线强相关的数据键

存档里当前和首发主线最相关的字段：

- `wins`
- `fateShards`
- `level`
- `exp`
- `bestStreak`
- `lifetimeFlips`
- `lifetimeHeads`
- `lifetimeCashEarned`
- `equippedCoin`
- `ownedCoins`
- `equippedDeskSetup`
- `ownedDeskSetups`
- `equippedChair`
- `ownedChairs`
- `autoFlipUnlocked`
- `rebirthTree`
- `runData`
- `guideData`
- `settingsData`
- `dailyClaim`
- `potions`
- `equippedBuff`

其中要特别记住：

- 底层仍用 `wins`
- 对玩家展示时普遍叫 `Cash`
- 新建默认档 `wins = 9`，只影响新玩家 / 新档默认值；不对已有玩家现金做迁移
- `level / exp` 是 Profile XP 的持久化成长字段，当前由真实玩家 Flip 结算后通过 `PlayerSystem:AddExp()` 增长；升级阈值来自 `ExcelConfig/PlayerLevel.lua`
- `dailyClaim.flipACoinGoals` 是 Flip 专属轻量每日目标状态，按服务器日保存 `progress / claimed`；当前没有独立 Daily 面板，完成即自动领奖并通知
- `runData.coinCountLevel` 是多金币数量 tier，默认 `0`，由 Rebirth 永久升级 `Coin Spread` 写入 baseline；它不是 HUD 里的本局 `Value` 升级
- `guideData.coinFlipOnboarding` 是首局引导专用状态；当前 v4 流程覆盖首次 Flip、首次 Value 升级、首次 Rebirth、首次非默认 Coin 购买与装备
- `onboardingFunnelStep` 现在只承担漏斗节点记录，不再直接代表 UI 引导进度

### 9.5 修改存档结构时必须同步的地方

只要新增或修改存档字段，至少检查：

1. `Keys.DataKey`
2. `DefaultData.lua`
3. `DebugData.lua`
4. 相关系统的初始化/下发路径
5. 客户端是否需要同步显示

---

## 10. UI 层真实情况

### 10.1 `uiController` 仍是中心工具

文件：

- `src/StarterGui/Main/uiController.lua`

它仍然是当前 UI 通用能力中心，负责大量：

- 通知
- 按钮 hover/click 包装
- 开关面板
- 动画和小工具

即使某些旧系统未启用，`uiController` 本身仍是当前活跃基础设施。

### 10.2 当前首发玩法最关键的 UI 在哪里

- `Main.Elements.CoinFlipHUD`
- 桌面内的同桌轻量状态 / streak / flip 反馈节点
- 当前预制 HUD 的三栏结构：
  - `Content.LeftPanel`：Cash / Streak
  - `Content.CenterPanel`：SeatLabel / ResultLabel / `FLIP` 主按钮 / `Auto:Off / Auto:On` 按钮 / `GuidePrompt` / `SpaceHint` / `GamepadRTHint`
  - `Content.RightPanel`：Chance / Speed / 四个升级按钮

这些由：

- `CoinFlipSystem/ui.lua`
- `EcoSystem/ui.lua`
- `RebirthSystem/ui.lua`
- `EffectSystem/init.lua`

直接管理。

当前约定：

- 主 HUD 绑定读取 Studio 预制节点，不再为统计卡、升级按钮或离座按钮运行时创建兜底资源。
- `CoinFlipSystem/ui.lua` 绑定 Flip HUD、run upgrade、多金币结果文案和 v4 引导高亮；不直接渲染 Shop / Inventory / Rebirth 面板内容，但会通过系统 UI 辅助方法打开并定位引导目标。
- `EcoSystem/ui.lua` 绑定 TopbarPlus `Shop` / `Boosts` / `Inventory` 图标、兼容旧 `Buttons.CoinFlipMenu.ShopButton / InventoryButton`，并管理 `Frames.Shop / Boosts / Inventory`；Boosts 使用独立 Studio-authored 面板展示 `Products.flipACoin` 和 `GamePasses`，不会显示 Shop 的 Coin / Desk / Chair 侧栏。付费 id 未配置时按钮显示 `Set ID` 且不可点击。Shop 购买成功和 Inventory 装备成功后，服务端发轻 notification，客户端按同步 payload 播放购买 / 装备 SFX。
- `RebirthSystem/ui.lua` 绑定 TopbarPlus `Rebirth` 图标、兼容旧 `Buttons.CoinFlipMenu.RebirthButton`，并管理 `Frames.Rebirth`。
- `EffectSystem` 负责桌面 coin flip 表现，`CoinFlipSystem/ui.lua` 只调用它并等待落地回调。
- 当前 in-play minimal HUD 是 Studio-authored 资源：TopbarPlus 是顶部入口，`CoinFlipMenu` 只保留兼容且玩法态隐藏，`Elements.cash / candy` 保留为 hidden legacy 节点但不再作为右上钱包显示，`CoinFlipHUD` 是全屏透明承载层，左下显示现金 / round streak，右下显示概率 / 速度 / Value / Luck，底部中心显示 `FLIP`、`Auto:Off / Auto:On`、`GuidePrompt` 和短结果提示；多金币结果复用 `ResultLabel`，单金币保持 `Heads! +$ 10` / `Tails! +$ 2`，多金币显示 `headsCount/coinCount`、combo 名、streak reset 和奖励，如 `2/3 Heads! Pair +$ 48` 或 `1/3 Heads. Streak reset. +$ 10`；Rebirth 永久升级 `Coin Spread` 提高 coin 数量时会短暂提示 `Coin Spread unlocked 2 coins per flip.`，并用 `UnlockBanner` / `FirstMultiCoinBanner` 做首次多金币解锁与首秀；`FlipButton.gamepadKeyImg` 用 `UserInputService:GetImageForKeyCode()` 显示当前输入方式对应的 R2 图片，键鼠端在同一 ImageLabel 内显示 Studio-authored `keyboardKeyText` 紧凑 Space 键帽兜底并放在 `FLIP` 按钮内部左侧，触屏端隐藏，旧 `InputHints` Frame 不再显示；`Main.Elements` 只保留 `CoinFlipHUD`、`cash`、`candy`、`ripple`，旧 `Buffs / Rewards / Quests / auto / blockInfo` 和旧 CoinFlip onboarding / spectator / overview 节点已从 Studio 资源中删除。
- 多金币 Flip 会选择一枚 primary coin 承载玩家相机跟随与强落地 `coinLandingBurst`：primary 现在固定是视觉中位币，5 枚是第 `3` 枚、4 枚是第 `2` 枚；其他硬币只保留轻落地 pulse。
- `Frames.Shop / Boosts / Inventory / Rebirth / Settings` 的主结构、布局、圆角、描边和文字约束均在 Studio 中维护；Shop / Boosts / Inventory 的 item 区域是 Studio-authored `ScrollingFrame + Template`，运行时从单个 `Template` clone 商品卡，不再依赖固定 `Item1` 到 `Item12` 卡片池或分页控件；Rebirth 面板复用 4 张 Studio-authored perk card 展示 `Coin Spread / Chain Start / Quick Start / Lucky Start`，升级 chip 和按钮都会标注当前 Rebirth Points 消耗；Shop / Boosts 卡片的 `Art.Image`、Preview 的 `PreviewScene.Icon` 和 Inventory 卡片的 `Icon.Image` 由 `EcoSystem/ui.lua` 绑定到 `Textures.FlipACoinItems` 临时 icon 配置，后续替换图片链接只需改 `src/ReplicatedStorage/configs/Textures.lua`；Shop / Boosts 商品卡隐藏独立价格标签，底部居中大 `BuyButton` 直接显示价格 / Robux 价格或 `Owned`；运行时代码只绑定按钮、更新图片 / 文本 / selected 状态、打开关闭、重置滚动位置和播放音效。触屏移动端打开面板时通过 `uiController` 套安全区尺寸 / 位置的重排逻辑已临时注释，等待移动端布局重做。
- `Frames.Shop / Boosts / Inventory / Rebirth` 打开时会走 `uiController.OpenFrame()` 的轻遮罩，并由 `CoinFlipSystem/ui.lua` 隐藏 gameplay HUD，关闭后再恢复。
- `uiController` 优先用 `GrowthPanelInputContext` 绑定 `ClosePanel = Escape / ButtonB`；Input Action System 不可用时回退到 `ContextActionService`。
- 当前游戏具备基础触屏支持；`default.project.json` 设置 `StarterPlayer.DevTouchMovementMode = Scriptable`，`uiClient.client.lua` 在触屏设备上关闭 `GuiService.TouchControlsEnabled`、禁用已生成的 `TouchGui` 并停用 `PlayerModule` movement controls，因为当前玩法不需要移动 / 跳跃；触屏端仍隐藏 keyboard / gamepad 输入提示并把 ready 文案改为 `Tap FLIP`。`CoinFlipSystem/ui.lua` 的 mobile HUD profile 和 portrait 下折叠 Chance / Speed 的逻辑已临时注释，移动端先沿用桌面 / narrow HUD 布局。`uiController.OpenFrame()` 的移动端 growth panel 重排与 viewport 刷新绑定也已临时注释；TopbarPlus 入口点击面积、growth panel 内容挤压和整体观感仍需 Studio / 真机 QA。
- 旧 `Stats` / `Actions` 容器如果仍存在，只是隐藏兼容遗留，不是当前主 HUD 数据源。

### 10.3 UI 延迟初始化模式

很多系统客户端入口都先创建：

- `local XxxUi = { pendingCalls = {} }`
- 然后 `setmetatable(XxxUi, Types.mt)`

含义是：

- 系统先收到同步消息也没关系
- 真 UI 模块加载前，调用会先缓存到 `pendingCalls`
- UI 初始化后再回放

这个模式对新 agent 很重要，因为它解释了：

- 为什么有些 `ui.lua` 即使很晚才 require，前面的远端同步也不会立刻丢

### 10.4 当前哪些系统的 `ui.lua` 很轻或几乎空

例如：

- `TableSeatSystem/ui.lua`
- `PlayerSystem/ui.lua`
- `CharacterSystem/ui.lua`

这些文件存在，但当前更多是保留系统结构一致性，真正的主要表现逻辑已经转移到别处，尤其是 `CoinFlipSystem/ui.lua` 和 `uiController.lua`。

---

## 11. 场景与资源依赖

新窗口如果要改当前主玩法，先确认 Studio 里这些对象存在：

### 11.1 `Workspace.CoinFlipTable`

当前主玩法最关键场景对象。

默认会被这些代码直接依赖：

- `TableSeatSystem`
- `CoinFlipSystem/ui.lua`

建议假设它至少包含：

- `Seats`
- `Assets`（可选；`DecorationSystem` / `FakePlayerSystem` 等会在运行时创建 `Assets` 用于桌搭、椅子、假玩家 runtime 等）
- `CoinVisuals`：`EffectSystem` 先找 `Assets.CoinVisuals`，没有则找 **`CoinFlipTable` 下的 `CoinVisuals`**（与 `Assets` 同级亦可）
- `Attachments`

其中：

- `Attachments/<SeatId>Marker` 可作为座位视觉锚点
- `Attachments/<SeatId>ChairAnchor` 可作为座位椅子锚点
- `Assets.FakePlayersRuntime` 是 `FakePlayerSystem` 的运行时假玩家模型容器，可由服务端自动创建
- 旧座位 Billboard 不再是首发主路径；若需要桌面反馈，应改成低噪音桌面信号

### 11.2 `Workspace.RankingList`

被 `BillboardManager.lua` 依赖。

如果不存在：

- `BillboardManager` 会立即安静降级成 no-op，不等待启动超时，也不刷启动 warn
- 不会阻止主玩法运行；补回排行榜展示时需在 server 启动前提供该实例树

### 11.3 `workspace.BGSoundsFolder`

被 `MusicSystem` 用作 BGM 实例容器。

### 11.4 `StarterGui.Templates.onPlayerHead`

被 `CharacterSystem` 克隆到角色头部，随后由 `PlayerSystem` 填信息。

---

## 12. 文档与代码之间的当前关系

### 12.1 哪些文档今天还值得看

- `README.md`
  - 项目入口与最短启动说明
- `docs/FRAMEWORK.md`
  - SystemMgr 框架机制、生命周期、桥接约定和编码习惯
- `docs/BOOTSTRAP.md`
  - 新对话启动路由：先读什么、什么时候再读框架或项目事实
- `docs/PROJECT_LOGIC.md`
  - 项目事实运行地图；判断当前玩法、系统和资源事实时优先看这里
- `docs/TASK_STATE.md`
  - 当前 active 任务、下一步、决策、backlog 和最近约 10 条完成摘要
- `docs/archive/`
  - 历史完成记录、旧计划和追溯用验证细节；默认启动不读
- `docs/RULES_SYNC.md`
  - 共享规则同步方式；当前共享源是同级 `../CentralRules`

### 12.2 已删除的旧 Markdown

2026-05-04 已把旧策划、旧路线图、旧执行进度、旧系统拆分和旧架构梳理文档从 `docs/` 删除。
2026-05-16 已删除根目录旧 `TODO.md`，并把 `README.md` 收敛为当前项目入口说明。

删除原因：

- 当前玩法定位已经合并进本文档第 2 节。
- 当前任务、近期决策和 backlog 已迁移到 `TASK_STATE.md`；较旧验证细节进入 `docs/archive/`。
- 旧系统拆分与旧架构梳理包含 `BaseSystem`、多桌 / 围观、旧 simulator 方向等过时信息，继续保留会误导新窗口。

### 12.3 哪些内容现在明显过时

- 旧 `PROJECT_LOGIC.md` 内容曾指向 `Minion Wars / BattleSystem / SkillSystem`
- 这些都不再代表当前项目

现在如果要判断真实结构：

- 永远先回 `SystemMgr.lua`
- 再看对应系统源码

---

## 13. 当前遗留区与非主线区域

这些内容目前不要默认当成“活跃系统”：

- `BackpackSystem`
- `BoxSystem`
- `DailySystem`
- `DoorSystem`
- `DropSystem`
- `EventSystem`
- `FreeRewardSystem`
- `GiftSystem`
- `NPCSystem`
- `PetSystem`
- `QuestSystem`
- `SeasonSystem`
- `SiteSystem`
- `SpinSystem`
- `TradeSystem`
- `TrailSystem`
- `WeaponSystem`
- `WeatherSystem`

它们的状态更像：

- 旧项目保留
- 未来可复用备选
- 或者尚未重新接入当前首发主线

同样，下面这些也不是当前运行时核心：

- `SystemMgr Fail.lua`
- `BaseSystem.lua`
- `plugin.lua`
- `windowsSettings/`
- `analytics.server.lua`

---

## 14. 给未来 agent 的维护规则

以后如果项目继续推进，维护本文时优先更新这些部分：

1. `SystemMgr.lua` 的注册表和加载顺序
2. 当前真正主线玩法系统
3. `wins` / `Cash` / `runData` 的真实数据流
4. `CoinFlipTable` 场景依赖
5. 哪些旧系统重新接回主线了
6. 哪些文档已经过时

新增系统或重新启用旧系统时，至少补这几件事：

- 在本文的“活跃系统职责图”里登记
- 写清楚它依赖谁、给谁发数据
- 说明它是主线系统、辅助系统，还是仅服务端工具
- 如果它改了存档结构，也同步更新“数据层与存档结构”

---

## 15. 现在可以把这个项目怎么理解

如果只用一句工程化的话概括当前仓库：

这是一个已经用旧框架成功跑通“8 人同桌翻硬币”主链路的 Flip A Coin 项目，当前最该相信的是 `SystemMgr + PlayerSystem + TableSeatSystem + FakePlayerSystem + DecorationSystem + CoinFlipSystem + EcoSystem + PotionSystem + BuffSystem + RebirthSystem + EffectSystem + SettingSystem + AnalyticsSystem + ClientData` 这条线，其余大量目录都应先视为遗留或候选，而不是默认活跃。

产品方向上，它应被理解为“单桌 8 人弱社交桌面运气游戏”：不要再往多桌大厅、自由走动、复杂观战面板方向扩展；首发重点是进服即坐下、面前一个强 `FLIP` 按钮、短循环升级、streak 情绪曲线、以及轻量同桌存在感。
