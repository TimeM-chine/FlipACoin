# FRAMEWORK

> 目的：描述 **SystemMgr 框架本身**——所有基于此框架的 Roblox 项目共享的机制、约定、编码习惯。**不写具体项目的业务**（那些在 `docs/PROJECT_LOGIC.md`）。
>
> 使用规则：
> - 新对话开始时与 `AGENTS.md` + `PROJECT_LOGIC.md` 一起读。
> - 跨项目复制时，整份 `FRAMEWORK.md` 可以原样带走；基本不需要按项目改。
> - 如果框架本体升级（SystemMgr 改接口、生命周期顺序调整、桥接规则变化等），**只改这里**，不要把框架细节塞进 `PROJECT_LOGIC.md`。

---

## 1. 目录约定

标准 Rojo 项目（`default.project.json`）下，通常是这几个根：

| 目录 | 作用 |
|---|---|
| `src/ReplicatedFirst/` | 启动阶段（加载屏、必要早期脚本） |
| `src/ReplicatedStorage/Systems/` | **框架系统本体**（`SystemMgr.lua` + 各系统目录） |
| `src/ReplicatedStorage/configs/` | 全局配置：`GameConfig`、`Keys`、`Types`、`DefaultData`、`DebugData` 等 |
| `src/ReplicatedStorage/ExcelConfig/` | （可选）Excel 导出的表驱动内容 |
| `src/ReplicatedStorage/modules/` | 共享工具：`ScheduleModule`、`TableModule`、`Util`、`TweenModule`、`Zone`、`Bezier` 等 |
| `src/ServerScriptService/` | 服务端入口（通常只有一个 `server.server.lua` 调 `SystemMgr.Start()`） |
| `src/ServerStorage/classes/` | 服务端类：`PlayerServerClass` |
| `src/ServerStorage/modules/` | 服务端模块：`DataManager`、`BillboardManager`、`GlobalDataModule` 等 |
| `src/ServerStorage/libs/` | 第三方库：`ProfileService` 等 |
| `src/StarterGui/Main/` | UI 骨架 + `uiController.lua`（UI 辅助）+ `uiClient.client.lua` |
| `src/StarterPlayer/StarterPlayerScripts/` | 客户端入口（调 `SystemMgr.Start()`） |
| `src/StarterPlayer/StarterCharacterScripts/` | 角色挂载的本地脚本 |

具体项目的活跃目录、是否存在 `ExcelConfig` 等以 `PROJECT_LOGIC.md` 为准。

---

## 2. 入口与启动顺序

### 服务端
```lua
-- src/ServerScriptService/server.server.lua
local SystemMgr = require(ReplicatedStorage.Systems.SystemMgr)
SystemMgr.Start()
-- 其后按项目需要初始化 GlobalData / Billboard / 定时任务
```

### 客户端
```lua
-- src/StarterPlayer/StarterPlayerScripts/client.client.lua
local SystemMgr = require(ReplicatedStorage.Systems.SystemMgr)
SystemMgr.Start()
```

### 加载顺序
1. `SystemMgr.Start()` 先按 `LoadOrder` 列出的名字 `task.spawn(LoadSystem, name)`（通常是 `PlayerSystem` → `CharacterSystem`）。
2. 再遍历 `systems` 表，把未加载的剩余系统以 `task.spawn` 并发加载。
3. 服务端额外做两件事：
   - 懒加载 `DataMgr`、`PlayerServerClass`
   - 遍历已在服的 `Players:GetPlayers()`，再挂 `PlayerAdded / PlayerRemoving`

---

## 3. `SystemMgr.lua`（框架中枢）

位置：`src/ReplicatedStorage/Systems/SystemMgr.lua`。**运行时对系统注册、桥接、生命周期的唯一权威。**

