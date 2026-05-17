# TASK_STATE

最后更新：2026-05-18

> 目的：记录当前正在做什么、下一步是什么、关键决策、待验证项与后续想法。项目事实放 `PROJECT_LOGIC.md`，框架规则放 `FRAMEWORK.md`；不要把本文件变成长篇历史日志。

## Active

当前没有 active 任务。

## Current Baseline

- 首发方向：单桌 `8` 人弱社交桌面运气游戏；玩家进服后自动分配座位并立即坐下，暂不支持主动离座或手动切桌。
- 核心循环：玩家面前一个明确的 `FLIP` 主按钮；HUD 点击、`Space`、手柄 `RT` 都走统一 Flip 入口，`Space` 不再触发跳跃或离座。
- 桌面视角：idle 使用可自由转向的头部第一人称，自己的 Flip 期间临时跟随硬币，落下后回到 idle。
- 弱社交反馈：其他座位的 flip / streak / 高光只做低噪音反馈；头部姿态经服务端驱动角色关节复制，用户真双客户端验证确认会同步到另一个客户端。
- 主 UI / Billboard / 世界表现资源以 Studio 预制为目标；代码主要负责读取、绑定、显隐和更新数值。
- 旧座位 Billboard、复杂观战面板、旧 spectator feed / table overview 已退出主流程。
- 单桌满员链路按逻辑验证通过：`8` 个座位、自动分配、满员等待、空位释放后再分配、重生回座和离服清理闭环成立。

## Decisions

- 旧“围观优化版”计划已失效，不继续做多桌大厅、空位抢座引导、离座按钮、手动切桌或复杂观战面板。
- 当前核心体验是“进服即坐下，面前一个巨大明确的 `FLIP` 按钮，循环简单但上头”。
- 弱社交成立：不做强聊天 / 自由移动 / 主动组队，但要让玩家感觉自己坐在一张正在发生事的桌上。
- 桌面沉浸视角前置；首发采用项目内两态相机，不接第三方 `Open FPC`。
- 头部姿态只是弱互动反馈，不做全身 IK；采用服务端驱动角色关节 C0，客户端只上报相机相对身体的 pitch / yaw。
- 玩家重生后应重新回到可用座位，不进入自由行走态。
- Rebirth Points 复用持久化 `fateShards`，不新增重复点数币种。
- Shop / Inventory 小按钮采用固定字号 Bold 文本；短状态标签优先于挤压长文案。
- Inventory 装备从 item card 立即生效；除非新增 staged-loadout 流程，否则独立 Apply 按钮保持隐藏。
- 运行态 Rebirth / Shop / Inventory 入口使用 TopbarPlus 顶栏按钮；`CoinFlipMenu` 只保留为旧绑定兼容节点，玩法态不再显示。
- Growth panels 保持 Studio-authored 结构但由运行时代码统一套黑底大面板布局；当前游戏不支持 mobile，不再做 mobile-only runtime reposition。
- `Main.Frames.noUse` 下的 legacy 透明 UI 保持不可交互，避免抢 Rebirth / Shop / Inventory hit test。
- 复杂客户端视觉、多客户端、移动端设备或 Studio-only 观感验证交由用户手动确认；Codex 只记录可自动覆盖的源码 / 单客户端 sanity 和用户回传结果。

## Known Follow-Ups

- Studio Play：确认 `coin1` through `coin9` 资产能按装备显示，新档默认 `Coin1`，旧 Coin id 存档能 reconcile 到 `coin1`。
- Studio Play：确认启动后 HUD 从 `Seat --` 切到分配座位并保持稳定，立刻点击 `FLIP` 不会被客户端旧 seat state 错拦。
- Studio Play：确认不同 Coin 自己/他人 flip 视觉正常，落点在桌面上方，不沉入桌面。
- Studio Play：确认 Desk Setup 购买 / 装备后按座位刷新，模型坐在桌面上，离座 / 离服能清理。
- Studio 资产整理：如需永久 source-backed decoration 资产，把 live `Workspace.TableDecoration` 移到 `ReplicatedStorage.Systems.DecorationSystem.Assets.TableDecoration`，并按 `Folding Table` / `Green Felt` / `Arcade Desk` / `Velvet Casino` 拆分命名。
- Studio Play：最终看一遍桌面版 Rebirth / Shop / Inventory 视觉比例、tab 状态、打开关闭流程；MCP synthetic click 对这些按钮不可靠。

