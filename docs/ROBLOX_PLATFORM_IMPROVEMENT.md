# Roblox Platform Improvement Plan

更新时间：2026-05-18

## 目的

这份文档记录当前 `Flip A Coin` 面向 Roblox 平台，尤其是移动端首发体验的适配评估和改进建议。

它不是长期策划案，也不替代 `PROJECT_LOGIC.md`。项目事实仍以 `PROJECT_LOGIC.md` 和当前源码为准；本文件只保留平台适配判断、风险和可执行改进项。

## 当前判断

整体方向适合 Roblox。

当前主玩法是单桌 `8` 人、弱社交、高频 `FLIP` 的桌面运气游戏。它具备 Roblox 上比较重要的几个特征：

- 进服后自动入座，玩家不需要先理解复杂大厅规则。
- 核心操作集中在一个明确的 `FLIP` 按钮。
- 单次反馈短，失败也给少量保底 Cash，适合碎片化游玩。
- `Auto:Off / Auto:On` 能降低重复点击疲劳。
- Cash、升级、Rebirth、Coin / Desk / Chair 装扮能支撑基础成长。
- 同桌其他玩家的 flip / streak / 高光反馈能建立弱社交存在感。

更准确的移动端口径是：

> 当前具备基础触屏可玩性，但还没有完成 Roblox 移动端首发级体验收敛。

依据：

- `CoinFlipSystem/ui.lua` 已绑定 Studio-owned `FlipButton` 和 `AutoButton`，触屏端可直接点击主操作。
- `uiClient.client.lua` 已在 `TouchEnabled` 时压低 `UIStroke` 厚度，并隐藏默认 JumpButton，避免当前坐席玩法被跳跃按钮干扰。
- `CoinFlipSystem/Presets.lua` 的 mobile layout 参数已接入 `CoinFlipSystem/ui.lua`，用于触屏端 viewport-specific HUD layout。
- 当前移动端风险主要是 UI 布局、提示、安全区、growth panels 和实机观感，而不是核心操作完全不可用。

## 当前进展

- 2026-05-18：代码侧曾完成 P0-1 / P0-2 的第一轮接入：触屏端隐藏 keyboard / gamepad 输入提示，ready 文案改为 `Tap FLIP`；后续为收敛首发桌面体验，`CoinFlipSystem/ui.lua` 的 mobile HUD profile 和 portrait 下折叠 Chance / Speed 逻辑已临时注释，触屏端目前沿用桌面 / narrow HUD 布局。
- 2026-05-18：代码侧曾完成 P0-3 的第一轮 safe-area 接入；后续 `uiController.OpenFrame()` 的移动端 growth panel 重排与 viewport 刷新绑定已临时注释，等待移动端布局重做。
- 待验证：尚未做手机 portrait / landscape、平板、TopbarPlus 点击面积、growth panel 内容挤压和双客户端实机 QA。

## 评分

| 维度 | 分数 | 判断 |
|---|---:|---|
| Roblox 平台匹配 | 8.0 / 10 | 短循环、强按钮、弱社交、收集成长都适合 Roblox。 |
| 移动端就绪 | 7.0 / 10 | 触屏可玩，但还缺手机布局、安全区、提示和实机 QA。 |
| 核心循环 | 8.5 / 10 | 一键 flip + Auto Flip 清晰，重复行为成本低。 |
| 社交存在感 | 7.5 / 10 | 单桌 8 人方向对，但桌面反馈还可以更可见。 |
| 留存成长 | 7.5 / 10 | 有 run upgrade / Rebirth / 装扮，但每日目标和里程碑偏薄。 |
| 合规风险 | 8.0 / 10 | 当前像游戏内运气循环；后续避免 Robux 直接购买随机收益或强博彩语义。 |

## P0 改进

### 1. 接入真实移动端 HUD 布局

目标：把当前 mobile layout 配置从“存在但未使用”变成实际运行时行为。

建议：

