# Task State Done Archive: 2026-05-01 to 2026-06-01

归档日期：2026-06-02

来源：旧 `docs/TASK_STATE.md` 的 `## Done` 历史记录。

这份文档保留历史脉络和完成项摘要，不作为当前项目事实来源。当前事实以 `docs/PROJECT_LOGIC.md` 和源码为准；当前待办以 `docs/TASK_STATE.md` 为准。

## 2026-06-01

- Platform input / rewarded potion boost implementation：`PotionSystem` / `BuffSystem` 接入 FlipACoin 主线；Rewarded Ad 和付费 `cash2x` boost 进入 Boosts 面板；Flip 奖励读取 Cash boost；补充输入来源和广告 / potion / buff analytics。
- SFX completion and coin landing burst：补齐 `SoundService.SFX` 主线音效候选，新增 Studio-owned `coinLandingBurst` 落地粒子资产，并由 `EffectSystem` 在硬币落地后播放。

## 2026-05-31

- Growth panel stale guide-mask fix：修复 Shop / Inventory / Rebirth 手动打开时被旧 guide mask 覆盖的问题，清理不匹配的 HUD 高亮。
- Front coin / left desk layout：调整动态硬币落点到玩家正前方，桌搭落点移到玩家左侧，并同步静态 fallback anchor。
- Fake player coin landing correction：`EffectSystem` 优先用 `TableSeatSystem:GetSeatTargetCFrame()` 推导 fake / real seat 的动态硬币落点。
- Coin landing proximity / TextLabel constraints：调整 `SeatXXCoinLandingAnchor` 到玩家侧，移除非 CoreGui `TextLabel` 下的 UI constraints，避免 `TextScaled` 被限制。
- MCP text scale / coin landing anchors：通过 Studio MCP 设置非 CoreGui `TextLabel.TextScaled = true`，并让 `EffectSystem` honor fixed `CoinLandingAnchor`。
- Reworked Flip / Rebirth / Coin onboarding：`Onboarding.lua` 迁到 v3，引导流程改为首次 Flip、首次 Rebirth、购买非默认 Coin、装备 Coin，并接入 guide highlight。

## 2026-05-30

- Streak / best-streak visual feedback：服务端记录真实玩家 / fake player best streak，接入 best-streak celebration 和高 streak spotlight。
- Mobile seated camera / fake head / auto-seat warning：移动端初始看桌面期间短暂切到 `Scriptable`，fake head 支持 `AnimationConstraint.Transform`，自动落座前后验证 Humanoid 状态。

## 2026-05-29

- Initial table camera / fake flip head tracking：首次入座时请求一次桌面朝向；fake player flip 时客户端驱动 fake rig 头部看向硬币。
- Coin flip vertical-axis spin correction：修正硬币空中旋转轴，避免像竖着的轮子转，落地仍收敛到 Heads / Tails 平铺姿态。
- Loading coin X-size lock correction：修复加载屏硬币翻面时宽度随高度一起缩小的问题。
- Loading coin projection correction：修正加载屏硬币投影和翻面尺寸表现。
- Loading coin / desktop scene click correction：修正加载屏硬币表现和桌面场景点击相关问题。
- Shop price button layout：调整 Shop 商品卡购买按钮布局。
- UI text scale / Bias wording pass：全 DataModel TextLabel 启用 `TextScaled`，玩家可见 `Bias` 文案改为 `Luck`。

## 2026-05-28

- LoadingScreen duration controls：加载屏加入最短 / 最长展示时间，进度条改为时间驱动虚拟进度。
- First-person body-view camera offset：两态第一人称相机加入身体可见偏移。
- LoadingScreen coin flip rewrite：`ReplicatedFirst.LoadingScreen` 接管启动体验，重做 Coin Flip 主题加载屏。
- Mobile table tap / spawn camera pass：桌面点击射线改为 `ScreenPointToRay()`，初始相机看向桌面中心。
- Frame UI template / stroke pass：统一 Growth panels 黑底 / 金描边结构，Shop / Inventory 使用 Studio-authored scrolling template。
- Auto Flip cooldown enable fix：修复冷却窗口开启 Auto 时不会排下一次自动请求的问题。

## 2026-05-27

- Roblox texture upload script：新增 Open Cloud 图片上传脚本，批量上传 Group-owned Image 并回填 `Textures.FlipACoinItems`。
- Desk setup shake pivot correction：桌搭点击抖动改为围绕底部接触点倾斜。
- Scene interaction details：新增桌搭点击抖动、桌面 knock SFX 和 ripple。
- Shop / Inventory item icons：为 Coin / Desk / Chair / product / gamepass 配置图片，并接入 Shop / Inventory 卡片渲染。
- Fake player appearance staging regression：修复 fake rig staging 导致 avatar description / body parts 丢失的问题。
- Fake player startup stability fix：fake director 加防重入和 pending create 计数，批处理座位广播。

## 2026-05-26