## Backlog / Ideas

- `P2` 首发成长补强：少量每日目标、Profile XP。
- `P3` 首发表现与运营：庆祝 VFX / SFX、桌面轻表情 / cheer、基础 gamepass、核心埋点。
- 可评估极简决策点：高 streak 后出现 `Cash Out` / `Double` / bonus choice，但不要破坏“一键 Flip”的主循环。

## Done

### 2026-05-18 Chair replacement loadout

- Outcome: `chair` 已作为第三类 loadout 接入，新增 `equippedChair / ownedChairs` 持久字段、`EcoSystem` 的 chair 商品与页签、`DecorationSystem` 的座位椅子运行时克隆，以及 Studio 里的 `SeatXXChairAnchor`、`ChairTab`、`PageControls` 和 `ChairSlot`。
- Validation: `git diff --check` 通过；Studio MCP 确认 `Assets.Chairs` 下有 11 个椅子模型、8 个 `SeatXXChairAnchor`、Shop/Inventory 的 chair 页签与分页控件、`Inventory.Loadout.ChairSlot`；Play-time 确认 `Workspace.CoinFlipTable.Assets.DecorationsRuntime` 会生成 `Seat01Chair` 和 `Seat01Decoration`。

### 2026-05-17 Auto Flip and persistent coin result

- Outcome: `StarterGui.Main.Elements.CoinFlipHUD.Content.CenterPanel` 新增 Studio-owned `AutoButton`，默认显示 `Auto:Off`，切换后显示 `Auto:On`；`CoinFlipSystem/ui.lua` 通过现有 `requestFlip()` 路径实现客户端自动连 flip，离座、打开 Shop / Inventory / Rebirth 或手动关闭会停止；`EffectSystem` 去掉了落地后的自动清理，上一枚硬币会保留到该座位下一次 flip 开始时才被替换。
- Validation: `git diff --check` 通过；`CleanupDelay` 引用已清除；Studio edit-time 确认 `AutoButton` 存在且是纯 scale 布局；Play-time 确认 HUD 已出现 `AutoButton` 且默认文案为 `Auto:Off`。

### 2026-05-17 UI scale compliance pass

- Outcome: 把 `StarterGui.Main.Elements.CoinFlipHUD` 的所有 `GuiObject` 子孙 `Position` / `Size` 改成纯 `Scale`，包括 `LeftPanel`、`RightPanel`、`LeftPanel.Cash / Streak`、`RightPanel.Stats / UpgradeButtons`、`RightPanel.Stats.Chance / Speed`、所有 stats / upgrade / cash / streak 文字节点、`CenterPanel.SeatLabel`、`ResultLabel`、`FlipButton`、`InputHints` 和 hint 文本；同时把 `AGENTS.md` 和 `.cursor/rules/40-ui-and-client-patterns.mdc` 补成明确的 `Scale` 版 UI 规则，避免后续再写固定像素布局。
- Validation: Studio edit-time 和 Play-time 扫描确认 `CoinFlipHUD` 所有 `GuiObject` 子孙的 `Position` / `Size` offset 数量均为 `0`；Studio Play 快速检查通过，`FlipButton` 仍能正常显示和点击，右下 stats / upgrade 卡片没有跑位，桌面视野没有被 UI 重新遮满；`git diff --check` 通过，仅有既有 CRLF 提示。

### 2026-05-17 StarterGui Elements cleanup

