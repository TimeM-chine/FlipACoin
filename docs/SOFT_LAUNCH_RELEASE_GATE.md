# Soft Launch Release Gate

最后更新：2026-07-12

## Current Decision

`CLOSED TEST`，待人工门禁关闭后目标转为 `SOFT LAUNCH`。

当前没有已证实 P0。2/8客户端、真手机、真平板和真手柄已由用户确认通过；Table Bonus专项、通知优先级运行和双客户端真实素材仍未关闭。未执行不是失败，也不能按通过处理。

## Automatic Gate

- [x] 核心 Flip、升级、Rebirth、2-5 Coin、Perfect Five、Edge Stand 单客户端情景通过。
- [x] Studio QA 仅在 Studio 注册，情景使用白名单并由服务端校验。
- [x] Studio Analytics 隔离，QA/Fake Player 不应污染首批正式数据。
- [x] 首批最小漏斗和购买三阶段事件已定义。
- [x] 30 分钟 Long Session 无持续对象、通知、输入或错误增长；发现并修复 Highlight Tween 持有链后完整重跑通过。
- [x] 通知优先级运行验证通过；旧普通通知计时不会提前清除高优先消息。
- [x] `git diff --check` 通过。

## Human Gate

- [x] 真手机横屏可完整操作。
- [x] 真平板安全区、文字和滚动通过。
- [x] 真手柄完整路径无焦点死路。
- [ ] 2 客户端同步、重生/离服已通过；Table Bonus专项仍待复核。
- [x] 8 客户端满桌、等待、Fake Player 让位和补位通过。
- [x] 音效层级与 coin-follow 相机舒适度通过。
- [ ] 三张真实运行截图和 12-18 秒视频整理完成。

## Decision Rule

- `SOFT LAUNCH`：Automatic Gate 全部通过，Human Gate 全部通过，没有 P0。
- `CLOSED TEST`：核心链路可运行，但仍有目标设备或多人路径未验证。
- `NO-GO`：出现存档/发货事故、核心 Flip 失败、目标设备不可操作或严重多人状态不一致。

不得用玩家数据尚不存在来判失败，也不得把设计推断写成已验证留存或付费结论。