### 3.1 `systems` 表
```lua
local systems = {
  PlayerSystem = require(Replicated.Systems.PlayerSystem),
  -- 只有登记在这里的系统才会被加载
}
setmetatable(systems, mt) -- 未加载系统访问时返回安全代理并 warn
```
- **想启用一个系统**：在 `systems` 里 `require` 它。
- **想暂时禁用**：注释掉那一行（目录保留无所谓）。
- 访问未加载系统会得到一个每个方法都会 warn + 返回 nil 的代理，不会炸。

### 3.2 `LoadOrder`
```lua
local LoadOrder = { "PlayerSystem", "CharacterSystem" }
```
只有真的需要"先于其他系统完成 `Init`"才加进来。其余系统并发加载，`Init` 不保证顺序。

### 3.3 桥接生成规则（`LoadSystem`）
服务端：遍历 system 的每个函数字段（除 `Init`、除 `whiteList` 里的），在 `system.Client[fn]` 挂 `FireClient` 包装；若 system 自行建了 `system.AllClients = setmetatable({}, System)`，也挂 `FireAllClients`。
客户端：把每个这样的函数挂到 `system.Server[fn]` 上做 `FireServer`。
末端：把原参数追加 `{ sysName, funName }` 作为定位信息，远端按 `systems[sysName][funName](systems[sysName], ...)` 调用。

服务端 remote 派发会先校验定位信息必须是合法的 `{ sysName: string, funName: string }`，且目标系统 / 方法真实存在；malformed 直连 RemoteEvent payload 会被直接丢弃。

调用约定：

| 方向 | 写法 |
|---|---|
| Server → 单个 player | `self.Client:Fun(player, args)` |
| Server → 所有 players | `self.AllClients:Fun(args)` |
| Client → Server | `self.Server:Fun(args)` |
| 非关键高频广播 | 在 `args` 里写 `unreliable = true`，走 `UnreliableRemoteEvent` |

`unreliable` 标记读取自第一个 payload table（即上表中的 `args.unreliable`），不是 varargs 包装表；桥接代理会据此选择 `RemoteEvent` 或 `UnreliableRemoteEvent`。

### 3.4 `whiteList`
每个系统都应声明：
```lua
local System: Types.System = { whiteList = { "SomeInternal" }, ... }
```
列进去的方法：
- **不会**被框架挂成 remote（外部客户端伪造 RemoteEvent 无法触发）
- 专供同服务端内部调用 / 共享工具方法

### 3.5 `SENDER`
- `SystemMgr` 生成的随机整数，挂 `SystemMgr.SENDER`。
- 由框架主动调起的方法（如 `PlayerAdded`）首参都是 `sender`；服务端实现**必须**判断：
  ```lua
  function System:PlayerAdded(sender, player, args)
    if IsServer then
      if sender ~= SENDER then return end
      ...
    end
  end
  ```
- 跨系统互相调用时，调用方把 `SENDER` 作为首参传入，被调方同样判断；这样外部伪造的 remote 进不来。

### 3.6 `IsLoaded`
- 服务端：`ins.IsLoaded = true` 在挂完桥 + 跑完 `Init` 之后置上。
- 客户端：同上，并在 `Replicated.Systems[name]` 下建一个名为 `IsLoaded` 的 Folder，作为其他客户端等待信号。
- 框架在派发 remote 前会 `WaitForChild("IsLoaded")` 做同步。

### 3.7 `PlayerAdded`/`PlayerRemoving` 编排（**顺序固定**）

进服（服务端）：
1. `DataManager`（自行监听 `Players.PlayerAdded`）先 `LoadProfileAsync`，完成后给 `player` 挂 `profileLoaded` BoolValue。
2. `SystemMgr` 的 `PlayerAdded` 连接遍历 `ListenAdded`（定义了 `PlayerAdded` 的系统名列表），用 `task.spawn` 调每个 `systems[name]:PlayerAdded(SENDER, player)`。
3. 各系统内部按需 `WaitForDataLoaded()`（通过 `PlayerServerClass.GetIns`）。

