# TASK_STATE

最后更新：2026-05-27

> 目的：记录当前正在做什么、下一步是什么、关键决策、待验证项与后续想法。项目事实放 `PROJECT_LOGIC.md`，框架规则放 `FRAMEWORK.md`；不要把本文件变成长篇历史日志。

## Active

当前没有进行中的实现任务。

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
- Growth panels 保持 Studio-authored 结构但由运行时代码统一套黑底大面板布局；当前游戏具备基础触屏支持，但移动端布局、提示、安全区和实机观感仍需专项收敛。
- `Main.Frames.noUse` 下的 legacy 透明 UI 保持不可交互，避免抢 Rebirth / Shop / Inventory hit test。
- 复杂客户端视觉、多客户端、移动端设备或 Studio-only 观感验证交由用户手动确认；Codex 只记录可自动覆盖的源码 / 单客户端 sanity 和用户回传结果。

## Known Follow-Ups

- Studio / device QA：按 `docs/ROBLOX_PLATFORM_IMPROVEMENT.md` 覆盖手机 portrait / landscape、平板、桌面键鼠、手柄和双客户端同桌，确认 HUD 响应式布局、安全区、growth panels、Topbar 入口与装扮刷新。
- Studio Play：填入真实 Developer Product / Game Pass id 后，确认 Boosts 入口能弹出 Robux 购买 prompt；购买 Cash / Rebirth Points / Apex bundle / VIP / 2x Cash / Lucky Charm / Quick Flip 后刷新 HUD、Shop、Inventory、Rebirth 和座位表现。
- Creator Dashboard：创建 `cashPackSmall / cashPackMedium / cashPackLarge / rebirthShardSmall / rebirthShardLarge / apexLoadoutBundle` 六个 Developer Products 和 `vip / winsX2 / luckyCharm / quickFlip` 四个 Game Pass，并把 id 填回 `EcoSystem/Presets.lua`。
- Studio Play：新档默认 Cash 为 `9`，入座后不能立即买 `Value` 升级；完成 `3` 次 Flip 后即使全 Tails 也能到 `12` Cash，并进入首次升级引导 / 升级按钮 pulse。
- Studio Play 双客户端：确认他人 Heads / Tails 落地 pulse 更明显、Heads streak ring 按 streak 扩大、高 streak / milestone 有短 Highlight；`streak1` / `streak2` 资产缺失时 fallback pulse 不阻塞落地回调。
- Studio Play：确认 `coin1` through `coin10` 资产能按装备显示，新档默认 `Copper R Coin`，旧 Coin id 存档能 reconcile 到 `coin1`。
- Studio Play：确认启动后 HUD 从 `Seat --` 切到分配座位并保持稳定，立刻点击 `FLIP` 不会被客户端旧 seat state 错拦。
- Studio Play：确认不同 Coin 自己/他人 flip 视觉正常，落点在桌面上方，不沉入桌面。
- Studio Play：确认 Desk Setup 购买 / 装备后按座位刷新，模型坐在桌面上，离座 / 离服能清理。
- Studio 资产整理：如需永久 source-backed decoration 资产，把 live `Workspace.TableDecoration` 移到 `ReplicatedStorage.Systems.DecorationSystem.Assets.TableDecoration`，并按 `Tall Candle` / `Barrel Stein` / `Balance Scale` / `Quill Pot` / `Cosmic Globe` / `Miner Trophy` / `Crimson Hourglass` / `Amethyst Hourglass` 拆分命名。
- Studio Play：最终看一遍桌面版 Rebirth / Shop / Inventory 视觉比例、tab 状态、打开关闭流程；MCP synthetic click 对这些按钮不可靠。

## Backlog / Ideas

- `P0` 移动端首发剩余收敛：安全区、growth panels、Topbar 入口和真实设备观感 QA。
- `P1` 同桌弱社交补强：他人 flip pulse、streak 小高光、全桌 milestone 轻反馈。
- `P2` 首发成长补强：少量每日目标、Profile XP。
- `P3` 首发表现与运营：庆祝 VFX / SFX、桌面轻表情 / cheer、基础 gamepass、核心埋点。
- 可评估极简决策点：高 streak 后出现 `Cash Out` / `Double` / bonus choice，但不要破坏“一键 Flip”的主循环。

## Done

### 2026-05-27 Roblox texture upload script

