---
name: UI Optimization Plan
overview: A comprehensive, cross-device UI optimization plan for the Flip A Coin project, designed to be executable by any LLM.
todos:
  - id: opt-hud
    content: Apply responsive scale and AnchorPoint to CoinFlipHUD
    status: pending
  - id: opt-overview
    content: Refactor CoinFlipTableOverview and SpectatorFeed for cross-device layout
    status: pending
  - id: opt-onboarding
    content: Update CoinFlipOnboarding with relative sizing and animations
    status: pending
  - id: opt-billboards
    content: Optimize SeatInfoBillboard and onPlayerHead with distance scaling and compact modes
    status: pending
  - id: opt-notifications
    content: Optimize dynamically generated Notification and Announcement Banners
    status: pending
isProject: false
---

# Flip A Coin 界面跨端优化方案 (Cross-Device UI Optimization Plan)

这份方案旨在为 `Flip A Coin` 项目提供一套标准化的界面优化指南。任意大模型（LLM）均可基于此方案，在不破坏现有业务逻辑（如 `CoinFlipSystem/ui.lua` 和 `uiController.lua`）的前提下，实现高质量、跨设备（PC、移动端、主机）的 UI 适配与视觉升级。

## 1. 核心适配策略 (Cross-Device Strategy)

为了确保 UI 在不同分辨率和设备上表现一致，所有界面的重构必须遵循以下原则：

*   **使用相对尺寸 (Scale) 与 AnchorPoint**：
    *   废弃绝对像素值（Offset），全面改用 `Scale` 来定义 `Size` 和 `Position`。
    *   正确设置 `AnchorPoint`（如居中对齐使用 `0.5, 0.5`，右侧对齐使用 `1, 0.5`），确保在屏幕缩放时 UI 元素不会偏移出界。
*   **引入 UIScale 与 UIAspectRatioConstraint**：
    *   在主容器（如 `CoinFlipHUD` 的 `Content`）中添加 `UIAspectRatioConstraint`，保持核心操作区的长宽比。
    *   对于移动端，可通过脚本或 `UISizeConstraint` 限制最大和最小尺寸，防止 UI 过大遮挡视野或过小无法点击。
*   **响应式布局 (Responsive Layout)**：
    *   列表类 UI（如 `CoinFlipTableOverview.List`）必须使用 `UIListLayout` 或 `UIGridLayout`，并配合 `UIPadding` 控制边距。
    *   文本元素需开启 `TextScaled = true`，并配合 `UITextSizeConstraint` 限制最大字号。

## 2. 视觉设计规范与环境融合 (Design System & Environmental Integration)

*   **环境融合 (Environmental Harmony)**：
    *   提取 3D 场景（如 `CoinFlipTable` 的材质、灯光）的色调。UI 背景建议采用带轻微模糊 (`BackgroundBlur` 或 `UIVisualEffect`) 的材质，或者与场景主色调（如桌面布料的绿色/红色/深色木纹）相呼应的半透明深色，减少 UI 的突兀感，使其像场景的一部分。
*   **色彩系统 (Color Palette)**：
    *   **主背景 (Background)**：深色半透明，如 `Color3.fromRGB(15, 18, 26)`，`BackgroundTransparency = 0.2`，配合场景色调微调。
    *   **边框 (Stroke/Border)**：使用 `UIStroke` 替代传统的 Border，颜色为 `Color3.fromRGB(40, 50, 65)`，厚度 `2px`。
    *   **高亮/强调 (Accent/Featured)**：用于 `featured seat` 或高光时刻，使用金色/亮黄色 `Color3.fromRGB(255, 215, 0)`。
*   **圆角规范 (Corner Radius)**：
    *   所有面板和按钮统一使用 `UICorner`，`CornerRadius = UDim.new(0, 8)` 或 `UDim.new(0.05, 0)`。
*   **字体排版 (Typography)**：
    *   标题 (Title)：`Font.GothamBold` 或 `Font.FredokaOne`，白色。
    *   正文 (Body)：`Font.GothamMedium`，浅灰色 `Color3.fromRGB(200, 200, 200)`。

## 3. 具体界面优化执行清单 (Specific UI Optimizations)

**注意：此清单涵盖了当前主玩法涉及的所有活跃 Frame 与 BillboardGui。**