- 在 `CoinFlipSystem/ui.lua` 中根据 `UserInputService.TouchEnabled` 和 `CurrentCamera.ViewportSize` 判断移动端 portrait / landscape。
- 使用 `Presets.UiLayout.MobileMaxWidth`、`MobileMaxAspect`、`MobileLandscapeSize`、`MobilePortraitSize`、`MobileMinSize`、`MobileMaxSize` 驱动 `CoinFlipHUD` 的整体尺寸和位置。
- 保持 layout-bearing UI 的 `Position` / `Size` 使用 Scale；Offset 只保留给 padding、stroke、text inset 这类固定微调。
- 手机 portrait 下优先保证 `FLIP`、`Auto`、Cash、Streak 不被遮挡；Chance / Speed / upgrade 可降低信息密度或折叠。

验收：

- 手机 portrait 下 `FLIP` 和 `Auto` 不被 Roblox topbar、safe area、默认触控控件遮挡。
- 手机 landscape 下桌面中心仍可见，右侧属性和升级按钮不压住硬币落点。
- HUD 在翻硬币中正确隐藏低优先级信息，结束后恢复。

### 2. 移动端输入提示独立化

目标：触屏玩家看到的是触屏语义，而不是 `Space` / `RT` 语义。

建议：

- TouchEnabled 时隐藏或替换 `InputHints` 中的 keyboard / gamepad 提示。
- 文案重点放在按钮本身和状态上，例如 `FLIP`、`Auto:Off`、`Auto:On`、`Waiting for seat...`。
- 不新增复杂教程浮层，避免回到旧 onboarding 面板。

验收：

- 触屏端首屏不出现只对键盘/手柄有效的主要提示。
- 玩家无需读长说明即可点击 `FLIP` 开始。

### 3. 移动端 Growth Panels QA

目标：Shop / Inventory / Rebirth 在手机上可打开、可滚动、可关闭、可购买 / 装备，不抢主 HUD hit test。

建议：

- 检查 TopbarPlus 图标在移动端的点击面积和安全区。
- 检查 Shop / Inventory / Rebirth 的 tab、分页、关闭按钮、item card、价格和状态标签是否会挤压。
- 手机端打开 growth panel 时继续隐藏 gameplay HUD 和 Auto Flip，关闭后恢复。

验收：

- portrait 和 landscape 下都能完成：打开 Shop、切到 Coin / Desk / Chair、购买、打开 Inventory、装备、打开 Rebirth、关闭面板。
- 没有 legacy `noUse` 透明 UI 抢点击。

## P1 改进

### 4. 强化同桌弱社交反馈

目标：让玩家明确感觉另外 7 个座位也在发生事，但不做复杂观战面板。

建议：

- 保留低噪音桌面信号：他人硬币短 pulse、streak 小高光、全桌 streak milestone 闪光。
- 重点展示座位上的事件，不恢复旧 `CoinFlipSpectatorFeed` 或复杂 table overview。
- 高 streak 可以让座位或硬币落点短暂强调，但避免遮挡自己的 Flip。

验收：

- 双客户端下，A flip 时 B 能看到轻量反馈。
- 高 streak 事件不会抢走主玩家输入焦点。

### 5. 增加首发留存目标

目标：补足“只点 FLIP”的长期疲劳。

建议：

- 每日 3 个极短目标，例如 flip 次数、达到 streak、购买一次升级。
- Profile XP 或轻量等级，只作为长期进度，不打断 run upgrade / Rebirth 主链路。
- 增加 milestone toast 和庆祝音效 / VFX，占用时间短，不弹大面板。

验收：

- 新玩家 5 分钟内能看到至少一个中期目标。
- 老玩家回流时有明确的今日目标或下一档成长目标。

### 6. 装扮价值前置

目标：让 Coin / Desk / Chair 不只是商店列表里的数值，而是在同桌视野里有存在感。

建议：

- 默认 Coin / Chair / Desk 保证视觉清晰。
- 购买或装备后立即刷新座位资产，并给一次短反馈。
- 稀有装扮可以有轻微材质、颜色或落地 pulse 差异，但不要影响 hitbox 或相机。

