# Launch QA Evidence

最后更新：2026-07-12

| 范围 | 状态 | 当前证据 | 后续动作 |
|---|---|---|---|
| Studio-only 注册边界 | 自动通过 | `SystemMgr` 只在 `IsStudio` 时 require `TestSystem`；生产注册表无该系统 | Studio Play 后确认生产发布配置不出现 QA 顶栏 |
| QA Remote 校验 | 自动通过 | 只接受预定义 `scenario` 字符串；服务端校验 Studio、sender、Player 和白名单 | 用未知枚举确认被拒绝 |
| DebugData 隔离 | 自动通过 | 每个情景先恢复完整 DebugData；DefaultData 和 schema 未改 | Fresh Run 核对 Cash 9、0 Rebirth、默认装备与引导 |
| Rebirth / Coin Spread 状态 | 单客户端通过 | Rebirth Ready 真实请求将 Cash `$250→$30` 并存入 1 RP；Coin Spread 真实购买变为 Lv.1/4、RP `1→0` | Team Test 复核观察者同步 |
| Multi Coin 2-5 | 单客户端通过 | 情景依次返回 2/3/4/5 枚结果；Coin Spread 首次双币为 `1/2 Heads`，排列、HUD 与镜头正常 | 2客户端复核观察者视角与清理 |
| Perfect Five / Edge Stand | 单客户端通过 | Perfect Five 为 `5/5 Heads +$200`；Edge Stand 为双 Tails、`Streak saved +$12`，均走生产 RequestFlip | Team Test 复核 Table Bonus 和广播优先级 |
| Fake Player 隔离 | 自动通过 | forced outcome hook 显式排除 `actor.isFake` | Team Test 确认无真实奖励/埋点 |
| 手柄运行时接入 | 结构通过，人工未验证 | Shop 初始焦点为 CoinTab；10 个透明 SelectButton 均不可选，10 个 BuyButton 均有方向链接 | 真手柄启动后接入并走完四面板 |
| 通知抢占计时 | 运行通过 | 高优先消息出现后，在普通消息旧计时到期点仍完整显示，并在自身时长结束后正常消失 | 无后续动作 |
| Studio QA 面板实例 | 通过 | Studio-authored `Frames.StudioQA` 已创建，11 个情景完整可见；仅 Studio 顶栏显示 QA | 保存 place 并在下次 Studio 会话复核 |
| 设备模拟 | 通过 | A06、iPhone 17 Pro、iPad Pro M5 13 横屏检查；QA 无越界，FLIP 在 iPhone 安全区回归后已修复 `TextFits=true` | 真手机/平板确认触达与安全区手感 |
| 短稳定性抽样 | 通过 | 50轮五面板显隐 + 10次五币 Flip：Lua `11175→7269 KB`，PlayerGui `10817→10802`，未挂载实例 `22→19` | 仍需完整30分钟趋势样本 |
| 30 分钟 Long Session | 自动通过 | 修复 Highlight Tween 持有链后完整重跑：818次真实服务端结算；UI、输入、错误与未挂载实例稳定，30分钟自动停止 | 保留人工相机/音效舒适度检查 |
| Long Session 采样完整度 | 自动通过 | 0分钟样本包含 Flip、Cash、座位、Lua、PlayerGui、coin visuals、通知、InputContext、runtime error；未挂载实例由 SceneAnalysis 同节点采样 | 完成5-30分钟趋势 |
| Studio Analytics 隔离 | 自动通过 | AnalyticsSystem、登录 onboarding 和 Eco economy API 在 Studio 跳过；冷启动控制台无 AnalyticsService event | 发布构建确认非 Studio 入口仍存在 |
| 购买漏斗 | 源码通过，线上未验证 | `entry / prompt_result / delivery` 分离；receipt 决策、去重和重试未改 | 正式低风险购买验证三阶段对齐 |
| Team Test 2 / 8 客户端 | 人工通过，Table Bonus专项待复核 | 用户确认2/8客户端同步、满桌、让位、离服和补位完成；此前不清楚Table Bonus规则 | 2客户端强制Perfect Five，核对另一真实玩家+$15 |
| 真手机 / 平板 / 手柄 | 人工通过 | 用户于2026-07-12确认三类真实设备验证通过；具体型号未提供 | 发布设备声明可保留，型号作为可选补充 |
| 三张真实运行素材 | 部分完成 | 已捕获真实 Perfect Five、Edge Stand、首次双币和设备截图；双客户端 Table Bonus 素材仍缺 | Team Test 捕获多人高光并整理最终文件 |
| 现有包装素材 | 自动/人工核对通过 | icon 小尺寸主体明确；三张渲染图无下注、筹码或随机赢钱文案，但红色实体按钮不代表实际 HUD | 放在真实 HUD 素材之后 |
| Rebirth攒钱引导 | 运行通过 | 卡内重复 `FLIP` 已隐藏，真实主 `FLIP` 保持高亮；提示 `TextFits=true`，Space实测Cash `$9→$22` | 真机已整体通过，无后续动作 |