离服（服务端）：
1. **先**按 `ListenMoving` 遍历调每个系统的 `PlayerRemoving`（此时 profile 数据仍可写）；系统若未定义 `PlayerRemoving`，框架会自动清空 `system.players[player.UserId]`。
2. **然后** `DataMgr:ReleaseProfile(player)`：snapshot + ProfileService 释放。
3. **最后** `PlayerServerClass.RemoveIns(player)`。

> 单个系统**不要**自己 hook `Players.PlayerRemoving` 释放 profile；只实现 `PlayerRemoving(self, sender, player)` 交给 `SystemMgr` 调度。

---

## 4. 单个系统文件布局

### 4.1 标准 5 件套
```
Systems/<YourSystem>/
  init.lua        # 桥接、生命周期、跨端入口
  Presets.lua     # 系统内常量、表驱动内容的聚合
  ui.lua          # 客户端渲染/本地输入
  Modules/        # 系统内逻辑拆分
  Assets/         # 系统专属资源（模型、特效、图片）
```
不是每个系统都需要全部 5 件；但**出现的部分请沿用这些名字**。

### 4.2 `init.lua` 顶部的规范顺序
```
-- services
-- requires
-- common variables   (IsServer, SENDER, SystemMgr, dataKey ...)
-- server variables   (PlayerServerClass, AnalyticsService, ...)
-- client variables   (LocalPlayer, ClientData, <Sys>Ui)

local <Sys>Ui = { pendingCalls = {} }
setmetatable(<Sys>Ui, Types.mt)

local System: Types.System = {
  whiteList = {},
  players = {},
  tasks = {},
  IsLoaded = false,
}
System.__index = System

if IsServer then
  System.Client = setmetatable({}, System)
  -- System.AllClients = setmetatable({}, System)  -- 需要广播时打开
  PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
else
  System.Server = setmetatable({}, System)
  LocalPlayer = Players.LocalPlayer
  ClientData = require(Replicated.Systems.ClientData)
end

function GetSystemMgr()  -- 懒加载规避循环依赖
  if not SystemMgr then
    SystemMgr = require(Replicated.Systems.SystemMgr)
    SENDER = SystemMgr.SENDER
  end
  return SystemMgr
end

function System:Init() GetSystemMgr() end
function System:PlayerAdded(sender, player, args) ... end
function System:PlayerRemoving(sender, player) ... end      -- 可选
function System:<业务方法>(sender, player, args) ... end    -- 保持 if IsServer else 双分支

---- [[ Both Sides ]] ----
---- [[ Server Only ]] ----
---- [[ Client Only ]] ----

return System
```

### 4.3 客户端 UI 的 pendingCalls 机制
`Types.mt` 提供了一个元表：在 `ui.lua` 还没 `require` 之前，其他代码调 `<Sys>Ui.Fun(...)` 会被缓存到 `pendingCalls`。`PlayerAdded` 客户端分支里：
```lua
local pendingCalls = <Sys>Ui.pendingCalls
<Sys>Ui = require(script.ui)
<Sys>Ui.Init()
for _, call in ipairs(pendingCalls) do
  <Sys>Ui[call.functionName](table.unpack(call.args))
end
```
这是跨系统早期调用不丢事件的标准写法。

### 4.4 `Types.System`
位于 `configs/Types.lua`：
```lua
export type System = {
  Remotes: { RemoteEvent },
  whiteList: table,
  IsLoaded: boolean,
}
```
注解用即可，字段增减不会触发类型错误。

---

## 5. 数据层

### 5.1 持久化
- `ServerStorage/libs/ProfileService.lua`（第三方）+ `ServerStorage/modules/DataManager.lua`（封装层）。
- `DataManager` 自己监听 `Players.PlayerAdded`：`ProfileStore:LoadProfileAsync("Player_"..UserId)` → `profile:Reconcile()` → 在 `player` 下建 `profileLoaded` BoolValue。
- `GameConfig.IsDebug`（通常 `= IsStudio and <flag>`）为真时用 `configs/DebugData.lua` 覆盖 profile 数据。
- **离服释放由 `SystemMgr` 编排调 `DataMgr:ReleaseProfile(player)`**，`DataManager` 内部**不要**再去 hook `PlayerRemoving`。

