# FlipACoin 首发路线图与进度

最后更新：2026-04-13

## 当前版本目标

- 目标版本：Flip A Coin 首发版
- 范围：只覆盖首发主线 `P0-P3`
- 不纳入当前开发：`P4 / v1.1` 内容，如 Fate Cards、私人桌主题、更完整个性化外观、赛季化扩展

## 当前整体状态

- `P0`：进行中
- `P1`：进行中
- `P2`：未开始
- `P3`：未开始

## 当前正在做

- 梳理并固化首发路线图与持续进度记录文档，作为跨对话 / 跨设备的统一上下文入口

## 下一步

1. 完成正式的 flip 表现
2. 补完同桌多人可视信息与旁观体验
3. 补完 streak 播报的高光表现与音效层级

## 当前已完成

### 2026-04-13

- 已建立首发路线图与进度文档，后续开发统一以本文件记录当前状态
- 已将 `AnnouncementSystem`、`CoinFlipSystem`、`TableSeatSystem` 调整回项目当前手写系统工作流，不再以 `BaseSystem` 作为默认依赖
- 已确认当前主线启用系统为：
  - `PlayerSystem`
  - `CharacterSystem`
  - `GuiSystem`
  - `MusicSystem`
  - `CoinFlipSystem`
  - `TableSeatSystem`
  - `AnnouncementSystem`
- 已完成多人入座后显示 Flip HUD 的基础链路
- 已完成服务端权威抛币基础逻辑：
  - 抛币请求
  - 正反判定
  - streak 计算
  - Cash 结算
  - 四项升级购买
  - runData 存档
- 已完成基础座位系统：
  - 坐下占座
  - 离座释放
  - AFK 踢座
  - 座位状态同步
- 已完成基础播报系统：
  - `3 / 5 / 7 / 9 / 10` 连正面阈值检测
  - 基础去重与通知播报
- 已补入首发玩法相关数据字段：
  - `fateShards`
  - `bestStreak`
  - `lifetimeFlips`
  - `lifetimeHeads`
  - `lifetimeCashEarned`
  - `equippedCoin`
  - `ownedCoins`
  - `rebirthTree`
  - `autoFlipUnlocked`
  - `runData`

## 阻塞与风险

- 当前 Flip 视觉表现还未达到首发标准
  - 玩家已经能坐下并看到 HUD
  - 但还需要正式的“硬币模型向上抛出、翻转、落桌”的完成版表现
- `PlayerSystem` 仍残留旧项目 `power / rebirth` 表达，后续需要改成服务当前玩法的头顶和成长展示
- `docs/FlipACoin_开发优先级清单与系统任务表.md` 中仍有 `BaseSystem` 相关旧描述，后续阅读代码时应以当前 `AGENTS.md` 和实际代码为准

## 系统进度表

| 系统 | 状态 | 当前结论 |
| --- | --- | --- |
| `CoinFlipSystem` | 进行中 | 已完成服务端权威结算、升级、HUD 同步；待完成正式 flip 表现、Auto Flip、功能硬币接入、Fever 接入 |
| `TableSeatSystem` | 进行中 | 已完成占座、离座、AFK、状态同步；待完成更完整的同桌信息展示与旁观体验 |
| `AnnouncementSystem` | 进行中 | 已完成基础 streak 播报与去重；待完成高光表现、音效、10 连庆祝升级 |
| `PlayerSystem` | 进行中 | 已完成玩家数据下发、leaderstats、Cash 更新；待清理旧 `power / rebirth` 展示并适配首发玩法 |
| `CharacterSystem` | 进行中 | 已完成角色头顶 UI 挂载基础链路；待配合同桌信息展示做首发适配 |
| `GuiSystem` | 进行中 | 已可承接基础通知；待统一 streak、rebirth、任务、奖励等消息入口 |
| `MusicSystem` | 未开始 | 仍未正式接入首发玩法播报与高光音效 |
| `TableHypeSystem` | 未开始 | 首发 P2 目标，尚未实现 |
| `RebirthSystem` | 未开始 | 旧系统不可直接复用，需按 Flip A Coin 轻量重写 |
| `CoinLoadoutSystem` | 未开始 | 首发 6 枚功能硬币与装备逻辑尚未开始 |
| `DailySystem` | 未开始 | 旧签到逻辑不可直接复用，需按新版任务重写 |