### 3.1 主操作区：`StarterGui.Main.Elements.CoinFlipHUD` (Frame)
*   **现状**：当前 Size 为绝对值 `{0, 680}, {0, 250}`，在小屏幕上会溢出。
*   **优化动作**：
    *   将 Size 改为 `{0.6, 0}, {0.25, 0}`，并添加 `UIAspectRatioConstraint`。
    *   位置设为底部居中：`AnchorPoint = Vector2.new(0.5, 1)`，`Position = UDim2.new(0.5, 0, 0.95, 0)`。
    *   内部按钮和文本全部改为 Scale 布局，确保按钮在手机上有足够大的点击热区（至少 44x44 pt）。
    *   背景材质与桌子材质呼应。

### 3.2 观战与桌况：`CoinFlipTableOverview` & `CoinFlipSpectatorFeed` (Frame)
*   **现状**：Overview 位于右侧，Feed 位于底部，缺乏统一的视觉层级。
*   **优化动作**：
    *   **CoinFlipTableOverview**：固定在屏幕右侧中间 `AnchorPoint = Vector2.new(1, 0.5)`，`Position = UDim2.new(0.98, 0, 0.5, 0)`。Size 改为 `{0.2, 0}, {0.4, 0}`。为 `List` 添加平滑滚动效果，并确保 `EmptyLabel` 在无数据时居中显示。
    *   **CoinFlipSpectatorFeed**：作为横幅显示在顶部或底部安全区内。增加淡入淡出动画（由 `uiController` 或本地脚本驱动）。

### 3.3 新手引导：`CoinFlipOnboarding` (Frame)
*   **现状**：固定在左上角，绝对尺寸 `{0, 328}, {0, 154}`。
*   **优化动作**：
    *   改为相对尺寸 `{0.25, 0}, {0.15, 0}`。
    *   `ProgressBar` 增加平滑的 Fill 动画（TweenService）。
    *   `TaskLabel` 和 `HintLabel` 增加呼吸灯效果（透明度渐变），引导玩家视线。

### 3.4 动态通知与播报：`Announcement Banner` & `Notifications` (Frame)
*   **现状**：由 `AnnouncementSystem/ui.lua` 和 `uiController.SetNotification` 动态生成。
*   **优化动作**：
    *   检查动态生成的 Frame 模板，确保它们同样使用了 Scale 布局和 `UIAspectRatioConstraint`。
    *   统一通知的背景色、圆角（`UICorner`）和描边（`UIStroke`），与主 UI 风格保持一致。

### 3.5 场景 3D UI：`SeatInfoBillboard` & `onPlayerHead` (BillboardGui)
*   **现状**：BillboardGui 容易在远距离重叠，或在近距离过大。
*   **目标对象**：
    *   `Workspace.CoinFlipTable.Seats.SeatXX.SeatInfoBillboard`
    *   `StarterGui.Templates.onPlayerHead`
    *   `StarterGui.Main.Elements.damage` (若在主玩法中触发)
*   **优化动作**：
    *   开启 `AlwaysOnTop = true`（已开启），但需调整 `MaxDistance`（建议设为 60-80）。
    *   启用 `DistanceLowerLimit` 和 `DistanceUpperLimit` 来实现基于距离的自动缩放（Distance Scaling），让其与 3D 环境更融洽。
    *   对于非 `featured seat`（普通座位），使用 Compact 模式（隐藏细节文本，缩小尺寸），减轻全桌信息噪音。
    *   字体颜色和描边需在 3D 场景的各种光照下保持高对比度（如白色字体加深色 `UIStroke`）。

## 4. 给大模型的执行指南 (Instructions for LLMs)

任何接管此任务的大模型，请按以下步骤操作：

1.  **读取目标 UI**：使用 `inspect_instance` 工具读取目标 UI 的当前属性（如 `StarterGui.Main.Elements.CoinFlipHUD`）。
2.  **生成修改脚本**：编写 Luau 脚本或使用 `multi_edit` 工具，将上述【视觉设计规范】和【适配策略】应用到目标 UI 的属性上。
    *   *注意：必须保留原有的对象名称（Name）和层级结构，因为 `CoinFlipSystem/ui.lua` 依赖这些名称进行逻辑绑定。*
3.  **注入适配脚本（可选）**：如果需要动态适配（如检测到手机端时改变布局），请在 `StarterGui/Main/uiClient.client.lua` 或对应的 `ui.lua` 中添加 `UserInputService` 或 `GuiService` 的设备检测逻辑。
4.  **验证**：确保修改后的 UI `Size` 和 `Position` 全部不包含硬编码的 Offset（除非是边框或极小的 Padding）。