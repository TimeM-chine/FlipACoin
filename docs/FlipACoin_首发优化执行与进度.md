# FlipACoin 首发优化执行与进度

最后更新：2026-04-19

## 文档定位

这份文档已按 2026-04-19 的新需求整份重置。

它现在只负责记录这一轮真实执行计划、当前状态和验证结论，用于：

- 跨设备继续推进
- 多 agent 并行接力
- 防止旧的“围观版”方案继续误导实现

后续接手顺序固定为：

1. `docs/PROJECT_LOGIC.md`
2. `docs/FlipACoin_首发优化执行与进度.md`
3. 若要补旧背景，再看 `docs/FlipACoin_首发路线图与进度.md`

如果文档和当前代码冲突：

- 以当前代码为准
- 先回写本文，再继续改

---

## 本轮需求重置

本轮不再继续“围观转化”方向，目标已改为更直接的单人入局体验：

1. 一个服务器可以有多张桌子，但玩家进入游戏后必须自动分配座位并立即坐下
2. 玩家暂时不能离开座位，也不做切桌逻辑
3. 摄像头必须改成第一人称
4. Flip 输入必须同时支持：
   - HUD 按钮点击
   - `Space`
   - 手柄 `RT`
5. `Space` 原本跳跃逻辑必须被禁用，不能让玩家跳出座位
6. 不再显示座位上的 `BillboardGui`
7. 参考给定示意图重做 `Flip HUD`，突出中间主按钮和两侧信息区
8. 所有资源必须预制到 Studio 中，不允许继续靠代码临时生成 UI / Billboard / 世界资源

本轮默认不做：

- 围观机制
- featured seat
- audience 范围收敛
- 空位抢座引导
- 离座按钮
- 手动切桌

---

## 社区检索结论

已先做第一人称方案检索，当前找到两个可参考社区方案：

