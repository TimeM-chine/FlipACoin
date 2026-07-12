# TASK_STATE

最后更新：2026-07-12

> 本文件只记录当前 live task。2026-07-11 以前的首发准备状态已压缩到 `docs/archive/TASK_STATE_DONE_2026-06-17_TO_2026-07-11.md`。

## Active

- **任务：发布闭环与可复现 QA**
- 当前发布建议：完成本任务后进入 `SOFT LAUNCH` 小规模公开测试；不是证明留存或商业化已经成功。
- 当前阶段：Studio QA、通知抢占、单客户端情景、30分钟长测、2/8客户端和真实设备已完成；Table Bonus专项和多人真实素材仍待验收。

## Current Baseline

- 当前活跃主线由 `SystemMgr.lua` 决定：自动入座、服务端权威 Flip、局内升级、Rebirth、多币、装备、弱社交反馈和固定商品商业化均已接入。
- 单客户端已验证自动入座、`Space` Flip、Tails Cash、死亡回座和成长面板打开/关闭；横屏设备模拟已覆盖小屏手机和 iPad。
- 真手机、平板、手柄和2/8客户端已由用户确认通过；Table Bonus因规则此前不清楚，仍需2客户端专项复核。
- 仓库已有游戏 icon 和三张渲染式市场图；真实运行 HUD、同桌高光和成长截图仍需补齐。

## Goals

1. 在不重做当前手机布局的前提下提高核心触控可靠性并消除关键文字溢出。
2. 让同桌广播不遮挡 Flip、结果、引导或成长面板操作。
3. 让玩家只用手柄完成 Flip、升级、浏览、购买、装备、Rebirth 和关闭面板。
4. 拉开 Tails、Heads、streak、Perfect/Edge Stand、Perfect Five/Table Bonus 的现有反馈层级，并强化升级购买后的可感知变化。
5. 完成新档、Rebirth、多币、双客户端、满桌和 UI 生命周期验收。
6. 补充真实运行发布截图及短视频镜头方案，并重新评估上线准备度。

## Non-Goals

- 不新增图鉴、任务、强社交、Timing Bonus 或其他玩法系统。
- 不修改存档 schema、商品 ID、商品发货、经济公式、Rebirth 成本或系统注册。
- Product receipt 模块有多个项目的长期使用记录，本任务不把理论故障窗口列为 P0，也不修改该模块。
- 不启用已注释的旧 mobile profile，不整体重做用户已完成的手机 UI。
- 不自动修改 Creator Dashboard；真机和真手柄最终手感由用户人工确认。

## Progress