- Team / SFX / scrolling shop cleanup：移除 legacy Team 实例；SFX 改为统一走 `MusicSystem`；Shop / Inventory 改为 Studio-authored `ScrollingFrame` 和卡片池。

## 2026-05-24

- UpgradeButtons state ordering fix：HUD state sync 加 `stateVersion`，客户端跳过旧 payload，避免升级按钮回退旧等级。
- CoinFlip guidance notification cleanup：移除主循环内教学 / 建议 toast，保留 HUD pulse 和 onboarding 状态。
- Fake flip first-rebirth conflict fix：修复 fake actor 误走真实玩家 `getPlayerState()` 的冲突。
- Fake player behavior tuning：fake 人数刷新改为 10 到 20 分钟级，fake flip 节奏更接近持续玩家，非 Flip 行为低噪音。
- First rebirth tuning：调整首次 Rebirth 相关节奏和辅助。
- Head streak display：补充头顶 streak 展示。
- Fake player system：接入 fake player 占座和 flip 行为。
- Coin display names：整理 Coin 展示名。
- Decoration and chair display names：整理 Desk / Chair 展示名。
- HUD wallet cleanup and Auto state color：清理 HUD wallet 表达，调整 Auto 状态颜色。

## 2026-05-23

- Disable mobile TouchGui：禁用默认移动端 TouchGui 中不适合当前坐席玩法的控件。
- Disable mobile UI redistribution：停止移动端 UI 重新分发路径，避免和当前主 HUD 冲突。

## 2026-05-20

- FlipACoin monetization implementation：实现首版 FlipACoin product / gamepass / monetization 配置和入口。
- Onboarding economy and social effects polish：打磨 onboarding、经济节奏和弱社交反馈。

## 2026-05-19

- Analytics service instrumentation：接入 `AnalyticsSystem` 和 Roblox `AnalyticsService` 主线埋点。
- Streak milestone effects：实现 streak milestone VFX / weak social feedback。
- Onboarding plan execution：执行首次 onboarding 计划。
- Onboarding design review：完成 onboarding 设计复核。
- In-flight random coin spin：硬币空中随机旋转。
- Random coin landing yaw：硬币落地随机 yaw。

## 2026-05-18

- Coin result persistence and HUD visibility：持久化硬币结果，调整 HUD 翻硬币期间显隐。
- Coin PrimaryPart landing correction：修正 Coin PrimaryPart 和落地定位。
- Mobile growth panel safe-area code pass：Growth panels 接入移动端 safe-area 布局。
- Dynamic table seating and persistent coin visuals：动态桌面座位和持久硬币视觉。
- Mobile HUD P0 code pass：移动端 HUD 第一轮代码适配。
- Roblox platform and mobile improvement plan：新增 Roblox 平台 / 移动端改进计划。
- Chair replacement loadout：接入 Chair 装扮替换。

## 2026-05-17

- Auto Flip and persistent coin result：实现 Auto Flip 和 persistent coin result。
- UI scale compliance pass：检查并修复 UI scale 规则。
- StarterGui Elements cleanup：清理 `StarterGui.Main.Elements`。
- Runtime UI prefab migration：把运行时 UI prefab 迁移到 Studio-authored 结构。
- Edge HUD layout correction：修正屏幕边缘 HUD 布局。

## 2026-05-16

- In-play minimal HUD frame/code pass：实现并复核玩法内极简 HUD frame / code。
- In-play minimal HUD implementation：实现玩法内极简 HUD。
- In-play HUD redesign correction：修正 HUD redesign。
- Game UI full-screen proposal：完成全屏 UI 提案。
- UI frame review proposal：完成 UI frame review 提案。
- Cross-project central rules merge：合并跨项目 central rules。
- Central rules GitHub setup：设置 central rules GitHub 工作流。
- Central rules sync：同步 central rules。
- Resource logic hookup：接入资源逻辑。
- Studio marker and sound assets：创建 Studio marker 和 sound assets。
- Markdown cleanup：完成早期 markdown cleanup。

## 2026-05-15

- Coin config rename：重命名 Coin 配置。
- Startup seat and first flip readiness：修复启动入座和首次 Flip readiness。
- Asset workflow rule：补充资源工作流规则。

## 2026-05-14

- Decoration system：实现 Decoration system。
- Coin and desk equip visuals：实现 Coin / Desk equip visuals。

## 2026-05-13

- System responsibility migration：迁移系统职责。
- Growth UI desktop cleanup and tab fixes：清理桌面 Growth UI 并修复 tab。

## 2026-05-08

- Core single-table experience：完成单桌核心体验。
- Legacy UI and startup cleanup：清理 legacy UI 和启动链。

## 2026-05-06

- Startup router：新增启动路由文档。

## 2026-05-04

- Docs consolidation：整合文档分层。

## 2026-05-01

- Product direction reset：重置产品方向为当前 FlipACoin 桌面运气游戏主线。