### 5.2 服务端玩家实例：`PlayerServerClass`
- 单例 `playerInsList[UserId]`，`PlayerServerClass.GetIns(player[, createIfNil])` 取或懒建。
- 常用 API：`GetOneData / SetOneData / AddOneData / GetAllData / ResetPlayerData / ResetPlayerOneData / LogOnboarding / IsVip`。
- `OnChatted` 作为开发者聊天指令入口（通常限 `GameConfig.DevIds` 或 `RunService:IsStudio()`）。
- `RemoveIns(player)` 由 `SystemMgr` 在离服末尾调用。

### 5.3 客户端数据镜像：`Systems/ClientData.lua`
- `PlayerSystem.Client:PlayerAdded(player, { data = allData })` 把服务端 profile 全量打给客户端。
- 客户端 `ClientData.InitData(data)` 设 `_Data`，挂 `initialized` BoolValue。
- 所有客户端读/写玩家数据都走 `ClientData:GetOneData / GetAllData / SetOneData / SetDataTable`。
- **规则**：不要自己再复制一份持久字段到别的客户端容器里。

### 5.4 增/删持久字段的五处联动
1. `configs/Keys.lua` 的 `Keys.DataKey` 加/删键名（键表被 `table.freeze` + `errorOnNil`，访问未登记键会直接报错）
2. `configs/DefaultData.lua` 加/删默认值（ProfileService `:Reconcile()` 会以此补齐老玩家）
3. `configs/DebugData.lua` 按需同步
4. 运行时读写点（系统 `Presets.lua` / `init.lua` / `ui.lua`）
5. 所有展示/任务/奖励引用该字段的位置

### 5.5 表驱动内容（可选框架模式）
如果项目有 `Excels/` + `ReplicatedStorage/ExcelConfig/`：
- 设计师改 `.xlsx` → 跑 `Excels/ExcelToLua3.py` 生成 `ExcelConfig/<Name>.lua`
- 运行时**不要**直接编辑 `ExcelConfig/*.lua` 的字面内容（会被下次导出覆盖）。
- 聚合/派生逻辑放到各系统的 `Presets.lua` 里。

---

## 6. 通用工具

常见且跨项目复用的模块（具体项目的存在情况见 `PROJECT_LOGIC.md`）：

| 模块 | 用途 |
|---|---|
| `modules/ScheduleModule` | 统一的周期任务（单个 Heartbeat 跑多个 schedule），`AddSchedule(interval, fn)` / `CancelSchedule(id)` |
| `modules/TableModule` | `DeepCopy` 等表工具 |
| `modules/Util` | 杂项（`Round`、`awardBadge`、`randomByProbability` 等） |
| `modules/TweenModule` | 自定义 Easing + Tween 包装 |
| `modules/Zone` | Zone+ 区域检测 |
| `modules/Bezier` / `modules/Preojectile` / `modules/SpaceModule` | 轨迹、弹道、空间工具 |
| `modules/GAModule` | Game Analytics 接入 |
| `StarterGui/Main/uiController.lua` | **UI 交互统一入口**（按钮 Hover/Click/Ripple、通知、遮罩、blur、modal） |

**硬性约定**：
- 按钮交互**一律**走 `uiController.SetButtonHoverAndClick`，不要手连 `MouseEnter/MouseButton1Click`。
- 周期任务**一律**走 `ScheduleModule`，不要写 `while task.wait() do` 死循环。

---

## 7. 命名与常量约定

### 7.1 `configs/Keys.lua`
- 所有子表都 `setmetatable(t, errorOnNil)` + `table.freeze`，**未登记的 key 抛错**。
- 常见子表：`DataKey / ItemType / QuestType / Rarity / CollisionGroup / Tags / BattleSates / PetStates / WeaponTypes / ...`。
- 新增值时同表追加并保持命名风格。