- Outcome: 确认 Roblox Open Cloud Assets API 支持通过 API key 脚本化创建图片资产，但每个请求创建一个资产，批量上传需要本地脚本循环调用并轮询 operation。新增 `tools/upload_flipacoin_textures.mjs`：默认上传 `Image` 资产，扫描 `textures/`，把 `coin*.png` 映射到 Coin、`TableDecoration*.png` 映射到 Desk Setup、`1.png` 到 `11.png` 映射到 Chair。首轮把 `Decal` 资产上传到了个人账号，Group 游戏无法加载；第二轮上传到 Group 但仍为 `Decal`，`ImageLabel.IsLoaded` 仍为 false；最终用 `assetType = Image` 上传到游戏所属 Group `962619180`，写出 `output/roblox-texture-upload-image-result.json`，并回填 `src/ReplicatedStorage/configs/Textures.lua` 的 `Textures.FlipACoinItems`。Product / GamePass 图标未在本批 `textures/` 中提供，仍保留原临时占位。
- Validation: `node --check tools/upload_flipacoin_textures.mjs` 通过；`node tools/upload_flipacoin_textures.mjs --dry-run` 找到 `29` 张图片并正确映射，忽略 `.DS_Store`；最终真实上传返回 `29` 个 Group-owned Image `rbxassetid`，manifest 校验数量为 `29`；`Textures.FlipACoinItems.coin` / `desk` / `chair` 均已回填新 id；Studio Play 单客户端打开 Shop / Inventory 后，`Item1` 使用 `rbxassetid://87703843792466` 且 `ImageLabel.IsLoaded = true`；`git diff --check -- src/ReplicatedStorage/configs/Textures.lua output/roblox-texture-upload-image-result.json tools/upload_flipacoin_textures.mjs docs/TASK_STATE.md` 通过。

### 2026-05-27 Desk setup shake pivot correction

- Outcome: `EffectSystem` 的桌搭点击抖动不再围绕 `Model:GetPivot()` 做局部旋转，改为按桌面法线计算模型包围盒底面中心，并围绕该底部接触点做世界空间倾斜；同时移除旧整体平移参数，让底部保持为视觉支点。`PROJECT_LOGIC.md` 已同步。
- Validation: `git diff --check -- src/ReplicatedStorage/Systems/EffectSystem/init.lua src/ReplicatedStorage/Systems/EffectSystem/Presets.lua docs/TASK_STATE.md` 通过；Studio Play 单客户端启动无新增脚本错误，`DecorationsRuntime` 生成 `Seat01Decoration / Seat02FakeDecoration / Seat03FakeDecoration` 等运行时桌搭；自动截图点击桌搭后未发现启动报错。最终抖动手感仍建议用户在 Studio 里直接点模型确认。

### 2026-05-27 Scene interaction details

- Outcome: `EffectSystem` 客户端新增场景点击射线；点击运行时桌搭模型会在本机短暂抖动并回到原位，同时追加轻量 Highlight；点击 `Workspace.CoinFlipTable.TableTop` 会通过 `MusicSystem` 播放 `SoundService.SFX.tableKnock` 并生成短生命周期桌面 ripple。Studio MCP 已在 `SoundService.SFX` 下创建 `tableKnock` 占位 Sound，当前临时复用 `rbxassetid://131939835329656`，后续替换该实例 `SoundId` 即可。`PROJECT_LOGIC.md` 已同步。
- Validation: `git diff --check -- src/ReplicatedStorage/Systems/EffectSystem/init.lua src/ReplicatedStorage/Systems/EffectSystem/Presets.lua docs/TASK_STATE.md docs/PROJECT_LOGIC.md` 通过；Studio Play 单客户端启动后确认 `DecorationsRuntime` 生成 `Seat01FakeDecoration / Seat02Decoration`、`TableTop` 存在、`SoundService.SFX.tableKnock` 存在；控制台未见新脚本错误，仅有既有 StyleRule `CornerRadius` 转换警告。`luau` 命令不可用；自动鼠标点击在第一人称鼠标锁定下不适合可靠判定桌搭 / 桌面命中，最终手感留待用户在 Studio 中手动确认。

### 2026-05-27 Shop / Inventory item icons

- Outcome: `Textures.FlipACoinItems` 新增 Coin / Desk Setup / Chair / FlipACoin product / GamePass 临时 icon 配置和 `GetFlipACoinItemIcon()`；`EcoSystem/ui.lua` 渲染 Shop / Inventory 卡片时会写入对应 icon。Studio 中 `Frames.Shop.Body.Items.Item1` 到 `Item12` 的 `Art` 下补齐 `ImageLabel`，`Frames.Inventory.Body.Items.Item1` 到 `Item12` 的 `Icon` 下补齐 `ImageLabel`，后续替换图片链接只需改 `src/ReplicatedStorage/configs/Textures.lua`。`PROJECT_LOGIC.md` 已同步。
- Validation: `git diff --check -- src/ReplicatedStorage/configs/Textures.lua src/ReplicatedStorage/Systems/EcoSystem/ui.lua docs/PROJECT_LOGIC.md docs/TASK_STATE.md` 通过；Studio edit-time 确认 Shop / Inventory 各 12 张卡片均有图片节点；Studio Play 单客户端打开 Shop / Inventory 后，`Item1` 均显示 `Copper R Coin` 且图片写入 `rbxassetid://119503428482490`；配置扫描确认 Coin / Desk / Chair / Product / GamePass 均能解析到非空 icon。控制台未见新脚本错误，仅有既有 StyleRule `CornerRadius` 转换警告。

