# PROJECT_LOGIC

更新时间：2026-04-16

## 1. 这份文档的定位

这份文档是给“新开 agent 窗口 / 新协作者”快速接管项目用的运行地图，不是策划案，也不是理想化架构说明。

新窗口建议按这个顺序读：

1. `docs/PROJECT_LOGIC.md`
2. `docs/FlipACoin_首发优化执行与进度.md`
3. `docs/FlipACoin_首发路线图与进度.md`
4. `docs/FlipACoin_Roblox多人化改造策划案.md`
5. 需要落代码时，再回到对应系统源码核实

如果文档和代码冲突：

- 以当前代码为准
- 再顺手把本文档更新掉

---

## 2. 当前项目一句话总结

这是一个基于旧 `SystemMgr + Systems` 框架持续改造中的 `Flip A Coin` 项目。

当前主玩法已经切到：

- 玩家进入大厅
- 通过 `CoinFlipTable` 的空座位入座
- 坐下后开始翻硬币
- 正面给主要 `wins` 奖励，反面给少量保底 `Cash`，但会打断 streak
- `wins` 在 UI 和 `leaderstats` 中对外展示为 `Cash`
- 用 `Cash` 升级本局四项 run 属性
- 冲更高 streak
- 同桌/旁观玩家看到桌况、播报和抛币结果

这份仓库里仍保留很多旧 simulator/战斗项目遗留目录，所以不要按“目录里有什么”理解项目，而要按下面两条判断：

1. `src/ReplicatedStorage/Systems/SystemMgr.lua` 里当前注册了哪些系统
2. 当前启动链真正会 require 哪些脚本

---

## 3. 新窗口最容易被误导的地方

先记住这些事实：

- `default.project.json` 当前项目名是 `Flip A Coin`
- `README.md` 仍是旧 Rojo 模板内容，不能用来判断项目现状
- `src/ReplicatedStorage/Systems` 下很多系统目录目前没有启用
- `src/ReplicatedStorage/Systems/SystemMgr Fail.lua` 是旧版本，不是当前入口
- `BaseSystem.lua` 是新基类尝试，但当前活跃系统大多仍是手写风格
- `TODO.md` 主要是旧武器/锻造方向遗留，不代表当前首发主线
- `analytics.server.lua` 整个文件目前是注释状态
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
  - 把 `ReplicatedFirst.RobStar` 挂到 `PlayerGui`
  - 这是最早可见的加载体验

玩家脚本阶段：

- `src/StarterPlayer/StarterPlayerScripts/client.client.lua`
  - 只做一件事：`require(Replicated.Systems.SystemMgr)` 然后 `SystemMgr.Start()`

主 UI 阶段：

- `src/StarterGui/Main/uiClient.client.lua`
  - 关闭默认背包
  - 做触屏 / 手柄适配
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
- `AnnouncementSystem`
- `CharacterSystem`
- `CoinFlipSystem`
- `GuiSystem`
- `MusicSystem`
- `PlayerSystem`
- `TableSeatSystem`

没有在这里注册的系统，即使目录还在，也默认不参与运行时主链路。

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

- 维护 `CoinFlipTable` 的座位目录
- 接 `ProximityPrompt` 入座
- 处理离座 / 换座
- AFK 超时踢座
- 同步座位状态给客户端
- 维护桌边 Billboard 信息
- 通知 `CoinFlipSystem` 当前座位态变化

依赖的场景约定：

- `Workspace.CoinFlipTable`
- 其下 `Seats` 文件夹
- 每个 `Seat` 需要有 `SeatId` 属性或用座位名作为 seat id
- 座位上要有 `ProximityPrompt`

一个非常重要的当前实现细节：

- `GetAudiencePlayers()` 现在直接返回 `Players:GetPlayers()`
- 所以“观战同步”和“播报接收范围”目前其实是全服，而不是严格只限同桌

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
- 按 `GameConfig.FlipACoin` 计算正面概率、奖励、速度
- 写入 `runData`
- 维护首局 `coinFlipOnboarding` 引导状态
- 累积 `wins / bestStreak / lifetimeFlips / lifetimeHeads / lifetimeCashEarned`
- 刷新 `leaderstats` 与头顶 UI
- 广播本次 flip 给旁观者
- 驱动 streak 播报
- 处理升级购买

客户端当前负责：

- 显示 Flip HUD
- 显示首局引导面板与按钮聚焦
- 本地改写 `SeatInfoBillboard`，把世界提示对齐到当前首局步骤
- 响应式布局
- 展示桌况 overview
- 展示观战 feed
- 播放 coin flip 可视表现

关键玩法数据：

- 本局成长写入 `dataKey.runData`
- 四项升级：
  - `valueLevel`
  - `comboLevel`
  - `speedLevel`
  - `biasLevel`

当前玩法核心配置都集中在：

- `GameConfig.FlipACoin`
- `CoinFlipSystem/Presets.lua`

当前额外要记住：

- 首局引导链已经接到真实玩法事件：
  - 靠近空位 prompt
  - 入座
  - flip `3` 次
  - 购买首次升级
  - 达成 `2 streak`
- `CoinFlipSystem/ui.lua` 还会根据当前引导步骤本地重写世界 Billboard：
  - 未入座时把空位改成 `Take Seat / Start Here`
  - 已入座后把自己的座位改成 `Next Up`
- `PlayerSystem:UpdatePlayerHeadGui()` 现在也会在引导期间把头顶文案切到当前下一步动作
- 引导细状态写在 `guideData.coinFlipOnboarding`
- 漏斗埋点仍继续沿用 `onboardingFunnelStep`
- 这两个字段现在是“引导状态”和“分析节点”两条线，不要再混写