### 7.2 `configs/GameConfig.lua`
- 版本、`IsDebug`、`GroupId / UniverseId / DevIds`、时间常量（`HalfMinute / OneMinute / OneHour / OneDay / OneWeek`）、`Badges` 映射等。
- Debug 分支通常会把时间常量调短方便测试（本框架常见做法）。

### 7.3 字符串
- Luau 反引号插值 `` `Hello {player.Name}` ``；**不要**用 `string.format` 做普通插值。

---

## 8. 编码习惯（LLM 在本仓库写代码前，**必读本节**）

这是**一站式清单**。AGENTS.md 的 Non-Negotiables 是精简版；`.cursor/rules/*.mdc` 是 Cursor 专属注入版；三者内容必须保持一致，以本节为准。

### 8.1 字符串与控制流
1. **反引号插值**：`` `Hello {player.Name} dealt {damage}` ``。不要用 `string.format` 做普通插值。
2. **不写 `do ... end` 块**。用函数、`if`、`for`、`while` 等控制结构来表达作用域。
3. **直白控制流 > 巧妙技巧**。别为省两行代码上复杂的三目/巧表达式。

### 8.2 防御性编程
4. **项目自持的路径不加 nil 保护**。确定性的资源/配置/UI 路径（`script.Presets`、`Replicated.configs.X`、`PlayerGui.Main.<known>` 之类）直接用，让坏配置在开发期炸出来。
5. **防御性检查只用于真正可选的 runtime state**：玩家驱动的缺席、跨系统时序问题、网络竞态。
6. **基于玩家事件的操作前再确认玩家仍在场**：`player:IsDescendantOf(Players)` 或 `PlayerServerClass.GetIns` 返回 nil 时果断 `return`。SystemMgr 在 remote 入口已经做了一层，但系统内部异步逻辑（`task.spawn` 后、延迟触发后）需自己再判一次。

### 8.3 文件形状（详 §4.2）
7. **系统 `init.lua` 顶部分段顺序固定**：services → requires → common vars → server vars → client vars → system table → `if IsServer then ... else ... end` → `GetSystemMgr` → `Init` → `PlayerAdded` → `PlayerRemoving` → 其他业务方法 → `---- [[ Both Sides ]] ---- / Server Only / Client Only` → 末尾 helper → `return`。
8. **业务方法保留 `if IsServer then ... else ... end` 双分支**（非 `whiteList` 的方法），即使一边是空占位。扫读时要一眼看出两端各干什么。
9. **helper 函数放文件末尾**。不为前置声明把 helper 挪到 lifecycle 之上；Luau 支持调用后定义。helper 多时按 `common / server-only / client-only` 分组（可用注释段标题）。
10. **不预声明 `local f` 再赋值**。除非真的有循环引用或编译时需要。

### 8.4 抽象与复用
11. **只在满足以下之一才抽 helper**：被复用、非平凡、或显著提升可读性。一次性短逻辑内联就好。
12. **不要包小 wrapper**，比如一个只 `return x.y.z` 的 helper。
13. **explicit names over clever shortening**：`playerIns` 好过 `p`；`totalOreScore` 好过 `s`。
14. **相关逻辑物理相邻**，除非复用需要抽走。
15. **匹配已有风格**：改旧文件时不强推新风格；新文件套本节规则。

### 8.5 架构
16. **不发明 `IsServer / SENDER / SystemMgr / GetSystemMgr / self.Client / AllClients / Server / whiteList` 的替代品**。
17. **实现顺序：服务端逻辑先，客户端逻辑后**。跨端功能先让服务端权威流程跑通再接 UI。
18. **避免系统间循环 require**。`SystemMgr` 用 `GetSystemMgr()` 懒加载模式规避；新系统如需引用他系统，沿用此模式。
19. **不存大量长期 state 不给清理路径**。每个系统自持缓存必须有 `PlayerRemoving` 或显式 TTL。
20. **广播用 `self.AllClients`，不要用 `self.Client` 循环广播所有玩家**。
21. **非关键高频广播加 `args.unreliable = true`**（走 `UnreliableRemoteEvent`）。
22. **不要 hook `Players.PlayerRemoving` 释放 profile 或清 `playerInsList`**——`SystemMgr` 编排。

