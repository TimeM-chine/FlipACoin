# Creator Dashboard Package

最后更新：2026-07-12

本文件只提供待上传配置，不自动修改 Creator Dashboard 或开放游戏。

## Listing

- Name: `Flip A Coin`
- Description line 1: `Take a seat and FLIP. Build Cash, chase streaks, and turn one coin into five.`
- Description line 2: `Upgrade each run, Rebirth for permanent table power, and share big moments with the whole table.`
- Additional copy:
  - `Tap FLIP, press Space, or use controller RT.`
  - `Heads and Tails both move your run forward.`
  - `Unlock Coins, Desk Setups, Chairs, and multi-coin flips.`
  - `No betting, wagering, or player-to-player gambling.`

## Media Order

1. `output/icon/flip-a-coin-icon-centered-512.png`
2. 真实 Fresh Run HUD 首屏。
3. 真实双客户端 Perfect Five / Table Bonus。
4. 真实首次双币或 Rebirth 完成状态。
5. 现有三张渲染式市场图作为补充包装，不作为实际 HUD 证明。
6. 12-18 秒实机视频：入座 -> Flip -> 升级 -> streak -> 多币/高光。

已核对的包装结论：icon 在小尺寸仍以完整硬币为主体；三张渲染图没有下注、筹码或随机赢钱文字。`market-abtest-a-core` 的红色实体按钮并非实际操作界面，只能作为补充概念图，不能排在真实黄色 HUD `FLIP` 首屏之前。

## Configuration Checklist

- [ ] Icon 在约 `150x150` 预览仍能识别完整硬币。
- [ ] 前三张 thumbnail 至少一张为真实 HUD，且无文字/安全区裁切。
- [ ] 设备只声明实际通过的 Desktop、Phone、Tablet、Gamepad。
- [ ] 手机方向保持 landscape。
- [ ] Developer Product / Game Pass 标题与固定发货一致。
- [ ] 内容成熟度、付费内容披露、隐私和本地化配置完成。
- [ ] 包装不使用下注、赌场、赌桌、筹码或 Robux 随机赢钱文案。
- [ ] 发布前再次确认 QA 顶栏和 TestSystem 在非 Studio 环境不可用。

## Release Gate

- `SOFT LAUNCH`：所有自动项通过，真手机/真手柄和 2/8 客户端完成，且没有 P0。
- `NO-GO`：存档或发货事故、核心 Flip 失败、目标设备不可操作或严重多人状态不一致。