### 2026-05-27 Fake player appearance staging regression

- Outcome: 修复 fake 启动稳定性改动引入的外观回归。`CreateFakeActor()` 现在先把 rig pivot 到高空 staging 位置并 parent 到 runtime folder，再调用 `Humanoid:ApplyDescription()`、准备 rig 和头顶 GUI，最后才入座；避免未 parent rig 丢 avatar description，同时不再用低于 `FallenPartsDestroyHeight` 的 staging 位置导致 body parts 被引擎清理。
- Validation: `git diff --check -- src/ReplicatedStorage/Systems/FakePlayerSystem/init.lua docs/PROJECT_LOGIC.md docs/TASK_STATE.md` 通过；Studio Play 单客户端等待 `8` 秒后采样 `FakePlayersRuntime`，`FakePlayer1` 保留 `17` 个 body part，并有 `1` 个 Shirt、`1` 个 Pants、`1` 个 Accessory、`HairAccessory = 62724852`，不再是只剩 `Humanoid / BodyColors / Animate` 的默认空外观；控制台未见新 fake 相关错误，仅有既有 StyleRule `CornerRadius` 转换警告。

### 2026-05-27 Fake player startup stability fix

- Outcome: `FakePlayerSystem` 的 director 增加防重入 guard 和 pending create 计数，fake 模型先完成外观 / rig / head GUI 准备，再进入 runtime 并尝试入座；开局补位和 fake 释放会抑制单个 fake 的座位广播，批量处理完后只通过 `TableSeatSystem:RefreshAudienceState()` 刷新一次。`TableSeatSystem:AssignFakeActor()` / `ClearFakeActor()` 保持默认立即广播行为，但支持内部 `suppressBroadcast` 参数供 fake 批处理使用。`PROJECT_LOGIC.md` 已同步。
- Validation: 源码扫描确认 `RunDirector()` 有 `_directorRunning` guard、fake 创建使用 `_pendingFakeCreates` 计数，批量路径向 fake assign / clear 传入 `suppressBroadcast` 并最终调用 `RefreshAudienceState()`；`git diff --check -- src/ReplicatedStorage/Systems/FakePlayerSystem/init.lua src/ReplicatedStorage/Systems/TableSeatSystem/init.lua docs/PROJECT_LOGIC.md docs/TASK_STATE.md` 通过。Studio Play 单客户端 8 秒采样确认 fake 稳定为 `FakePlayer1 / FakePlayer2`，占座稳定在 `Seat01:FakePlayer1 / Seat02:FakePlayer2 / Seat03:MagicalHailuo`，玩家 root 坐标保持 `9.80,-20.82,3.69` 不变；控制台未见新 fake / seat 错误，仅有既有 StyleRule `CornerRadius` 转换警告。

### 2026-05-26 Team / SFX / scrolling shop cleanup

- Outcome: Studio 里的 legacy `red / blue / white` Team 实例已移除，运行态玩家保持无队伍且默认玩家列表不再按队伍分组；`MusicSystem` 新增本地 SFX helper，Flip、Shop、Inventory、Rebirth 和 notification 活跃音效改为统一经 `MusicSystem` 播放并读取当前 `SoundService.SFX.Volume`；`Frames.Shop.Body.Items` 与 `Frames.Inventory.Body.Items` 已通过 MCP 改为 Studio-authored `ScrollingFrame`，各补齐 `Item1` 到 `Item12` 卡片池并隐藏分页控件，`EcoSystem/ui.lua` 改为按当前 tab 直接渲染完整列表并在切 tab / 打开入口时重置滚动位置。`PROJECT_LOGIC.md` 已同步。
- Validation: MCP edit-time 确认 `Teams` 下无 Team 实例、Shop / Inventory `Items` 均为 `ScrollingFrame`、各 12 张卡片且 `PageControls.Visible = false`；源码扫描确认活跃 `EcoSystem/ui.lua` 无 `selectedShopPage / selectedInventoryPage / PageControls / updatePageControls` 分页残留；`git diff --check` 通过；Studio Play 单客户端 sanity 确认玩家 `Neutral = true` 且无 Team、PlayerGui Shop / Inventory 为 `ScrollingFrame`；临时把 `SoundService.SFX.Volume` 设为 `0` 后，通过 `MusicSystem` 播放 `coinSpin / coinLand` 创建的实例音量为 `0`。`luau` 命令不可用，`stylua --check` 因 Aftman 未在仓库或用户 `aftman.toml` 注册 stylua 被拒绝运行；Play 控制台未见新脚本错误，仅有既有 StyleRule `CornerRadius` 转换警告。