### 7.5 `AnnouncementSystem`

文件：

- `src/ReplicatedStorage/Systems/AnnouncementSystem/init.lua`
- `src/ReplicatedStorage/Systems/AnnouncementSystem/Presets.lua`
- `src/ReplicatedStorage/Systems/AnnouncementSystem/ui.lua`

当前职责：

- 当 `CoinFlipSystem` 出现正面且 streak 到阈值时，生成高光播报
- 当前阈值是：
  - `4`
  - `6`
  - `8`
  - `10`
- 客户端动态创建顶部 banner，并通过 `uiController.SetNotification` 再打一层通知

当前依赖关系：

- `CoinFlipSystem:RequestFlip()` -> `AnnouncementSystem:HandleFlipResolved()`

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
- 维护 BGM 淡入淡出
- 提供 `SetBgmVolume` / `SetSfxVolume`

当前注意点：

- 这个系统已经启用
- 但首发主玩法里还没有大量深接
- 它依赖 `SoundService` 下的分组和资源命名，以及 `workspace.BGSoundsFolder`

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

### 8.2 玩家数据下发

1. `PlayerSystem:PlayerAdded()` 读取完整数据
2. 服务端通过系统桥接把数据发给客户端
3. 客户端 `ClientData.InitData(args.data)`
4. 客户端各系统 UI 再读取 `ClientData`

所以：

- 客户端大多数读数据场景都不是实时请求服务器
- 而是读 `ReplicatedStorage/Systems/ClientData.lua` 里的本地镜像

### 8.3 入座开始玩法

1. 玩家触发 `CoinFlipTable` 上的座位 `ProximityPrompt`
2. `TableSeatSystem:RequestSit()` 占座并让 Humanoid 坐下
3. 座位状态广播给所有客户端
4. `CoinFlipSystem` 收到座位态后切换 HUD / 观战态

### 8.4 翻硬币结算

1. 客户端请求 `CoinFlipSystem.Server:RequestFlip()`
2. 服务端检查：
   - 玩家还在不在
   - 是否已入座
   - flip 冷却是否结束
3. 计算本次正反和奖励
4. 更新 `wins` 与 `runData`
5. 刷新：
   - `leaderstats.Cash`
   - 头顶 UI
   - 座位桌况
6. 发回本人 HUD 结果
7. 发给其他玩家观察结果
8. 若达到阈值，驱动 `AnnouncementSystem`

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

- `GameConfig.IsDebug` 目前在 Studio 下为 `true`
- 所以 Studio 测试时会直接把 profile 数据替换成 `DebugData`

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
- `bestStreak`
- `lifetimeFlips`
- `lifetimeHeads`
- `lifetimeCashEarned`
- `equippedCoin`
- `ownedCoins`
- `autoFlipUnlocked`
- `rebirthTree`
- `runData`
- `guideData`
- `settingsData`

其中要特别记住：

- 底层仍用 `wins`
- 对玩家展示时普遍叫 `Cash`
- `guideData.coinFlipOnboarding` 是首局引导专用状态
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
- `Main.Elements.CoinFlipTableOverview`
- `Main.Elements.CoinFlipSpectatorFeed`

这些由：

- `CoinFlipSystem/ui.lua`

直接管理。

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
- `Assets`
- `Assets.CoinVisuals`
- `Attachments`

其中：

- `Attachments/<SeatId>Marker` 会被 `TableSeatSystem` 用来给座位 Billboard 找 Adornee
- 缺少时会退回直接挂到座位本体

### 11.2 `Workspace.RankingList`

被 `BillboardManager.lua` 依赖。

如果不存在：

- 当前代码会降级成 no-op
- 不会阻止主玩法运行

### 11.3 `workspace.BGSoundsFolder`

被 `MusicSystem` 用作 BGM 实例容器。

### 11.4 `StarterGui.Templates.onPlayerHead`

被 `CharacterSystem` 克隆到角色头部，随后由 `PlayerSystem` 填信息。

---

## 12. 文档与代码之间的当前关系

### 12.1 哪些文档今天还值得看

- `docs/PROJECT_LOGIC.md`
  - 运行地图，优先级最高
- `docs/FlipACoin_首发优化执行与进度.md`
  - 当前全链路首发优化的唯一续接文档
- `docs/FlipACoin_首发路线图与进度.md`
  - 旧的首发推进历史和已完成事项
- `docs/FlipACoin_Roblox多人化改造策划案.md`
  - 产品目标和玩法定位
- `docs/FlipACoin_开发优先级清单与系统任务表.md`
  - 仍有参考价值，但部分内容已经落后于当前代码

### 12.2 哪些文档现在明显过时

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
- `BuffSystem`
- `DailySystem`
- `DoorSystem`
- `DropSystem`
- `EcoSystem`
- `EffectSystem`
- `EventSystem`
- `FreeRewardSystem`
- `GiftSystem`
- `NPCSystem`
- `PetSystem`
- `PotionSystem`
- `QuestSystem`
- `RebirthSystem`
- `SeasonSystem`
- `SettingSystem`
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

这是一个已经用旧框架成功跑通“8 人同桌翻硬币”主链路的 Flip A Coin 项目，当前最该相信的是 `SystemMgr + PlayerSystem + TableSeatSystem + CoinFlipSystem + ClientData` 这条线，其余大量目录都应先视为遗留或候选，而不是默认活跃。