## 首发开发顺序

1. `CoinFlipSystem`
2. `TableSeatSystem`
3. `AnnouncementSystem`
4. `PlayerSystem / CharacterSystem` 配套适配
5. `TableHypeSystem`
6. 轻量 `RebirthSystem`
7. `CoinLoadoutSystem`
8. 新版 `DailySystem`
9. `GuiSystem / MusicSystem` 表现与通知统一
10. 埋点、移动端与发布前打磨

## 详细路线图

### P0：玩法底座与单人闭环

目标：先让玩家坐下后能稳定抛币、升级、结算、离线恢复。

已完成：

- 首发相关核心数据字段已落库
- `wins = Cash` 基本兼容路径已建立
- `CoinFlipSystem` 已接入 `SystemMgr`
- 单人抛币、升级、数值同步已打通
- Flip HUD 已出现并可操作

待完成：

- 正式 flip 表现：
  - 硬币模型或等价正式资源
  - 抛出
  - 翻转
  - 落桌停留
  - 正反面视觉差异
- 输入节流、结果反馈、视觉清理收尾

P0 完成标准：

- 1 名玩家进服能坐下并抛币
- 服务端权威生成结果
- 客户端能稳定看到自己的结果与数值变化
- 离开重进后 `runData` 能正确恢复
- flip 表现达到首发可接受标准

### P1：多人圆桌闭环

目标：从“自己能抛”升级为“8 人同桌可看、可围观”。

已完成：

- 基础占座 / 离座 / AFK
- 其他玩家基础结果同步
- 基础 streak 播报

待完成：

- 同桌玩家更多可视信息：
  - 玩家名
  - 当前 streak
  - 当前装备硬币
- 观战体验补完
- 桌边 Billboard 信息同步
- streak 播报高光强化：
  - `3 / 5 / 7 / 9 / 10`
  - `10` 连全桌庆祝

P1 完成标准：

- 同桌玩家能看到彼此抛币表现
- 座位占用和释放稳定
- 热门 streak 播报不会乱序或重复
- 服务器满 8 人时仍可正常同步

### P2：首发成长闭环

目标：把“能玩”升级成“能留人”。

待完成：

- 轻量 `RebirthSystem`
- `CoinLoadoutSystem`
- 6 枚首发功能硬币
- `TableHypeSystem`
- Auto Flip 解锁与控制
- 新版 `DailySystem`
- Profile XP 和基础奖励投放

P2 完成标准：

- 玩家完成 1 次 rebirth 后能明显感受到开局变强
- 同桌行为会推动 Table Fever
- 日常任务能稳定刷新、推进和领奖
- 功能硬币能改变起手体验，但不会压过四核心升级

### P3：首发表现与运营层

目标：让首发版本具备传播性、打磨度和基础数据观测能力。

待完成：

- 庆祝 VFX / SFX
- 桌面表情系统
- 基础商城和 gamepass 接入
- 核心埋点
- 头顶信息、leaderstats、通知文案统一整理
- 移动端和触屏操作适配

P3 完成标准：

- `10` 连正面的高光时刻足够强
- 常见埋点能支撑留存和转化分析
- 移动端能完整进行抛币、升级、rebirth

## backlog

- `P4 / v1.1`：
  - Fate Cards
  - 更完整的个性化外观
  - 私人桌主题
  - 排行榜扩展
  - 赛季化内容

## 文档维护规则

- 后续每完成一个明确任务后，必须更新本文件
- 每次更新至少同时修改：
  - `最后更新`
  - `当前正在做`
  - `下一步`
  - `当前已完成`
  - `系统进度表`
- 状态只使用：
  - `未开始`
  - `进行中`
  - `已完成`
  - `阻塞`
- 其他对话继续本项目时，优先先读本文件，再读 `AGENTS.md` 与相关系统代码