### 2026-05-24 UpgradeButtons state ordering fix

- Outcome: 修复 `CoinFlipHUD.Content.RightPanel.UpgradeButtons` 升级后偶尔回退旧等级的问题；`CoinFlipSystem` 服务端给每次 HUD 状态同步加递增 `stateVersion`，客户端 `SyncRunState()` 会跳过低于当前版本的旧 payload，避免 flip 落地回调延迟应用旧 `runData` 覆盖已购买升级后的按钮等级。
- Validation: `git diff --check -- src/ReplicatedStorage/Systems/CoinFlipSystem/init.lua src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua docs/TASK_STATE.md` 通过；源码扫描确认 `stateVersion` 只由服务端 `stampClientState()` 写入，客户端用 `latestRunStateVersion` 拒绝旧同步。按仓库规则未运行 `rojo build`，未执行 Studio Play。

### 2026-05-24 CoinFlip guidance notification cleanup

- Outcome: 移除 CoinFlip 主循环内的教学 / 建议类 toast：Tails 后不再弹 `Next: buy Value or flip again` 或重建 streak 提示，首次可升级时只保留 HUD 升级按钮 pulse，不再弹升级建议文字；服务端 onboarding 仍保留状态、头顶文案和漏斗埋点，但不再通过 `GuiSystem:SetNotification()` 发阶段 toast。`PROJECT_LOGIC.md` 已同步。
- Validation: 教学 / 建议通知关键词扫描无命中；`SetNotification` 在 `CoinFlipSystem` 内无命中；`git diff --check -- src\ReplicatedStorage\Systems\CoinFlipSystem\ui.lua src\ReplicatedStorage\Systems\CoinFlipSystem\init.lua src\ReplicatedStorage\Systems\CoinFlipSystem\Modules\Onboarding.lua docs\PROJECT_LOGIC.md docs\TASK_STATE.md` 通过。未执行 Studio Play。

### 2026-05-24 Fake flip first-rebirth conflict fix

- Outcome: 修复 fake actor 共享 `CoinFlipSystem` actor 结算时误走真实玩家 `getPlayerState()` 的冲突；`actor.isFake and nil or ...` 因 `nil` falsey 会继续取 `actor.player`，导致假玩家 flip 报 `attempt to index nil with 'UserId'`，现改为显式 Luau if expression，fake flip 不再访问真实 Player state，首次 rebirth 隐形加成仍只作用于真实玩家。
- Validation: `git diff --check -- src\ReplicatedStorage\Systems\CoinFlipSystem\init.lua docs\TASK_STATE.md` 通过；Studio Play 单客户端等待约 `12` 秒，fake rig 生成并占座，控制台未再出现 `CoinFlipSystem:62` 或 scheduled fake flip 报错。未执行多客户端验证。

### 2026-05-24 Fake player behavior tuning

- Outcome: 假玩家人数目标刷新从几十秒改为 `10` 到 `20` 分钟级别，移除短 tick 随机离座；fake actor 改为高频随机检查 Flip，接近真实玩家持续 Flip 的节奏，并通过独立随机动作时间降低同时 Flip 的概率。非 Flip 行为改为短促摇头 / 点头，不再持续看向真实玩家；客户端收到假玩家 `ObservedFlip` 时会在本机临时驱动 fake Rig 头部看向该座位硬币视觉。`PROJECT_LOGIC.md` 已同步行为节奏和客户端表现规则。
- Validation: `git diff --check` 通过；`rojo build default.project.json --output $env:TEMP\flip_fake_behavior_check.rbxl` 通过；源码扫描确认 fake 行为仍由 `ScheduleModule` 驱动，新增代码未引入 `while task.wait()`，旧 `LookAtRealPlayerChance / RandomLeaveChance / getRandomRealPlayer` 路径已移除；Studio Play 单客户端 sanity 确认 `FakePlayersRuntime` 生成 `FakePlayer2`，假玩家坐在 `Seat02`，座位硬币视觉存在，控制台未出现 fake 相关错误。未执行多客户端观感验证。

### 2026-05-24 First rebirth tuning