- Outcome: 通过 MCP 清理 `StarterGui.Main.Elements`，只保留当前首发主流程使用的 `CoinFlipHUD`、`cash`、`candy`、`ripple`。删除旧 `Buffs / Rewards / Quests / Quests_back / blockInfo / auto`、旧 CoinFlip onboarding / spectator / overview 及 backup、旧 `damage` Billboard；`uiController.AddReward()` 改为可选 legacy no-op，避免删除 `Rewards` 后启动硬等待。
- Validation: 活跃系统 / `StarterGui` 源码扫描确认不再硬等待被删 Elements；`git diff --check` 通过；Studio Play 确认 `Elements` 子节点数为 `4`，HUD 显示 `Seat 01`，按 `Space` 翻牌后结果正常更新。

### 2026-05-17 Runtime UI prefab migration

- Outcome: 补充中央 rules：可调整 UI prefab 不再用运行时代码生成，除 TopbarPlus `Icon`、短生命周期模板 clone 和非 UI 运行时对象外，Frame / card / layout / 圆角 / 描边 / constraint 均应 Studio-owned。已用 MCP 将 `StarterGui.Main` 下 `CoinFlipHUD`、`Shop`、`Inventory`、`Rebirth` 相关布局和样式整理成 Studio 资源，并把 `CoinFlipSystem` / `EcoSystem` / `RebirthSystem` / `PlayerSystem` UI 逻辑收敛为读取、绑定、显隐和数值更新。
- Validation: 目标活跃 UI 文件扫描确认不再包含 `Instance.new` / 运行时样式生成 helper；Studio Play 确认 HUD 可显示、`Seat 01` 文案正确、`Space` 翻牌后结果更新且 HUD 仍保持边缘布局。

### 2026-05-17 Edge HUD layout correction

- Outcome: 按用户回传图 2 继续收敛运行态 HUD：`CoinFlipHUD` 改为全屏透明承载层，现金 / 连击贴左下，概率 / 速度 / Value / Bias 贴右下，`FLIP` 与短结果提示居中贴底；桌子中心保持可见。Rebirth / Shop / Inventory 顶部入口改为 TopbarPlus `Icon.new()`，旧 `CoinFlipMenu` 不再显示。
- Validation: `git diff --check` 通过；Studio Play 确认 idle HUD 不遮挡桌面、`Space` 翻牌后结果返回、Shop 打开时 gameplay HUD 自动隐藏。MCP synthetic click 对 TopbarPlus 图标仍不稳定，已用 `uiController.OpenFrame("Shop")` 验证面板显隐链路。

### 2026-05-16 In-play minimal HUD frame/code pass

- Outcome: 按 `ui_game_ui_design_inplay_minimal.html` 截图继续收敛运行态 UI：`CoinFlipMenu` 改为顶部圆形入口，`cash/candy` 复用为右上钱包，旧 TopBar / Buffs / RightBottom 等 legacy UI 在玩法态隐藏；`CoinFlipHUD` 改为底部桌边式三段布局，Shop / Inventory / Rebirth 统一为黑底高对比大面板，打开成长面板时 gameplay HUD 自动让位。
- Validation: `git diff --check` 通过；Studio Play 截图确认 idle HUD、Space flip、Rebirth 面板和 Shop 面板能按新布局显示；MCP synthetic click 对圆形菜单按钮仍不稳定，实际按钮绑定沿用 `uiController.SetButtonHoverAndClick`。

### 2026-05-16 In-play minimal HUD implementation

- Outcome: 按 `ui_game_ui_design_inplay_minimal.html` 将主玩法 HUD 收窄为桌边式布局，`CoinFlipMenu` 改为更轻的顶部条，`CoinFlipHUD` / onboarding / table overview 默认不再常驻；翻牌时隐藏非必要 UI，恢复后再回到结果与升级状态。
- Validation: `git diff --check` 通过；Studio 里重启 Play 后确认 idle 画面更轻、HUD 不再像启动界面，flip 完成后可正常回到结果显示。

### 2026-05-16 In-play HUD redesign correction