### 8.6 通用工具
23. **按钮交互用 `uiController.SetButtonHoverAndClick`**，不要手连 `MouseEnter / MouseButton1Click`。
24. **周期任务用 `ScheduleModule.AddSchedule`**，不要写 `while true do task.wait(...) end`。长任务记下 `scheduleId` 以便取消。

### 8.7 数据层
25. **持久字段新增/删除**：`Keys.DataKey` + `DefaultData` + `DebugData` + 运行时读写点 + 下游消费者，**同一次改动里**全部落地。
26. **客户端别自建 profile 字段缓存**，走 `ClientData`。
27. **不直接编辑 `ExcelConfig/*.lua` 字面量**——改 xlsx 再导出。聚合/派生放 `Presets.lua`。

### 8.8 测试与收尾
28. **离开前清 debug `print`**，保留必要 `warn`。
29. **关键路径用 `pcall`**；`SystemMgr` 已在非 Studio 环境下为 remote 套 pcall，业务内部不必再套一层，除非真有可能失败。
30. **Studio 验证覆盖：init → 运行 → 离服 cleanup → 再登陆 profile 正确**；跨端功能走 Team Test。

---

## 9. 开发工作流（与框架相关的部分）

### 9.1 新增系统
1. 复制 `Systems/Template/` 改名
2. 按需增删 `Presets.lua / ui.lua / Modules/`
3. 在 `SystemMgr.lua` 的 `systems` 里 `require` 它
4. 只有需要优先初始化才加进 `LoadOrder`
5. 服务端方法首参 `sender` 并判断 `~= SENDER then return`；内部工具放 `whiteList`

### 9.2 新增持久字段
→ §5.4 五处联动。

### 9.3 跨系统调用
```lua
local SystemMgr = require(Replicated.Systems.SystemMgr)
SystemMgr.systems.BackpackSystem:DeleteItems(SENDER, player, { items = ... })
```

### 9.4 测试
- 先在 Studio 单机跑通 Init / 运行 / 离服 cleanup / 再登陆 profile 校验。
- 跨端功能用 Team Test 多客户端。
- 离开前清 debug `print`，保留必要 `warn`。

---

## 10. 反模式清单（别干）

- ❌ 自己挂 `Players.PlayerRemoving` 去释放 profile 或清 `playerInsList`（由 `SystemMgr` 编排）。
- ❌ 给未经 `whiteList` 保护的方法暴露敏感操作——客户端可以通过伪造 RemoteEvent 调到。
- ❌ 绕开 `ClientData`，自己在客户端里复制一份服务端 profile 字段。
- ❌ 直接编辑 `ExcelConfig/*.lua` 的字面数据（会被下次导出覆盖）。
- ❌ 在系统 `init.lua` 里堆一切业务逻辑；复杂逻辑应拆到 `Modules/` 或 `Presets.lua`。
- ❌ 写 `while true do task.wait() end`；用 `ScheduleModule`。
- ❌ 手连按钮事件绕过 `uiController`。
- ❌ 把"当前任务进度/TODO/决策"写到本文件或 `PROJECT_LOGIC.md`——那是 `TASK_STATE.md` 的事。

---

## 11. 与其他文档的分工

- **本文件（`FRAMEWORK.md`）**：跨项目复用的框架机制与约定。项目间几乎不改。
- **`PROJECT_LOGIC.md`**：仅本项目的事实（活跃系统列表、业务玩法主线、已知遗留、速查）。换项目就重写。
- **`TASK_STATE.md`**：当前在做什么、下一步是什么。每次会话都会写。
- **`AGENTS.md`**：跨工具通用规则（读文档顺序、维护纪律、风格硬性要求）。
- **`.cursor/rules/*.mdc`**：Cursor 专属，`alwaysApply` 注入。