## Long Session Samples

| 时间 | Flips | Cash | Lua KB | PlayerGui | Coin visuals | Notifications | InputContext | Runtime errors | Unparented |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 0m | 0 | 500 | 4508 | 5352 | 3 | 0 | 1 | 0 | 39 |
| 5m | 136 | 4256 | 2910 | 5352 | 7 | 0 | 1 | 0 | 69 |
| 10m | 273 | 7947 | 3961 | 5352 | 7 | 1 | 1 | 0 | 143 |
| 15m | 409 | 11675 | 2930 | 5352 | 7 | 0 | 1 | 0 | 192 |

15分钟门禁触发：未挂载实例连续三个节点增长，SceneAnalysis 将 `175/192` 归因于 `EffectSystem` 持有的已销毁 Highlight。已仅在 `playHighlightFlash` 完成路径增加 Tween 销毁，后续节点用于验证增长是否停止。

修复后新会话早期检查：0分钟 `42 total / 24 EffectSystem`，约2分钟 `18 total / 0 EffectSystem`，同时生产 Flip 仍持续运行。完整0-30分钟回归继续执行。

### Highlight 修复后完整回归

| 时间 | Flips | Cash | Lua KB | PlayerGui | Coin visuals | Notifications | InputContext | Runtime errors | Unparented / Effect |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 0m | 0 | 500 | 6357 | 5352 | 6 | 0 | 1 | 0 | 42 / 24 |
| 5m | 136 | 4690 | 1875 | 5352 | 10 | 0 | 1 | 0 | 18 / 0 |
| 10m | 273 | 8712 | 1874 | 5352 | 10 | 0 | 1 | 0 | 22 / 4 |
| 15m | 409 | 12232 | 1878 | 5352 | 8 | 0 | 1 | 0 | 19 / 1 |
| 20m | 545 | 16089 | 1871 | 5352 | 8 | 0 | 1 | 0 | 18 / 0 |
| 25m | 682 | 19912 | 4226 | 5352 | 8 | 0 | 1 | 0 | 18 / 0 |
| 30m | 818 | 23540 | 3185 | 5352 | 8 | 0 | 1 | 0 | 18 / 0 |

修复后完整30分钟通过：Lua内存在25分钟单点波动后回落，PlayerGui / InputContext / runtime error 全程不增长；EffectSystem 未挂载实例保持0-4低位瞬态，30分钟为0。30分钟样本后额外等待4秒 Flip仍为818，两个测试 schedule 已自动停止。

## P0 判定

只有存档或购买事故、核心 Flip 链路失败、设备不可操作、严重多人同步错误列为 P0。当前没有新增已证实 P0；未执行的 Studio、真机和 Team Test 不能视为通过。