- [Open FPC](https://devforum.roblox.com/t/open-fpc-a-modern-first-person-camera-system/2507587)
  - 偏现代化、可定制，适合先作为首选评估对象
- [FPX](https://devforum.roblox.com/t/fpx-first-person-experience/3537429)
  - 更新更近，但集成侵入性更强，先不作为第一选择

当前决策：

- 第一人称相机任务不排到最后
- 先按 `Open FPC` 作为优先接入候选
- 若它与“强制坐席 + 禁止离座 + 当前角色链路”冲突过大，再回退到自实现第一人称锁定方案

---

## 当前代码事实

以下是当前代码里已经确认、但与新方案冲突的点：

- `TableSeatSystem` 仍然是 `ProximityPrompt` 入座
- `TableSeatSystem` 仍保留：
  - `RequestStand`
  - AFK 踢座
  - `SeatInfoBillboard`
  - featured seat 计算
  - audience / spectator 同步语义
- `CoinFlipSystem/ui.lua` 仍保留：
  - `CoinFlipSpectatorFeed`
  - `CoinFlipTableOverview`
  - `Leave Seat` 按钮
  - `Jump to leave the seat.` 文案
  - 运行时 `ensure*` 创建 UI 的逻辑
- 当前代码文案里已经出现 `Space flips`，但尚未看到完整冻结为首发正式输入方案的实现闭环
- 当前 UI 仍有大量运行时 `Instance.new` 兜底逻辑，不符合“资源全部预制到 Studio”要求

本轮要做的不是在旧方案上继续加补丁，而是把上面这些冲突点按新需求整批替换掉。

---

## 当前正在做

- 已完成旧进度文档清空与需求重置
- 已完成第一人称社区方案检索
- 已完成 `M0-03` Studio 资源清单冻结
- 已落 `M1-01` 自动分配空座位首版代码，当前等待 Studio Play 回归
- 已落 `M1-02 / M1-03` 强制坐席首版代码，当前等待 Studio Play 回归
- 下一步继续 `M1-01 / M1-02 / M1-03` 的实机验证与脱座回收，不再继续旧的围观任务

---

## M0-03 资源清单冻结结果

清点时间：2026-04-19

清点方式：

- 源码检索活跃系统中的 `Instance.new`、`BillboardGui`、`ProximityPrompt`、`CoinFlipHUD`、`CoinFlipTableOverview`、`CoinFlipSpectatorFeed`、`Camera`、`UserInputService`
- Studio 停止模式检查 `StarterGui.Main.Elements` 与 `Workspace.CoinFlipTable`
- 以 `SystemMgr.lua` 当前注册系统为准，只把首发主线和活跃系统算入本轮资源口径

### 范围冻结

本轮主路径只保留：

- 自动分配座位
- 自动坐下并锁定坐席
- 第一人称相机
- `Flip HUD`
- 点击 / `Space` / 手柄 `RT` 触发同一套 Flip
- 当前现金、streak、概率、速度、四项升级、基础结果反馈

本轮明确退场，不再继续投入：

- 手动抢座 / 空位 `ProximityPrompt` 主流程
- 离座按钮与 `RequestStand` 玩家入口
- 座位 `SeatInfoBillboard`
- `CoinFlipTableOverview`
- `CoinFlipSpectatorFeed`
- `featured seat`
- spectator / audience 方向表现
- 空位抢座引导文案

### 当前 Studio 已有资源

`StarterGui.Main.Elements` 当前已存在：

- `CoinFlipHUD`
  - `Content`
  - `Stats`
  - `Stats.Cash`
  - `Stats.Chance`
  - `Stats.Streak`
  - `Stats.Speed`
  - `Actions`
  - `Actions.FlipButton`
  - `Actions.LeaveButton`
- `CoinFlipOnboarding`
- `CoinFlipTableOverview`
- `CoinFlipSpectatorFeed`
- 对应的 `_backup` 旧资源：`CoinFlipHUD_backup`、`CoinFlipOnboarding_backup`、`CoinFlipTableOverview_backup`、`CoinFlipSpectatorFeed_backup`

`Workspace.CoinFlipTable` 当前已存在：

- `Seats`
- `Seats.Seat01` 到 `Seats.Seat08`
- 每个座位当前都有 `Prompt`
- 每个座位当前都有 `SeatInfoBillboard`
- `Attachments`
- `Assets`
- `Assets.CoinVisuals`
- `TableTop`
- `TableBase`
- `SpectatorZone`

### 必须预制或重做的首发资源

`StarterGui.Main.Elements.CoinFlipHUD` 需要冻结为新的预制结构，不再靠代码补主节点：

- `Content.LeftPanel`
- `Content.LeftPanel.CashCard.Title`
- `Content.LeftPanel.CashCard.Value`
- `Content.LeftPanel.StreakCard.Title`
- `Content.LeftPanel.StreakCard.Value`
- `Content.CenterPanel`
- `Content.CenterPanel.FlipButton`
- `Content.CenterPanel.FlipButton.Label`
- `Content.CenterPanel.ResultLabel`
- `Content.CenterPanel.InputHints`
- `Content.CenterPanel.InputHints.SpaceHint`
- `Content.CenterPanel.InputHints.GamepadRTHint`
- `Content.RightPanel`
- `Content.RightPanel.ChanceCard.Title`
- `Content.RightPanel.ChanceCard.Value`
- `Content.RightPanel.SpeedCard.Title`
- `Content.RightPanel.SpeedCard.Value`
- `Content.RightPanel.UpgradeButtons`
- `Content.RightPanel.UpgradeButtons.ValueButton`
- `Content.RightPanel.UpgradeButtons.ComboButton`
- `Content.RightPanel.UpgradeButtons.SpeedButton`
- `Content.RightPanel.UpgradeButtons.BiasButton`

每个升级按钮必须预制：

- `Title`
- `Level`
- `Cost`
- `UICorner`
- `UIStroke`
- 文本约束或缩放约束

输入提示资源必须预制在 HUD 内：

- `SpaceHint` 用于 PC 键盘提示
- `GamepadRTHint` 用于手柄 `RT` 提示
- 后续代码只负责显隐和改文字，不再 `Instance.new` 创建提示节点

第一人称模块放置边界冻结为：

- 社区模块或回退模块放在 `StarterPlayer.StarterPlayerScripts.Modules.FirstPersonCamera`
- 项目适配脚本放在 `StarterPlayer.StarterPlayerScripts` 或 `CoinFlipSystem` 客户端初始化链路中
- 相机模块只处理本地相机、鼠标锁定、角色局部透明、重生再绑定
- 相机模块不负责座位分配、Flip 请求、HUD 数据刷新

桌面与座位资源保留口径：

- `Workspace.CoinFlipTable.Seats` 保留为自动分配座位池
- `Workspace.CoinFlipTable.Attachments` 保留为相机 / 硬币表现 / 座位锚点候选
- `Workspace.CoinFlipTable.Assets.CoinVisuals` 保留为硬币视觉预制目录
- `Prompt` 后续只允许作为调试或直接禁用资源，不能再是主流程入口
- `SeatInfoBillboard` 后续必须隐藏、禁用或移除，不再进入首发主表现
- `SpectatorZone` 暂不投入；如后续没有其它系统依赖，应在清理阶段退场

### 必须清理的运行时创建点

`src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua` 仍在运行时补造这些主资源或旧表现，后续 `M4` 必须替换为预制绑定：

- `UICorner` / `UIStroke` 兜底
- `TextLabel` 兜底
- `Seat` stat card
- `ResultLabel`
- `UpgradeButtons`
- `UIGridLayout`
- 四个升级按钮
- onboarding 的 `ProgressText` / `Steps`
- table overview rows
- `LeaveSeatButton`
- `UISizeConstraint` / `UITextSizeConstraint` 兜底
- `CoinLandingPulse` 世界 Part

`src/ReplicatedStorage/Systems/TableSeatSystem/init.lua` 当前仍依赖：

- `SeatInfoBillboard`
- `Prompt`
- `featured seat` 状态字段
- billboard 刷新链路

`src/ReplicatedStorage/Systems/AnnouncementSystem/ui.lua` 当前仍运行时创建顶部 banner。若首发继续保留 announcement，需要新增 Studio 预制 banner 模板；若不保留，需要在表现清理阶段退场。

`src/ReplicatedFirst/LoadingScreen/Loader.lua` 仍有加载期运行时创建逻辑。它不阻塞 `M0-03`，但如果“所有 UI 都必须预制”的口径扩展到加载屏，也需要单独列入后续清理。

### M0-03 决策

- `M0-03` 已完成，后续 agent 不需要重新盘点第一批资源。
- `M1` 可以直接开始自动分配和自动坐下，不需要等待 HUD 重做。
- `M4` 必须按上面的新 HUD 结构做 Studio 资源与代码绑定，不允许继续扩展 `ensure*` 兜底创建逻辑。
- `M2` 接入第一人称时按 `StarterPlayer.StarterPlayerScripts.Modules.FirstPersonCamera` 作为模块落点；如果使用 `Open FPC`，也必须包一层项目适配，避免第三方模块直接耦合座位系统。

---

## 新执行顺序

### M0：范围冻结与资源清点

目标：先把旧方向彻底停掉，明确哪些资源必须改成 Studio 预制。

重点内容：

- 冻结本轮“不做列表”
- 盘点当前哪些 UI / Billboard / 世界元素还是运行时代码创建
- 确认新 HUD 需要的 Studio 资源清单
- 确认第一人称模块放置位置和接入边界

完成标准：

- 后续 agent 不会再继续做围观、Billboard、featured seat 方向
- HUD / 输入 / 相机 / 座位所需资源有明确清单

### M1：自动入座与强制坐席

目标：玩家进入游戏后自动落到某张桌子的空座位上，并且不能主动离开。

重点内容：

- 服务端自动分配空座位
- `PlayerAdded / CharacterAdded` 后自动坐下
- 去掉手动入座 prompt 主路径
- 禁止 `RequestStand`
- 禁止跳跃导致的离座
- 暂停 AFK 踢座或改成不会把玩家弹出座位

完成标准：

- 玩家进服后无需操作即可进入可 Flip 状态
- 玩家无法通过跳跃、按钮或默认座椅行为离开座位

### M2：第一人称相机

目标：玩家入局后稳定处于第一人称视角，并与坐席状态兼容。

重点内容：

- 优先评估并接入 `Open FPC`
- 若模块不合适，落回自实现第一人称锁定
- 处理角色坐姿、头部遮挡、镜头穿模、重生后的重新绑定

完成标准：

- 角色坐下后镜头稳定
- 重生、重新入座后仍能恢复第一人称
- 不因第一人称导致无法 Flip 或严重遮挡桌面

### M3：Flip 输入统一

目标：让 PC、键盘和手柄都能用同一套输入闭环完成 Flip。

重点内容：

- HUD 点击触发
- `Space` 触发
- 手柄 `RT` 触发
- 屏蔽默认跳跃
- 确保输入在 HUD 激活、重生、第一人称状态下都稳定

完成标准：

- 点击、`Space`、`RT` 都能触发同一个 `RequestFlip`
- `Space` 不再导致跳跃或离座

### M4：HUD 重做与旧表现清理

目标：去掉旧的围观和桌况表现，只留下主玩家首屏所需信息。

重点内容：

- 删除座位 `BillboardGui` 显示链路
- 删除 spectator feed / table overview / featured seat 相关表现
- 参考示意图重做 `CoinFlipHUD`
- 强化中间 `FLIP` 主按钮
- 两侧分别承载当前现金 / streak / 升级信息
- 所有 HUD 子节点改为 Studio 预制，不再运行时补造

完成标准：

- 玩家一进游戏只看到首屏主玩法 HUD
- 不再出现围观、热门座位、桌况看板相关视觉
- 代码只负责绑定预制资源，不再负责补生成主资源

### M5：回归验证与文档续写

目标：把自动入座、第一人称、输入和 HUD 在真实 Studio 流程里收口。

重点内容：

- 单人进服验证
- 多桌分配验证
- 满桌保护验证
- 重生后重新坐下与重新绑相机验证
- `Space / RT / 点击` 三输入回归
- 文档持续回写

完成标准：

- 新玩家进服即可直接玩
- 不需要 prompt、Billboard、离座按钮
- 多端输入和第一人称都稳定

---

## 任务总表

| ID | 里程碑 | 模块 | 优先级 | 状态 | 验收标准 | 依赖 | 最近更新 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `M0-01` | `M0` | 进度文档重置 | `P0` | `已完成` | 旧围观计划已清空，本文成为新需求下的唯一执行真相 | `PROJECT_LOGIC` | `2026-04-19` |
| `M0-02` | `M0` | 第一人称社区检索 | `P0` | `已完成` | 已确认 `Open FPC` 可作为优先评估候选，第一人称任务不后置 | `M0-01` | `2026-04-19` |
| `M0-03` | `M0` | Studio 资源清单冻结 | `P0` | `已完成` | 已确认当前预制资源、待退场旧资源、新 HUD 预制结构、输入提示节点与第一人称模块放置边界 | `M0-01` | `2026-04-19` |
| `M1-01` | `M1` | 自动分配空座位 | `P0` | `进行中` | 服务端已接入自动分配与 `CharacterAdded` 自动重试，待 Studio Play 确认新玩家进服后稳定落到空座位 | `M0-03` | `2026-04-19` |
| `M1-02` | `M1` | 自动坐下链路 | `P0` | `进行中` | 自动入座已接到 `PlayerAdded / CharacterAdded` 与脱座后回拉逻辑，待 Studio Play 确认角色生成后稳定坐下 | `M1-01` | `2026-04-19` |
| `M1-03` | `M1` | 禁止离座与跳座 | `P0` | `进行中` | 已关闭 `RequestStand` 主路径、禁用跳跃状态与触屏跳跃按钮，待 Studio Play 确认默认座椅行为仍不会把玩家弹出 | `M1-02` | `2026-04-19` |
| `M1-04` | `M1` | 旧 prompt / AFK 逻辑退场 | `P1` | `未开始` | `ProximityPrompt` 不再承担主流程，AFK 不再把玩家踢离座位 | `M1-02` | `2026-04-19` |
| `M2-01` | `M2` | `Open FPC` 评估与接入 | `P0` | `未开始` | 模块已进入 Studio 并能在当前项目链路中工作 | `M0-02`、`M1-02` | `2026-04-19` |
| `M2-02` | `M2` | 第一人称回退方案 | `P1` | `未开始` | 若社区模块不适配，可切回自实现第一人称锁定 | `M2-01` | `2026-04-19` |
| `M2-03` | `M2` | 重生与再绑定 | `P0` | `未开始` | 重生后玩家仍自动坐下并恢复第一人称 | `M1-02`、`M2-01` | `2026-04-19` |
| `M3-01` | `M3` | `Space` Flip 绑定 | `P0` | `未开始` | `Space` 可稳定触发 Flip，且不触发跳跃 | `M1-03` | `2026-04-19` |
| `M3-02` | `M3` | 手柄 `RT` Flip 绑定 | `P0` | `未开始` | 手柄 `RT` 可稳定触发同一个 Flip 行为 | `M1-03` | `2026-04-19` |
| `M3-03` | `M3` | HUD 点击 Flip 统一入口 | `P0` | `未开始` | 点击、`Space`、`RT` 最终都走同一请求路径 | `M3-01`、`M3-02` | `2026-04-19` |
| `M4-01` | `M4` | 移除座位 BillboardGui | `P0` | `未开始` | 不再显示 `SeatInfoBillboard`，相关刷新链路全部停用 | `M1-02` | `2026-04-19` |
| `M4-02` | `M4` | 移除围观 HUD 链路 | `P0` | `未开始` | `CoinFlipSpectatorFeed`、`CoinFlipTableOverview`、featured seat 表现退出主流程 | `M4-01` | `2026-04-19` |
| `M4-03` | `M4` | 新 Flip HUD 预制资源 | `P0` | `未开始` | 参考图中的主按钮、左侧状态、右侧升级区已在 Studio 做成资源 | `M0-03` | `2026-04-19` |
| `M4-04` | `M4` | HUD 绑定改为预制模式 | `P0` | `未开始` | 主 UI 不再依赖运行时 `Instance.new` 补资源 | `M4-03` | `2026-04-19` |
| `M5-01` | `M5` | 单人首轮回归 | `P0` | `未开始` | 玩家进服后自动坐下、第一人称生效、三输入可 Flip | `M1`、`M2`、`M3`、`M4` | `2026-04-19` |
| `M5-02` | `M5` | 多桌与满桌验证 | `P0` | `未开始` | 多张桌子下分配稳定，满桌时有明确降级处理 | `M1`、`M2` | `2026-04-19` |
| `M5-03` | `M5` | 文档续接维护 | `P0` | `进行中` | 每轮实现后都回写本文的状态、决策与测试结论 | `M0-01` | `2026-04-19` |

状态只使用：

- `未开始`
- `进行中`
- `已完成`
- `阻塞`

---

## 关键改造点

### 1. `TableSeatSystem`

后续改造重点：

- 从 `Prompt 入座` 改成 `服务端自动分配 + 自动坐下`
- 停掉 `RequestStand`
- 停掉 AFK 踢座对主流程的影响
- 停掉 `SeatInfoBillboard` 刷新
- 删除 featured seat / audience 相关状态下发

### 2. `CoinFlipSystem/ui.lua`

后续改造重点：

- 不再把未入座 / 观战态当成主路径
- 删除 `Leave Seat`
- 删除 spectator feed / overview / featured 文案
- 重做 `CoinFlipHUD`
- 输入统一改成：
  - 点击
  - `Space`
  - `RT`
- 清掉运行时 `ensure*` 资源补造逻辑，改为绑定 Studio 预制节点

### 3. Studio 资源

必须转为预制的资源至少包括：

- `StarterGui.Main.Elements.CoinFlipHUD`
- HUD 内部主按钮、左侧状态区、右侧升级区
- 相机模块或相机配置容器
- 桌面上真正需要保留的视觉锚点

明确不再继续投入的资源：

- `SeatInfoBillboard`
- spectator feed 相关 UI
- table overview 相关 UI

---

## 当前假设

这几条是当前计划默认假设，若实现中发现不成立，要先改本文再改代码：

1. 玩家重生后仍应被重新放回可用座位，而不是重生后处于自由行走态
2. 如果原座位无效或丢失，允许重生时重新分配空位
3. 多桌存在时，当前阶段只要求“能自动分到某张桌子的空位”，不要求玩家自己选桌
4. 若社区第一人称模块接入成本过高，允许回退到项目内自实现，但优先顺序不变
5. “资源全部预制到 Studio” 的判定口径是：
   - 主资源必须预先存在
   - 代码只负责读、绑、显隐、改字、改值
   - 不再依赖运行时 `Instance.new` 生成主 UI 或主世界资源

---

## 测试与验证记录

### 当前状态

- 本轮已完成需求重置、第一人称社区检索与 `M0-03` 资源清单冻结
- 已完成一次 Studio 资源审计
- 尚未开始真正的 Play 模式行为回归
- 当前第一优先级已切到 `M1-01 / M1-02 / M1-03`

### 已记录验证

#### 2026-04-19 资源审计

测试场景：

- Studio 停止模式检查 `StarterGui.Main.Elements`
- Studio 停止模式检查 `Workspace.CoinFlipTable`
- 源码检索活跃系统中的运行时创建点与旧围观链路

结果：

- `StarterGui.Main.Elements` 当前已有 `CoinFlipHUD`、`CoinFlipOnboarding`、`CoinFlipTableOverview`、`CoinFlipSpectatorFeed` 及对应 `_backup` 资源
- `CoinFlipHUD` 当前只有 `Stats + Actions + FlipButton + LeaveButton` 这一版预制结构，升级区和部分文本仍靠 `CoinFlipSystem/ui.lua` 兜底生成
- `Workspace.CoinFlipTable.Seats.Seat01` 到 `Seat08` 当前全部仍带 `Prompt` 和 `SeatInfoBillboard`
- 仓库当前还没有 `Open FPC` 或其它第一人称模块落地文件

发现的问题：

- 旧围观资源和首发主路径资源还混在一起
- `CoinFlipSystem/ui.lua` 仍大量依赖 `ensure*` 运行时补造主节点
- `TableSeatSystem` 仍把 `Prompt`、`SeatInfoBillboard`、`featured seat` 视为活跃链路

是否影响里程碑状态：

- `M0-03` 可判定完成
- 不阻塞进入 `M1`
- 直接构成 `M4-01 / M4-02 / M4-03 / M4-04` 的实现输入

#### 2026-04-19 自动入座代码级校验

测试场景：

- 改造 `TableSeatSystem` 为服务端自动找空座位
- 关闭客户端与服务端座位 `Prompt` 主路径
- 接入 `PlayerAdded / CharacterAdded` 自动入座重试
- 用 `rojo build` 做工程级解析校验

结果：

- `TableSeatSystem` 已新增空座位选择与自动入座重试逻辑
- 新玩家进入时会绑定 `CharacterAdded`，并在角色可用后自动调用 `RequestSit`
- 当前所有座位 `Prompt` 在代码路径里都会被强制禁用，不再作为主流程入口
- onboarding 的 `sitDown` 现在会顺带补齐 `approachSeat`，不会因 `Prompt` 关闭而卡死
- `rojo build --output build-test.rbxlx` 构建通过，当前改动未出现项目级解析错误

发现的问题：

- 还没做 Studio Play 真机回归，无法确认入服即坐下、满桌等待、重生后再入座的实际表现
- 构建校验时生成了 `build-test.rbxlx` 临时文件，当前因路径访问被拒绝未删除成功，需要后续顺手清理

是否影响里程碑状态：

- `M1-01` 可转为 `进行中`
- 不足以把 `M1-01` 直接转 `已完成`

#### 2026-04-19 强制坐席代码级校验

测试场景：

- 改造 `TableSeatSystem` 的脱座分支，在玩家仍存活时自动回拉到座位
- 让 `RequestStand` 失效，不再清空占座
- 在 `CharacterSystem` 与 `StarterCharacterScripts` 中禁用跳跃
- 隐藏触屏 `JumpButton`
- 清理 `CoinFlipHUD` 中的 `Leave / Jump to leave` 旧提示
- 用 `rojo build --output build-test-2.rbxlx` 做工程级解析校验

结果：

- 座椅 `Occupant` 变空时，若玩家角色仍存活，会直接重新进入自动入座流程
- `RequestStand` 当前不会再触发离座清理，而是回到自动入座逻辑
- 角色生成后会同时在服务端和客户端把跳跃状态关掉
- 触屏跳跃按钮已隐藏
- HUD 默认提示已改成 `Waiting for seat assignment...` 和 `Click FLIP to flip.`
- `rojo build --output build-test-2.rbxlx` 构建通过，当前改动未出现项目级解析错误

发现的问题：

- `CoinFlipSystem/ui.lua` 里旧的 `LeaveSeatButton` 资源和相关兜底函数仍在，只是已隐藏，真正删链路要放到 `M4`
- 还没做 Studio Play 真机回归，无法确认 Roblox 原生座椅状态机会不会在某些边界场景下继续触发脱座
- 构建校验又生成了 `build-test-2.rbxlx` 临时文件，当前未清理

是否影响里程碑状态：

- `M1-02` 可转为 `进行中`
- `M1-03` 可转为 `进行中`
- 两项都不足以直接转 `已完成`

### 计划中的必测场景

1. 自动入座
   - 新玩家进入游戏后是否无需操作就能坐下
2. 禁止离座
   - `Space`、默认跳跃、座椅默认行为、旧离座逻辑是否都无法把玩家弹出座位
3. 第一人称
   - 坐下后镜头是否稳定
   - 重生后是否能恢复
4. Flip 输入
   - 点击、`Space`、手柄 `RT` 是否都能触发 Flip
5. HUD
   - 玩家只看到主玩法 HUD，不再出现观战 / Billboard / 桌况 UI
6. 多桌
   - 多张桌子时能否稳定分配
   - 满桌时是否有清晰降级处理

### 记录规则

每次 Studio 验证后至少补充：

- 测试日期
- 测试场景
- 结果
- 发现的问题
- 是否影响里程碑状态

---

## 对话续接规则

后续任何新对话或新 agent 接手时，默认按下面规则继续：

1. 先读 `docs/PROJECT_LOGIC.md`
2. 再读本文件
3. 优先看：
   - `当前正在做`
   - `新执行顺序`
   - `任务总表`
   - `关键改造点`
   - `当前假设`
   - `测试与验证记录`
4. 如果又出现新需求变更，直接在本文重排，不要叠加旧阶段命名
5. 如果某任务状态变化，必须同步更新：
   - `当前正在做`
   - `任务总表`
   - `测试与验证记录`
6. 如果代码和本文不一致：
   - 先确认代码
   - 再更新本文
   - 不允许带着旧计划继续做

---

## 今日结论

- 旧的“围观优化版”进度文档已失效，今天已整份重置
- 第一人称任务已通过社区检索确认可以前置，不再排最后
- `M0-03` 已完成，当前资源清单、退场资源、相机模块落点和新 HUD 预制结构已经冻结
- 当前新的最高优先级是：
  - `M1-01 / M1-02 / M1-03` 自动入座与禁止离座
  - `M2-01` 第一人称相机接入
  - `M4-03 / M4-04` 预制版 Flip HUD 落地