- Outcome: 用户指出上一版全屏 Flip Machine 过度遮挡后，新增 `ui_game_ui_design_inplay_minimal.html`：参考图只取黑底高对比 / 筹码奖励 / 粗字体风格，主 gameplay 改为低遮挡边缘 HUD，抛硬币中隐藏或弱化非必要 UI，Shop 等主动菜单才使用大面板。
- Validation: 方案文件存在性和关键章节检查通过；规则风险扫描未发现小于 14px 的 px 字号、贴边 0 定位、超大 z-index 或长动画；`git diff --check` 通过，仅有既有 CRLF 提示。

### 2026-05-16 Game UI full-screen proposal

- Outcome: 使用 `$game-ui-design` 的 patterns / sharp edges / validations 重新审查当前运行态 UI，并结合用户提供的参考图新增 `ui_game_ui_design_fullscreen.html`，提出全屏 Coin Machine 主界面、全屏商店和挑战式 Rebirth / Daily 面板方向；未改 Roblox UI 资产或源码。
- Validation: Studio Play 截图复核主 HUD、Shop、Inventory、Rebirth；方案文件存在性和关键章节检查通过；规则风险扫描未发现小于 14px 的 px 字号、贴边 0 定位、超大 z-index 或长动画；Play 已停止。

### 2026-05-16 UI frame review proposal

- Outcome: 通过 Roblox Studio MCP 查看 `StarterGui.Main` 和 Play 运行态 `PlayerGui.Main` 的主 HUD、CoinFlipMenu、Shop、Inventory、Rebirth 与 legacy `noUse` Frame，新增 `ui_frame_review_proposal.html` 作为待确认 UI 修改方案；未改 Roblox UI 资产或源码。
- Validation: Studio Play 截图覆盖主 HUD、Shop、Inventory、Rebirth；本地文件存在性和标题/章节关键词检查通过；Browser 直接打开本地 `file://` 被安全策略拦截，未绕过。

### 2026-05-16 Cross-project central rules merge

- Outcome: 中央 rules 已重构为跨项目通用层，只保留 `AGENTS.md` 与 `.cursor/rules/*.mdc`；`docs/BOOTSTRAP.md` 与 `docs/FRAMEWORK.md` 留在各项目本地维护。FlipACoin 与 TheForger 均已同步到中央规则版本。
- Validation: 两个项目的 `Sync-Rules.ps1 -Mode Sync` / `-Mode Check` 通过；TheForger 的 `docs/BOOTSTRAP.md` / `docs/FRAMEWORK.md` 未被中央覆盖；中央源未残留项目名或项目玩法词。
- Decisions: 中央层只承担跨项目通用工作规则，不再承载项目启动文档或项目框架说明。

### 2026-05-16 Central rules GitHub setup

- Outcome: `C:\Users\hh\OneDrive\Desktop\roblox\_central-rules` 已配置 `origin` 为 `git@github.com:RobStar-Studio/CentralRules.git` 并推送 `main`；中央仓库根部新增 `README.md`，说明 Windows / macOS / 任意路径的 rules 同步流程。
- Validation: 中央仓库 `git status --short` 为空；`origin/main` 已建立 upstream；最近提交为 `7c7a089 Add sync instructions` 和 `8a74816 Initial central rules`。
- Decisions: 项目内已有 `docs/RULES_SYNC.md` 保持不重复；中央仓库用根 `README.md` 作为跨设备入口说明。

### 2026-05-16 Central rules sync

- Outcome: 已新增 `.rules-sync.json`、`tools/rules/Sync-Rules.ps1` 和 `docs/RULES_SYNC.md`；中央 rules 源已初始化到 `C:\Users\hh\OneDrive\Desktop\roblox\_central-rules`，托管 `AGENTS.md`、`docs/BOOTSTRAP.md`、`docs/FRAMEWORK.md` 和 `.cursor/rules/*.mdc`，并包含可复用 `tools/Sync-Rules.ps1` 与 `templates/rules-sync.json`。
- Validation: `Sync-Rules.ps1 -Mode InitCentral`、`-Mode Sync`、`-Mode Check` 通过；`git diff --check` 通过，仅出现既有 LF-to-CRLF 工作区提示。
- Decisions: `docs/PROJECT_LOGIC.md` 和 `docs/TASK_STATE.md` 保持项目专属，不进入中央同步。