- Outcome: 新增 0 rebirth 真实玩家首局隐形正面率保护：Cash 未达首个 rebirth 门槛时实际结算获得 `+7%` 隐形加成，连续 Tails 后每次再加 `+4%`，保护后实际正面率封顶 `45%`，但 HUD 仍显示不含隐形保护的正常 Chance；rebirth baseline 现在按 `min(rebirth, 3)` 自动给起始 Bias，并继续叠加 `Lucky Start`；fake player 创建时随机获得 `0` 到 `5` 级表演用 `biasLevel`，不接入真实 rebirth 规则。`PROJECT_LOGIC.md` 已同步。
- Validation: `git diff --check -- src\ReplicatedStorage\configs\GameConfig.lua src\ReplicatedStorage\Systems\CoinFlipSystem\Presets.lua src\ReplicatedStorage\Systems\CoinFlipSystem\init.lua src\ReplicatedStorage\Systems\RebirthSystem\Presets.lua src\ReplicatedStorage\Systems\RebirthSystem\init.lua src\ReplicatedStorage\Systems\FakePlayerSystem\Presets.lua src\ReplicatedStorage\Systems\FakePlayerSystem\init.lua docs\PROJECT_LOGIC.md docs\TASK_STATE.md` 通过，仅有既有 LF-to-CRLF 工作区提示；源码扫描确认 `BuildDerivedStats()` 仍使用可见 `GetHeadsChance()`，实际 roll 使用 `GetRollHeadsChance()`，fake actor 的随机 `biasLevel` 范围为 `0` 到 `5`；`stylua --check` / `selene` 因 Aftman 未在仓库或用户 `aftman.toml` 注册对应工具被拒绝运行。

### 2026-05-24 Head streak display

- Outcome: 真实玩家和假玩家头顶 Billboard 第一行从座位号改为当前 `Streak N`；装备 Coin 名称保留在下一行，避免连胜大于 `0` 时两行重复显示 streak。`PROJECT_LOGIC.md` 已同步头顶展示规则。
- Validation: `git diff --check -- src\ReplicatedStorage\Systems\PlayerSystem\init.lua src\ReplicatedStorage\Systems\FakePlayerSystem\init.lua docs\PROJECT_LOGIC.md docs\TASK_STATE.md` 通过，仅有既有 LF-to-CRLF 工作区提示；源码扫描确认头顶 `vip.Text` 只写入 `Streak {streak}`，未发现继续把 `seatId or "Spectating"` 写到头顶第一行。

### 2026-05-24 Fake player system

- Outcome: 新增并注册 `FakePlayerSystem`，服务端在真实玩家数为 `1` 到 `2` 时维护 `1` 到 `3` 个假玩家；假玩家从 `PlayerSystem.Assets.Rig` 克隆模型，随机套用 `PlayerPresets.FakeUserIds / FakeNames`、Coin、Desk Setup 和 Chair，占用桌面座位并拥有头顶信息、装饰、视线动作和随机离座/补位行为。`TableSeatSystem` 支持 fake actor 占座、座位快照和真实玩家需要座位时释放假玩家；`CoinFlipSystem` 抽出 actor flip 结算，真实玩家和假玩家共享结果概率、奖励、streak、ObservedFlip 和公告表现，但假玩家只更新内存状态；`DecorationSystem` 支持 fake actor 桌搭和椅子刷新/清理。`PROJECT_LOGIC.md` 已同步系统注册、低人数补位规则、fake 不写存档/analytics/leaderstats 和运行时资源约定。
- Validation: `git diff --check` 通过；`rojo build default.project.json --output $env:TEMP\flip_fake_player_check.rbxl` 通过；源码扫描确认新增 fake 路径未使用 `while task.wait()` 死循环，fake flip 不写 profile / leaderstats / analytics，`SetOneData`、`AddResource` 和 `LogCoinFlipResolved` 仍只在真实玩家分支。`stylua` / `selene` 未在仓库或用户 `aftman.toml` 注册，`luau` 命令不可用；Roblox Studio MCP 未发现已连接 Studio 实例，因此未执行 Play / 多客户端视觉验证。

### 2026-05-24 Coin display names

- Outcome: `EcoSystem/Presets.lua` 的 Coin 配置按用户图从左到右命名为 `Copper R Coin`、`Steel R Coin`、`Golden R Coin`、`Crimson Ring Coin`、`Amethyst R Coin`、`Rose Gear Coin`、`Sunburst R Coin`、`Emerald Cut Coin`、`Sapphire Halo Coin`、`Ancient Ruby Coin`；新增 `coin10` 商品条目并把 Apex bundle 改为解锁 `coin10`；`PROJECT_LOGIC.md` 已同步 Coin 资产范围为 `coin1` 到 `coin10`。
- Validation: `git diff --check -- src\ReplicatedStorage\Systems\EcoSystem\Presets.lua docs\PROJECT_LOGIC.md docs\TASK_STATE.md` 通过，仅有既有 LF-to-CRLF 工作区提示；配置扫描确认 `coin1` 到 `coin10` 和 Apex bundle `coin10` 解锁存在；按仓库规则未运行 Rojo build。

### 2026-05-24 Decoration and chair display names

- Outcome: `EcoSystem/Presets.lua` 的 Desk Setup 从 4 个扩展为图 1 从左到右的 8 个 table decoration 名称，Chair 11 个 `displayName` 按图 2 从左到右改为外形命名；Apex bundle 改为解锁最高级 `Amethyst Hourglass / Royal Chaise`；`PROJECT_LOGIC.md` 和 task-state follow-up 已同步桌搭 id 范围与名称。
- Validation: `git diff --check -- src\ReplicatedStorage\Systems\EcoSystem\Presets.lua docs\PROJECT_LOGIC.md docs\TASK_STATE.md` 通过，仅有既有 LF-to-CRLF 工作区提示；旧桌搭名与椅子编号占位名扫描无源码 / 项目逻辑残留；按仓库规则未运行 Rojo build。