当前小步：购买 / 装备成功后已复用现有 notification 与本地 SFX 做短反馈；座位资产刷新仍走现有 Coin / DecorationSystem 路径，最终观感需 Studio 验证。

验收：

- 玩家能在自己的座位和他人座位上看出装扮差异。
- 装备切换不需要重进游戏。

## P2 改进

### 7. 合规语义收敛

目标：保留运气和 streak 刺激，但避免强化博彩表达。

建议：

- 谨慎使用 `Cash Out`、`Double`、`Jackpot` 等强博彩词；如果未来做 streak 决策，优先使用中性表达，不与 Robux 购买直接绑定。
- 不做 Robux 直接购买随机收益。
- 如果未来做付费随机装扮，必须明确展示概率，并遵守 Roblox 随机虚拟物品政策。

当前小步：源码里面向玩家的 `Jackpot` 结果 / 全桌提示 / 座位状态 / Shop 角色标签已收敛为 `Perfect Five`、`Table Bonus`、`Hot Streak` 或 `Perfect`；内部 `comboKey = "jackpot"`、`TableJackpot` 配置和 `coinflip_table_jackpot` 埋点保留为历史 schema，不作为玩家可见文案。

验收：

- 付费项主要卖装扮、便利或明确收益，不卖不可见概率收益。
- 随机付费内容有清晰概率披露和年龄 / 地区合规判断。

### 8. 数据和埋点

目标：用少量关键数据判断移动端是否真的舒服。

建议：

- 记录首局：进服到入座、入座到第一次 Flip、首次 Auto Toggle、首次升级、首次打开 Shop / Inventory / Rebirth。
- 区分 touch / keyboard / gamepad 设备口径。
- 优先看移动端前 3 分钟流失点。

当前小步：核心 session 埋点已覆盖进服、离服、session 设备画像、前 `3` 分钟短会话结束、进服到首次入座 latency、首次 Flip latency、首次 Auto Toggle、首次 run upgrade、首次打开 `Shop / Inventory / Rebirth` 和 Flip 次数 milestone。这些事件只用服务器内存 session 去重，不新增持久字段；`coinflip_device_profile` 带 `touch / keyboard / gamepad / hybrid` 设备分类、viewport band 和最近输入类型，`coinflip_early_session_end` 带设备分类、viewport band 和当前首局进度阶段，growth panel 打开事件带 panel、入口 source 和最近输入类型。

验收：

- 能回答：移动端玩家是否知道点哪里、是否能完成首次升级、是否能打开并关闭 growth panel。

## 建议落地顺序

1. P0-1：接入真实移动端 HUD 布局。
2. P0-2：替换触屏输入提示。
3. P0-3：做手机 portrait / landscape growth panels QA。
4. P1-4：补强同桌弱社交反馈。
5. P1-5：补每日目标 / profile XP。
6. P1-6：强化装扮购买后的即时反馈。
7. P2-7：上线前做付费和随机语义合规检查。
8. P2-8：补移动端关键漏斗埋点。

## 实机 QA 清单

- iPhone 小屏 portrait。
- iPhone landscape。
- Android 常见宽高比 portrait。
- Android landscape。
- 平板 landscape。
- 桌面端键鼠。
- 手柄。
- 双客户端同桌。

每个设备至少覆盖：

- 进服自动入座。
- 首次点击 `FLIP`。
- 开关 `Auto`。
- 翻硬币中 HUD 隐藏和恢复。
- 购买升级。
- 打开 / 关闭 Shop、Inventory、Rebirth。
- 购买 / 装备 Coin、Desk、Chair。
- 重生后回座。
- 离服 / 重进后装扮和数据恢复。

## 非目标

- 不恢复多桌大厅。
- 不恢复主动离座 / 手动切桌。
- 不恢复复杂观战面板。
- 不用运行时代码生成可编辑 UI prefab。
- 不为移动端单独复制一套并行 UI 系统；优先让 Studio-authored UI 加上响应式布局规则。