### 2026-05-16 Resource logic hookup

- Outcome: 代码已接入桌搭 / 硬币 / 音效资源逻辑：桌搭继续读取 `SeatXXDecorationAnchor`；硬币落点优先读取 `SeatXXCoinLandingAnchor`；Flip、结果、现金奖励、购买、装备、Rebirth、通知和 streak 播报会播放对应 `SoundService.SFX` 占位音效。
- Validation: `git diff --check` 通过；MCP 确认 8 个座位的 `DecorationAnchor` / `CoinLandingAnchor` 和所有活跃音效占位均存在，活跃 `SoundId` 仍为空；`stylua` / `selene` 因未列入本仓库 `aftman.toml` 被 Aftman 拒绝运行。
- Decisions: 不新增持久化字段；不填音效资源 id；纯 Luau 资源逻辑改动未运行 Rojo build。

### 2026-05-16 Studio marker and sound assets

- Outcome: 通过 Studio MCP 在 `Workspace.CoinFlipTable.Attachments` 为 `Seat01` 到 `Seat08` 创建 / 更新 `DecorationAnchor` 与 `CoinLandingAnchor` 定位块；`SoundService` 已整理为活跃 `bgm`、`SFX` 音效占位和 `NoUse` 旧音效文件夹，活跃音效 `SoundId` 均为空。
- Validation: MCP 数据检查确认 8 个座位无缺失锚点；硬币落点位于玩家前方同侧且未越过桌子圆心；活跃音效 `SoundId` 全为空。
- Decisions: 本轮只制作 Studio 资源，不写资源逻辑代码；未从商店选音频资源，后续由用户填写音效 asset id。

### 2026-05-16 Markdown cleanup

- Outcome: 根目录 `README.md` 已改为当前 Flip A Coin 入口说明；旧武器 / Forge / Ore 的 `TODO.md` 已删除；`TASK_STATE.md` 从长篇历史流水压缩为当前状态、关键决策、待验证项、backlog 和 Done 摘要；`PROJECT_LOGIC.md` 已同步文档关系。
- Validation: 旧 Rojo 模板名、旧 TODO 关键词和“README 是旧内容”的 Markdown 引用扫描无结果；`git diff --check` 通过，仅有 Git 的 LF-to-CRLF 工作区提示。
- Decisions: `Packages/` 下第三方 README/LICENSE 不参与本轮清理。

### 2026-05-15 Coin config rename

- Outcome: Coin shop item ids 收敛为 `coin1` through `coin9`，默认 owned/equipped 为 `coin1`，UI / head / seat summary 对外显示 `Coin1` through `Coin9`。
- Validation: `git diff --check` 和 `rojo build default.project.json --output /private/tmp/flip_coin_config_rename_check.rbxl` 通过；`stylua` 不在 `aftman.toml` 中。
- Remaining: 见 Known Follow-Ups 的 Studio Play 项。

### 2026-05-15 Startup seat and first flip readiness

- Outcome: 修复启动 seat state 竞态和首屏 `FLIP` 可见但不发请求的问题；TableSeatSystem seat event 负责座位转场，CoinFlip run-state snapshot 不再回退更晚的已入座状态。
- Validation: `git diff --check` 通过；两次 Rojo build 检查通过。
- Remaining: 见 Known Follow-Ups 的启动 HUD / 立刻 Flip 项。

### 2026-05-15 Asset workflow rule

- Outcome: 在 `AGENTS.md` 和 Cursor rules 中补充规则：不要用 Rojo/source edits 创建复杂 Roblox 资产占位层级，除非用户明确要求 source-control 简单资产结构。

### 2026-05-14 Decoration system

- Outcome: 新增并注册 `DecorationSystem`，让 Desk Setup 视觉按座位 clone / replace / clear；`EcoSystem` 和 `TableSeatSystem` 已在购买、装备、入座、离座、离服时刷新或清理 decoration。
- Validation: `git diff --check` 和 `rojo build default.project.json --output /private/tmp/flip_decoration_system_check.rbxl` 通过；`stylua` / `selene` 本地不可用。
- Remaining: 见 Known Follow-Ups 的 Desk Setup 和 Studio 资产整理项。

