# FlipACoin 首发路线图与进度

最后更新：2026-05-01

> 迁移说明：这份文档是 2026-04-14 的首发路线图历史快照。当前任务状态、下一步、验证记录和 backlog 已移动到 `docs/TASK_STATE.md`。

## 当前版本目标

- 目标版本：Flip A Coin 首发版
- 范围：只覆盖首发主线 `P0-P3`
- 不纳入当前开发：`P4 / v1.1` 内容，如 Fate Cards、私人桌主题、更完整个性化外观、赛季化扩展

## 历史整体状态快照

- `P0`：已完成
- `P1`：进行中
- `P2`：未开始
- `P3`：未开始

## 历史“当前正在做”快照

- 在 Studio 实机里继续观察 8 人同桌时的 Billboard、观战 UI 和 streak 高光视觉密度，并开始准备 P2 首发成长闭环

## 历史“下一步”快照

1. 在 Studio 实机里继续观察 8 人同桌时的 Billboard、观战 UI 和 streak 高光视觉密度
2. 清理 `PlayerSystem` 旧 `power / rebirth` 展示并统一首发头顶信息
3. 开始轻量 `RebirthSystem` 与 Auto Flip 的首发接入

## 当前已完成

### 2026-04-14

- 已补完同桌玩家更多可视信息同步：
  - 玩家名
  - 当前 streak
  - 当前装备硬币
  - Cash / 当前状态文案
- 已补完观战体验和桌边 Billboard 信息同步：
  - 桌边 Billboard 运行时生成与服务端统一刷新
  - 客户端桌况面板与旁观信息补完
  - 抛币 / 升级后同桌信息实时同步
- 已修复 `Space` 作为抛币键时会触发默认跳跃并导致离座的问题
- 已将抛币输入改回按钮触发，并恢复跳跃离座
- 已修复连续快速点击 `Flip` 时可能卡在 `Flipping...` 但实际未抛币的问题
- 已补完 streak 播报高光表现基础版：
  - `3 / 5 / 7 / 9 / 10` 分层高光条幅
  - 顶部 streak banner
  - 可选音效接线与缺资源静默回退
  - `10` 连提示升级为全桌聚焦文案

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
- 已完成正式 flip 表现首版：
  - 基于 `CoinFlipTable` 当前 Attachment 的起落点
  - 硬币抛出到桌面中心的可视弧线
  - 正反面可见的翻转表现
  - 落桌停留与落点脉冲反馈
  - HUD 结果文字高亮反馈
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

- 正式 flip 表现已补入首版，但仍需要在 Studio 实机里继续观察以下细节：
  - 8 人同桌同时抛币时的视觉密度
  - 不同机位下正反面可读性
  - 桌面中心落点和 pulse 强度是否需要再收
- `PlayerSystem` 仍残留旧项目 `power / rebirth` 表达，后续需要改成服务当前玩法的头顶和成长展示
- `docs/FlipACoin_开发优先级清单与系统任务表.md` 中仍有 `BaseSystem` 相关旧描述，后续阅读代码时应以当前 `AGENTS.md` 和实际代码为准

## 系统进度表

| 系统 | 状态 | 当前结论 |
| --- | --- | --- |
| `CoinFlipSystem` | 进行中 | 已完成服务端权威结算、升级、HUD 同步、正式 flip 表现首版，并补完多人观战侧的桌况同步；待完成 Auto Flip、功能硬币接入、Fever 接入 |
| `TableSeatSystem` | 进行中 | 已完成占座、离座、AFK、状态同步、同桌信息展示、观战桌况面板和 Billboard 同步；后续转入 8 人同桌实机观察与细收 |
| `AnnouncementSystem` | 进行中 | 已完成基础 streak 播报、去重、高光条幅和基础音效接线；后续可继续补更强的 10 连庆祝 VFX / SFX |
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
- 正式 flip 表现首版已完成：
  - 硬币抛出
  - 翻转
  - 落桌停留
  - 正反面视觉差异
- 输入节流、结果反馈、视觉清理已补首版收尾

待完成：

- 无，P0 进入完成态，后续仅保留体验打磨

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
- 同桌玩家更多可视信息：
  - 玩家名
  - 当前 streak
  - 当前装备硬币
- 观战体验基础版
- 桌边 Billboard 信息同步
- `Space` 抛币输入已修复，不再触发默认跳跃离座
- streak 播报高光强化基础版：
  - `3 / 5 / 7 / 9 / 10`
  - 顶部高光 banner
  - `10` 连全桌聚焦提示

待完成：

- Studio 实机验证与体验细收

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

## 历史 backlog 快照

- `P4 / v1.1`：
  - Fate Cards
  - 更完整的个性化外观
  - 私人桌主题
  - 排行榜扩展
  - 赛季化内容

## 文档维护规则

- 本文件不再作为实时状态文档维护。
- 后续任务状态、下一步、验证记录、backlog 统一维护在 `docs/TASK_STATE.md`。
- 本文件只在需要保留或更正历史路线图快照时更新。