### 2026-05-24 HUD wallet cleanup and Auto state color

- Outcome: `AutoButton` 开启时同步把文字和 `UIStroke` 改为绿色，关闭时恢复纯白；玩法 HUD 不再显示或更新右上 `Elements.cash / candy`，只保留左下 Cash 显示；当前打开的 Studio `StarterGui` 默认 Auto off 状态也已设为白色。
- Validation: `git diff --check -- src\ReplicatedStorage\Systems\CoinFlipSystem\ui.lua src\StarterGui\Main\uiClient.client.lua docs\PROJECT_LOGIC.md docs\TASK_STATE.md` 通过，仅有既有 LF-to-CRLF 工作区提示；Studio edit-time 确认 `AutoButton` off 文字 / 描边为白色，`Elements.cash / candy` 保持隐藏；Studio Play 单客户端 sanity 确认运行态 `Auto:Off` 为白色且右上 `cash / candy` 隐藏；按仓库规则未运行 Rojo build。

### 2026-05-23 Disable mobile TouchGui

- Outcome: `uiClient.client.lua` 在触屏设备上禁用 Roblox 默认 `TouchGui`，同时监听后续自动生成的 `TouchGui` 并禁用；移除旧的 `TouchGuiFake` / `JumpButton` 尺寸位置调整路径；同步更新 `PROJECT_LOGIC.md`。
- Validation: `git diff --check -- src\StarterGui\Main\uiClient.client.lua docs\PROJECT_LOGIC.md docs\TASK_STATE.md` 通过，仅有既有 LF-to-CRLF 工作区提示；按仓库规则未运行 Rojo build，未做移动端真机验证。

### 2026-05-23 Disable mobile UI redistribution

- Outcome: 临时注释 `CoinFlipSystem/ui.lua` 的 mobile HUD profile，使移动端沿用桌面 / narrow HUD 布局，不再触发 portrait 统计折叠；临时注释 `uiController.OpenFrame()` 中 Shop / Inventory / Rebirth 的移动端 growth panel 重排和 viewport 绑定调用；同步更新 `PROJECT_LOGIC.md`。
- Validation: `git diff --check -- src\ReplicatedStorage\Systems\CoinFlipSystem\ui.lua src\StarterGui\Main\uiController.lua docs\PROJECT_LOGIC.md docs\TASK_STATE.md` 通过，仅有既有 LF-to-CRLF 工作区提示；按仓库规则未运行 Rojo build，未做 Studio / 真机观感验证。

### 2026-05-20 FlipACoin monetization implementation

- Outcome: `EcoSystem/Presets.lua` 新增 FlipACoin 专用 Developer Product 和 Game Pass 占位配置；`EcoSystem` receipt 可发 Cash、Rebirth Points、Apex 外观礼包并同步成长状态；gamepass ownership 会写入 `gamePasses`，VIP 解锁外观，`winsX2 / luckyCharm / quickFlip` 合入 flip 奖励、概率和间隔加成，且 `winsX2` 覆盖 Heads 奖励与 Tails 保底 Cash；`EcoSystem/ui.lua` 复用 Shop 卡片并新增 TopbarPlus `Boosts` 入口，未配置 id 时显示 `Set ID` 且禁用购买；同步更新 `PROJECT_LOGIC.md`。
- Validation: `git diff --check` 通过；新增付费 key / Marketplace prompt / `winsX2` 二次倍率引用扫描通过；`stylua --check` 因 Aftman 未在仓库 / 用户 `aftman.toml` 注册 stylua 无法运行；本机未发现 `luau` / `selene`；Studio MCP 当前只连接 `⛏️Ding-Dong Dig & Forge!⛏️`，未改 Studio UI 资产，也未做 Play / 购买 prompt 验收。

### 2026-05-20 Onboarding economy and social effects polish

- Outcome: 新档默认 `wins` 从 `30` 调整为 `9`，首局引导文案对齐为“Flip 3 次赚到第一次升级”；`ObservedFlip` 继续复用现有 payload，但会标记 milestone，`EffectSystem` 为观察者 Heads / Tails 使用更强落地 pulse，为 Heads streak 追加按 streak 放大的 ring，高 streak / milestone 创建短生命周期 `Highlight`；`PlayStreakMilestone()` 在 VFX 资产缺失或类型无效时 fallback 到程序化 pulse + highlight，已有 VFX 仍优先播放，camera shake 仍只由 milestone 配置触发。
- Validation: `git diff --check` 通过；`wins = 9` / onboarding 文案 / observed visual options / `EffectSystem` 新 preset 与 fallback 引用扫描通过；`stylua --check` 因 Aftman 未在仓库 / 用户 `aftman.toml` 注册 stylua 无法运行；本机未发现 `luau` / `luau-analyze` / `selene`；本轮按用户说明未打开 Studio，单客户端 / 双客户端观感留待 Studio Play 验收。