### 2026-05-14 Coin and desk equip visuals

- Outcome: Equipped Coin 随 flip payload 下发，`EffectSystem` 按 `CoinFlipSystem.Assets.Coins/<item id>` 播放自己和他人的硬币视觉；Coin / Desk Setup 都按真实 bounds 计算桌面 lift。
- Validation: `git diff --check` 和 `rojo build default.project.json --output /private/tmp/flip_coin_decoration_check.rbxl` 通过；本地缺少 `stylua` / `selene` / `luau`。
- Remaining: 见 Known Follow-Ups 的 Coin / Desk Setup Studio Play 项。

### 2026-05-13 System responsibility migration

- Outcome: Shop / Inventory authority 与 UI 迁到 `EcoSystem`，Rebirth authority 与 UI 迁到 `RebirthSystem`，flip visual playback 迁到 `EffectSystem`，settings lookup / effect factor helpers 迁到 `SettingSystem`。
- Validation: `git diff --check` 通过；选定 Stylua 检查通过；源码扫描确认旧 remote call 路径移除。

### 2026-05-13 Growth UI desktop cleanup and tab fixes

- Outcome: 移除 mobile-only runtime reposition，Rebirth / Shop / Inventory 使用 Studio-authored layout；Shop / Inventory category tab selected state 改为 runtime 显式颜色。
- Validation: `git diff --check` 通过；本地缺少 `selene`。
- Remaining: 见 Known Follow-Ups 的桌面 UI 最终观感项。

### 2026-05-08 Core single-table experience

- Outcome: 完成单桌 `8` 人方向校准、自动入座、强制坐席、统一 Flip 输入、两态第一人称相机、重生回座、头部姿态同步、旧 Billboard / 观战 UI 退场、三栏 Flip HUD 预制绑定、同桌轻高光与 coin pulse 预制化。
- Validation: 单人 Studio Play 覆盖自动坐下、HUD、`Space` / HUD 点击 / `RT` Flip、重生回座、旧表现隐藏；用户真双客户端验证确认头部姿态同步。

### 2026-05-08 Legacy UI and startup cleanup

- Outcome: 删除未启用的 `ReplicatedFirst.LoadingScreen` 旧路径；Announcement banner runtime creation 退场；旧 CoinFlip onboarding 面板不再显示或运行时创建 guide 子节点。
- Validation: `git diff --check` 和相关引用扫描通过；LoadingScreen 删除时 Rojo build 通过。

### 2026-05-06 Startup router

- Outcome: 新增 `docs/BOOTSTRAP.md` 作为低成本启动路由；`AGENTS.md`、`FRAMEWORK.md`、`PROJECT_LOGIC.md` 改为先读 bootstrap 和 `TASK_STATE.md` Active，再按任务类型读相关章节。

### 2026-05-04 Docs consolidation

- Outcome: `docs/` 收敛为 `BOOTSTRAP.md`、`FRAMEWORK.md`、`PROJECT_LOGIC.md`、`TASK_STATE.md`；旧策划、旧路线图、旧执行进度、旧系统拆分和旧架构梳理 Markdown 已删除或迁移摘要。

### 2026-05-01 Product direction reset

- Outcome: 明确首发不是多桌大厅或强社交 simulator，而是单桌 `8` 人、弱社交、高频 Flip、强按钮反馈的桌面运气游戏。

## Maintenance Rules

- 每次开始新任务，在 `## Active` 添加一条，至少写 `Started / Status / Progress / Next / Decisions`。
- 任务完成后移动到 `## Done`，写一行 outcome 和日期；不要把逐条验证流水长期留在 Active。
- 新发现但不排期的想法放到 `## Backlog / Ideas`，保持单行。
- 若代码和本文件冲突，先确认代码，再更新本文件。