- [x] 将旧 live task 状态压缩归档，并重置 `TASK_STATE.md`。
- [x] 扩大核心触控命中区域，修复小横屏 FLIP 文字适配；在不重排升级网格的前提下保证命中区零重叠。
- [x] 收敛广播单频道、优先级和面板态抑制；高优先级高光可抢占普通 streak。
- [x] 完成长面板初始焦点、二维导航、滚动跟随、肩键分类和关闭后焦点恢复的源码实现。
- [x] 调整现有 Flip 与升级反馈层级；升级同步时展示关键数值前后变化。
- [ ] 完成新档 Rebirth、多币、双客户端和满桌验收；单客户端 Flip、死亡回座和面板 sanity 已通过。
- [x] 完成 100 次面板开关生命周期观察；`uiController` 未挂载对象由约 606 个 TextButton 降为 2 个 Tween，循环后无增长。
- [x] 完成修复后完整30分钟高频 Flip：818次真实服务端结算，UI/输入/错误稳定，EffectSystem Highlight 未挂载增长已关闭。
- [ ] 补齐真实同桌高光和真实多 Coin/Rebirth 截图；素材排序、描述和短视频镜头已写入 `docs/LAUNCH_MEDIA_GUIDE.md`。
- [x] 将手柄检测改为运行时输入类型；透明 SelectButton 退出焦点图，实际 Buy/Equip 聚焦时更新卡片和 Preview。
- [x] 肩键分类改为读取面板 `GrowthCategory`；Rebirth 禁用操作保留浏览焦点并在回调前显式拒绝请求。
- [x] 重写遗留 `TestSystem`，仅 Studio 注册并提供 Fresh、Upgrade、Rebirth、Coin Spread、2-5 Coin、Perfect Five、Edge Stand 和 Long Session 情景。
- [x] 情景先恢复完整 DebugData，再通过生产 baseline、状态同步和一次性服务端结果 hook 进入真实业务/表现路径；Fake Player 被排除。
- [x] DebugData 保持新档 Cash `$9`，仅将 Studio SFX 恢复为可听。
- [x] 在 Studio 创建 `Frames.StudioQA` 面板实例；11 个情景按钮使用 Scale 布局，QA 打开时隔离教程/通知遮挡并在关闭后恢复。
- [x] 单客户端完成 Fresh、Upgrade、Rebirth、Coin Spread、Multi Coin 2–5、Perfect Five 和 Edge Stand；真实请求与 HUD 同步通过。
- [x] 完成 A06、iPhone 17 Pro 和 iPad Pro M5 13 横屏模拟；修复 iPhone 安全区下 FLIP `TextFits=false`。
- [x] 完成 50轮五面板显隐 + 10次五币 Flip 短稳定性抽样，无持续对象或内存增长证据。
- [x] 将四项升级按钮的透明命中层和新手引导 ripple 隔离到 `OverlayElements` 文件夹，避免被按钮内 `UIListLayout` 排版并挤压 Title/Level/Cost。
- [ ] 完成Table Bonus专项及多人真实素材验收；证据表见 `docs/LAUNCH_QA_EVIDENCE.md`。
- [x] 补全 Long Session 的 Studio 自动 Flip 驱动、7条采样历史、SceneAnalysis 未挂载实例趋势和 runtime error 计数；完整30分钟结果正在执行。
- [x] 增加 `notificationPriority` Studio 情景和购买 `entry / prompt_result / delivery` 三阶段漏斗；Product receipt 判定保持不变。
- [x] 输出首批事件字典、人工设备/Team Test 清单和 Creator Dashboard 待发布配置包。

## Next

1. 用2客户端触发真实玩家Perfect Five，确认另一真实玩家获得Table Bonus `$15`。
2. 捕获双客户端真实高光素材后重新评估 `SOFT LAUNCH`。

## Decisions

- 视觉改动采用保守微调：保持布局和美术，优先扩大透明命中区、避让遮挡和复用现有反馈资源。
- Studio 负责可视结构和命中区；Luau 负责绑定、显隐、焦点、队列和动态反馈。
- 仅在 100 次面板开关证明未挂载对象持续增长后修复 `uiController` 生命周期，不做推测性重构。
- 自动化只能证明实例、输入、同步和尺寸事实；真机触控、手柄手感、音效强度和相机舒适度必须人工确认。

## Manual Validation

- [x] 真手机横屏拇指操作和安全区。
- [x] 真平板布局和触达距离。
- [x] 真手柄完整路径和焦点可见性。
- [x] 双客户端同桌反馈的噪音、遮挡和同步观感。
- [x] VFX/SFX 层级及 coin-follow 相机舒适度。

## Recent Done

- 2026-07-12：用户确认2/8客户端、手机、平板和手柄通过；运行验证notificationPriority抢占计时，并移除Rebirth攒钱提示中的无效重复FLIP按钮，保留真实主FLIP高亮。
- 2026-07-12：补全 Long Session 自动驱动与采样，定位并修复 EffectSystem Highlight Tween 持有链；修复后完整30分钟818次真实结算通过，输出购买漏斗、事件字典、人工QA和Dashboard配置包。
- 2026-07-12：修复升级卡透明命中层和引导 ripple 参与 `UIListLayout` 的布局回归；Studio Play 验证四项文字位置恢复、递归命中绑定有效且引导层不再挤压内容。
- 2026-07-12：完成运行时手柄焦点硬化、Studio-only QA 情景服务端、一次性稀有结果 hook、Long Session 采样和发布证据表；Studio 面板与运行验收仍明确未完成。
- 2026-07-12：通过 Studio MCP 完成 QA 面板、全单客户端情景、A06/iPhone/iPad 横屏和短稳定性验收；修复 QA 初始化竞态、遮挡隔离及 iPhone FLIP 文字适配。
- 2026-07-11：重置 live task board；旧首发准备状态已归档，本任务成为唯一 Active。
- 2026-07-11：完成触控命中区、FLIP 文字、广播单频道、手柄导航、升级反馈和按钮连接强引用修复；单客户端及 100 次面板循环自动验证通过。