### 2026-05-19 Analytics service instrumentation

- Outcome: 新增并注册 `AnalyticsSystem` 作为 Roblox `AnalyticsService` 的服务端内部门面；接入座位分配、Flip 结果 / streak milestone、run upgrade、shop purchase / equip、rebirth / rebirth upgrade 成功路径；保留 `EcoSystem:AddResource()` 现有 economy event 和首局 onboarding funnel；同步更新 `PROJECT_LOGIC.md`。
- Validation: `git diff --check` 通过；`AnalyticsSystem` / `coinflip_` 事件引用扫描通过；`stylua --check` 因 Aftman 未在仓库 / 用户 `aftman.toml` 注册 stylua 无法运行；本机未发现 `luau` / `luau-analyze` / `selene`。

### 2026-05-19 Streak milestone effects

- Outcome: 固定 streak milestone 改为读取 `AnnouncementSystem/Presets.lua` 的 `StreakEffects` 配置；默认 `5` 播放 `streak1` SFX / VFX，`10` 播放 `streak2` SFX / VFX 并触发 camera shake；milestone payload 会随自己和同桌观察者的 flip payload 下发，客户端等硬币本地落地后由 `EffectSystem:PlayStreakMilestone()` 播放表现；通知仍走低噪音 `SetNotification()`。
- Validation: `git diff --check` 通过；旧 `Presets.Thresholds` / streak `soundName` 引用扫描通过；`stylua --check` 因 Aftman 未在仓库 / 用户 `aftman.toml` 注册 stylua 无法运行；本机未发现 `luau` / `luau-analyze` / `selene`。

### 2026-05-19 Onboarding plan execution

- Outcome: 首局引导状态升到 `version = 2`，改为自动入座确认、首次 Flip、flip `3` 次、首次升级、升级后再 Flip 理解 streak；旧 `approachSeat / sitDown` action 和旧存档会迁移兼容；首次升级步骤会对已有 HUD 升级按钮做短 pulse 和通知提示；同步更新 `PROJECT_LOGIC.md`。
- Validation: `git diff --check` 通过；旧找座 / 手动坐下 / `2 streak` 随机门槛文案扫描仅剩旧存档迁移兼容引用；`stylua --check` 因 Aftman 未在仓库 / 用户 `aftman.toml` 注册 stylua 无法运行；本机未发现 `luau` / `luau-analyze` / `selene`。

### 2026-05-19 Onboarding design review

- Outcome: 完成当前首局引导设计评估：保留“低打扰、无旧浮层”的方向，但建议把旧找座/坐下语言改成自动入座确认、首 Flip、首次升级和 streak 目标的轻提示计划；本轮未改 Luau 或 Studio UI 资产。
- Validation: 源码阅读覆盖 `CoinFlipSystem/Modules/Onboarding.lua`、`CoinFlipSystem/init.lua`、`CoinFlipSystem/ui.lua`、`TableSeatSystem/init.lua`、`PlayerSystem/init.lua` 与项目文档；未运行 Studio Play。

### 2026-05-19 In-flight random coin spin

- Outcome: `EffectSystem` now decides the random tabletop yaw at flip start, applies extra randomized yaw turns while the coin is airborne, and blends the final descent into the exact flat Heads / Tails rest orientation so the coin no longer visibly rotates after it has landed.
- Validation: `git diff --check` passed; Studio MCP / Play validation intentionally skipped per user request, with final visual feel left for manual Studio review.

### 2026-05-19 Random coin landing yaw

- Outcome: `EffectSystem` now applies a random tabletop yaw around the table surface normal whenever a coin settles, stores that yaw with the persistent coin visual, and reuses it for idle refresh / delayed coin replacement so the coin stays flat while keeping its landed Heads / Tails face.
- Validation: `git diff --check` passed; Studio Play single-client sanity confirmed HUD stayed visible, coin remained about `0.01` studs above `TableTop`, and consecutive flips changed the coin's tabletop orientation; `stylua --check src/ReplicatedStorage/Systems/EffectSystem/init.lua` could not run because Aftman has no `stylua` entry in repo/user `aftman.toml`.

### 2026-05-18 Coin result persistence and HUD visibility

