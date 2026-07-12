# Soft Launch Analytics

最后更新：2026-07-12

本文件定义首批玩家的最小观测集。当前没有真实玩家留存、时长或付费数据；下列条件用于发现异常，不是行业基准或成功阈值。

## Event Dictionary

| 问题 | 事件 | 关键字段 / 值 | 能得出的结论 | 不能得出的结论 |
|---|---|---|---|---|
| 玩家是否进入 | `coinflip_session_start` | account age band | 有效会话数量与账户年龄分布 | 留存、获客质量 |
| 是否成功入座 | `coinflip_first_seat_assigned_latency` | duration band、auto/manual、seat | 入座是否完成及耗时区间 | 玩家是否理解座位系统 |
| 是否完成首次 Flip | `coinflip_first_flip_latency` | duration band、input、outcome | 核心操作是否被发现 | 玩家是否喜欢 Flip |
| 是否到达第 10 次 Flip | `coinflip_flip_count_milestone` | milestone=10、duration、outcome | 玩家是否进入重复循环 | 10 次后会否长期留下 |
| 是否完成首次升级 | `coinflip_first_run_upgrade` | upgrade key、level、cash band | 早期成长是否被使用 | 升级节奏已平衡 |
| 是否打开成长面板 | `coinflip_first_growth_panel_open` | panel、source、input | Shop/Boosts/Inventory/Rebirth 是否被发现 | 面板内容是否有吸引力 |
| 是否首次 Rebirth | `coinflip_rebirth` | rebirth count、RP、cash | 玩家是否到达并执行首轮重置 | Rebirth 长期价值已验证 |
| 在何时退出 | `coinflip_session_end` | duration、flip count、last milestone | 退出发生在哪个行为阶段 | 退出原因或 D1 留存 |
| 哪类设备受影响 | `coinflip_device_profile` | device、viewport、input | 漏斗异常是否集中在设备类 | 真机手感或具体机型性能 |
| 是否进入购买漏斗 | `coinflip_purchase_funnel` | entry、type、storeId | 商品入口被点击 | 玩家有购买意愿 |
| Roblox 提示结果 | `coinflip_purchase_funnel` | prompt_result、purchased/cancelled | 提示后确认或取消 | 已可靠发货 |
| 是否完成发货 | `coinflip_purchase_funnel` | delivery、type、storeId | 服务端完成固定商品发货路径 | receipt 模块永远不会出错 |

## Observation Rules

- Studio QA 不发送正式 `AnalyticsSystem`、登录 onboarding 或经济事件。
- Fake Player 不调用真实玩家 Analytics；多人测试需继续核对 Analytics Output 中没有 fake actor 事件。
- 首批数据先按 `deviceClass / viewportBand / inputType` 分层查看，再判断是否是全局问题。
- 购买漏斗必须按 `entry -> prompt_result:purchased -> delivery` 对齐；`entry` 或 `prompt_result` 不代表收入。
- 样本量不足时不得报告 D1、平均 Session、付费率、漏斗转化率或“玩家喜欢/不喜欢”。

## Danger Conditions

- 大量 session 没有对应入座事件：优先检查数据初始化、满桌等待和座位分配。
- 已入座但没有首次 Flip：优先检查首屏引导、输入或设备遮挡。
- 首次 Flip 后、首次升级前集中结束：优先检查早期成本、反馈和升级可发现性。
- 异常只集中在 touch/gamepad 或某 viewport band：先复现设备操作，不调整全局经济。
- 出现 `prompt_result:purchased` 而没有对应 `delivery`：按购买事故调查，发布门禁视为 P0。

