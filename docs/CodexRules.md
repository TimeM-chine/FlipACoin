# Codex Rules For FlipACoin

## 1. 目标

这份 Rules 不是照搬 CursorRules，而是基于：

- `.cursor/rules` 的明确约束
- 当前仓库真实结构
- 你现有代码习惯
- `Flip A Coin` 项目的新阶段需求

提炼出的我在这个仓库里应该遵守的工作规则。

## 2. 项目理解规则

1. 修改任何功能前，先确认它是否真的在 `SystemMgr.lua` 中启用。
2. 先区分“当前 Flip A Coin 需要的系统”和“旧项目遗留系统”，不要默认仓库里的每个系统都仍然有效。
3. 遇到系统依赖时，优先检查 `SystemMgr.systems.XxxSystem` 是否真的被注册，否则按“未启用依赖”处理。
4. 优先从这条主链理解功能：`入口脚本 -> SystemMgr -> 对应 System -> PlayerServerClass/DataManager -> UI`。

## 3. 系统开发规则

1. 新功能优先放进已有系统；只有现有系统职责明显不合适时再建新系统。
2. 新系统目录继续遵守 `SystemName/init.lua + Presets.lua + ui.lua + Assets/` 结构。
3. 新系统若没有兼容性包袱，优先基于 `BaseSystem.lua` 编写，而不是继续复制旧模板。
4. 如果修改的是旧系统，优先顺着现有写法改，避免一次任务里顺手做大规模风格迁移。
5. 只有需要优先启动的系统，才加入 `LoadOrder`。

## 4. 双端通信规则

1. 不在业务代码里随手新建零散 RemoteEvent，跨端调用统一走 `SystemMgr` 自动代理。
2. 服务端发客户端使用 `self.Client:Method(player, args)`。
3. 服务端广播使用 `self.AllClients:Method(args)`。
4. 客户端请求服务端使用 `self.Server:Method(args)`。
5. 只要函数不应该暴露给远程，就加入 `whiteList`。
6. 服务端关键系统方法继续保留 `sender ~= SENDER` 这一层校验，或在 `BaseSystem` 下统一走 `CheckSender()`。
7. 处理服务端远程逻辑时，要考虑玩家可能已经离场，不要绕过 `SystemMgr` 现有的 alive guard 思路。

## 5. 生命周期规则

1. 涉及玩家初始化的系统逻辑，优先放在 `PlayerAdded` 中统一接入。
2. 涉及缓存、连接、任务清理的逻辑，要在 `PlayerRemoving` 中显式处理。
3. 绝不随意改乱当前的离场顺序：
   - 先系统清理
   - 再 `DataManager:ReleaseProfile`
   - 再 `PlayerServerClass.RemoveIns`
4. 玩家数据可写逻辑必须发生在 profile release 之前。

## 6. 数据规则

1. 玩家权威数据只由服务端维护。
2. 服务端读写数据优先经过 `PlayerServerClass`，不要在业务系统里直接散落 `ProfileService` 操作。
3. 客户端本地数据统一通过 `ClientData` 读取和更新。
4. 新增字段时先改：
   - `Keys.DataKey`
   - `DefaultData`
   - 需要时再补 `DebugData`
5. 不要在客户端假设某个数据一定已经初始化，除非它确实经过 `ClientData.InitData()` 或明确等待过初始化标记。

## 7. UI 规则

1. 系统 UI 初始化继续沿用现有模式：
   - 先用 `pendingCalls` 占位
   - 再在客户端 `PlayerAdded` 后 `require(script.ui)`
   - 最后回放积压调用
2. 如果是新系统且使用 `BaseSystem`，优先用 `BaseSystem:InitUI()` 收敛这套流程。
3. 按钮交互优先使用 `uiController.SetButtonHoverAndClick`。
4. 通知、弹窗、倒计时、奖励展示等通用 UI 行为优先复用 `uiController`，不要在系统 UI 里重复造轮子。
5. 做 UI 时优先使用 Scale，照顾移动端、安全区和手柄输入。
6. 用 MCP 或静态方式查 UI 时，路径优先走 `StarterGui`，不是运行期的 `PlayerGui`。

## 8. 配置与常量规则

1. 不硬编码可配置数据，优先放进：
   - `GameConfig.lua`
   - `Keys.lua`
   - `Types.lua`
   - 对应系统的 `Presets.lua`
2. 系统内部的业务配置放各自 `Presets.lua`，不要把系统私有配置挤进全局配置。
3. 改配置前先确认是否会影响旧系统依赖。

## 9. 定时与性能规则

1. 周期任务优先使用 `ScheduleModule.AddSchedule()`，不要随手写常驻 `while true do task.wait()`。
2. 广播频繁但不关键的数据时，优先考虑 `UnreliableRemoteEvent` 语义。
3. 只在关键跨端路径、定时任务、可能失败的外部调用上做 `pcall`，不要把整个代码库写成过度防御风格。

## 10. 代码风格规则

1. 优先使用 Luau 反引号字符串插值，不新增新的 `string.format` 风格代码，除非是在保持旧代码局部一致性。
2. 不使用 `do end` 人工分块。
3. 保持你当前常用的文件布局：
   - `services`
   - `requires`
   - `common variables`
   - `server variables`
   - `client variables`
4. 修改已有系统时，尽量保留原文件头部元信息注释风格。
5. 代码默认直接、清楚、少废话，不为了“看起来安全”加大量无意义 nil 判断。
6. 但下面这些保护仍然是值得保留的：
   - 玩家是否仍在游戏中
   - 远程调用来源
   - 定时任务错误隔离
   - Profile release 时序

## 11. 迁移与重构规则

1. 当前仓库处于“旧系统模板 + 新 BaseSystem 并存”阶段，短任务不主动做全局迁移。
2. 只有在下面情况才顺手推进迁移：
   - 正在新建系统
   - 该系统本来就要大改
   - 迁移能明显减少重复代码且风险可控
3. 对遗留依赖要保持警惕，例如系统代码里引用了当前未启用系统时，先确认是要恢复依赖，还是要裁掉依赖。

## 12. Flip A Coin 特定规则

1. 后续新增玩法系统时，优先围绕策划案建议的核心系统拆分：
   - `CoinFlipSystem`
   - `TableSeatSystem`
   - `TableHypeSystem`
   - `CoinLoadoutSystem`
   - `AnnouncementSystem`
2. 新玩法实现要优先复用现成底座：
   - `PlayerSystem`
   - `GuiSystem`
   - `MusicSystem`
   - `ScheduleModule`
   - `PlayerServerClass`
   - `DataManager`
3. 不为了复用旧 simulator 内容而保留多余复杂度，优先让系统服务当前“多人抛硬币”玩法。

## 13. 执行原则

1. 先确认真实运行链，再动代码。
2. 先保证系统结构正确，再补功能细节。
3. 先保证服务端权威，再做客户端表现。
4. 先复用现有框架，再决定是否抽新层。
5. 修改时尊重仓库现状，但在新代码里逐步朝 `BaseSystem + 更清晰配置边界 + 更少模板重复` 的方向推进。