- Outcome: `CoinFlipSystem` now sends delayed post-join run-state resyncs so the HUD recovers after auto-seat timing races; `CoinFlipSystem/ui.lua` keeps the gameplay HUD visible during flip and only disables repeat flip input; `EffectSystem` stores each persistent coin visual's last result so Tails / Heads survives seat refreshes, idle re-placement, and delayed coin replacement.
- Validation: `git diff --check` passed; Studio Play after restart confirmed HUD visible after auto-seat (`Click FLIP`, left/right panels and Flip button visible), equipped coin exists as a Model with `PrimaryPart = coin`, a Tails result kept identical coin orientation after a 1 second refresh wait, and the landed coin stayed about `0.01` studs above `TableTop`; `stylua --check` could not run because Aftman has no `stylua` entry in repo/user `aftman.toml`.

### 2026-05-18 Coin PrimaryPart landing correction

- Outcome: `EffectSystem` now treats equipped coin Model `PrimaryPart` as the coin focus for camera follow, keeps fallback coin movement only for fallback tracking, resolves landed height from one `TableTop` raycast plus one bounds lift, and moves dynamic landing radius from `4.4` to `5.4` so the player's coin sits closer on the table; synchronized `PROJECT_LOGIC.md`.
- Validation: `git diff --check` passed; Studio MCP confirmed all 10 `CoinFlipSystem.Assets.Coins` Models have `PrimaryPart`; Studio Play single-client sanity confirmed `Seat01` equipped coin Model uses `PrimaryPart = coin` and rests/lands with about `0.01` studs gap above `TableTop`; `stylua --check` could not run because Aftman has no `stylua` entry in repo/user `aftman.toml`; local `selene` / `luau` commands were unavailable; multi-client visual QA remains user-side.

### 2026-05-18 Mobile growth panel safe-area code pass

- Outcome: `uiController.OpenFrame()` 会在触屏移动端对现有 `Shop / Inventory / Rebirth` Frame 套用 viewport / Core UI inset 感知的 Scale 布局，打开面板和 viewport 变化时都会刷新；未新增运行时 editable prefab 或并行 UI 系统；同步更新 `PROJECT_LOGIC.md` 和 `ROBLOX_PLATFORM_IMPROVEMENT.md`。
- Validation: `git diff --check` 通过；`stylua --check src/StarterGui/Main/uiController.lua` 因 Aftman 未在仓库 `aftman.toml` 列出 stylua 被拒绝运行；本机未发现 `selene` / `luau` 可执行命令；Roblox Studio MCP 未发现打开的 Studio 实例，未做 Studio Play / 真机 / 多客户端 QA。

### 2026-05-18 Dynamic table seating and persistent coin visuals

- Outcome: `TableSeatSystem` 按当前活跃入座人数计算 `360 / n` 圆环座位目标并 tween 座位；`DecorationSystem` 会把现有桌搭 / 椅子 tween 到动态座位推导出的目标位；`CoinFlipSystem/ui.lua` 在 `Auto:On` 时不再请求相机跟随；`EffectSystem` 改为每座位维护一个持久 coin visual，idle 留在桌面、flip 垂直抛起落回同一落点，换装在 flip 中会延后到落地后替换；同步更新 `PROJECT_LOGIC.md`。
- Validation: `git diff --check` 通过；`stylua --check` 因 Aftman 未在仓库 `aftman.toml` 列出 stylua 被拒绝运行；本机未发现 `selene` 可执行命令；Roblox Studio MCP 未发现打开的 Studio 实例，未做 Play / 多客户端 / 设备观感验证。

### 2026-05-18 Mobile HUD P0 code pass

- Outcome: `CoinFlipSystem/ui.lua` 已接入 `Presets.UiLayout` 的 mobile HUD 参数；触屏且 viewport 命中移动端 profile 时会用 Scale 调整 `CoinFlipHUD` 尺寸 / 位置，监听 camera viewport 变化刷新布局，触屏端隐藏 keyboard / gamepad 输入提示，ready 文案改为 `Tap FLIP`，手机 portrait 下折叠 Chance / Speed 状态以优先保留主操作、Auto、Cash、Streak 和升级入口；同步更新 `PROJECT_LOGIC.md` 的移动端现状。
- Validation: `git diff --check` 通过；`stylua --check src/ReplicatedStorage/Systems/CoinFlipSystem/ui.lua` 因 Aftman 未在仓库 `aftman.toml` 列出 stylua 被拒绝运行；Studio 未开启，未做 Play / device QA。

### 2026-05-18 Roblox platform and mobile improvement plan

- Outcome: 新增 `docs/ROBLOX_PLATFORM_IMPROVEMENT.md`，记录当前 Roblox 平台匹配度、移动端就绪评分、证据、P0/P1/P2 改进项、落地顺序和实机 QA 清单；同步修正 `TASK_STATE.md` 中过时的 mobile 口径，明确当前是“基础触屏可玩，但移动端布局、提示、安全区和实机观感仍需专项收敛”。
- Validation: 文档层检查完成；未改 Luau 源码或 Studio 资产，未运行 Play / Rojo 验证。

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
