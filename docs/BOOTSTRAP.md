# BOOTSTRAP

目的：让新对话启动更省 token，同时不丢安全约束。本文只做启动路由，不重复 `PROJECT_LOGIC.md` 的项目事实，也不重复 `FRAMEWORK.md` 的框架规则。

## 新对话启动

1. 读本文。
2. 只读 `docs/TASK_STATE.md` 的 `## Active` 区块。
3. 按任务类型再读其他文档：
   - 写 Luau：编辑前必须读 `docs/FRAMEWORK.md` §8。
   - 改核心框架行为：读 `docs/FRAMEWORK.md` 相关章节；大范围框架改动才读全文。
   - 改玩法流程、持久化 schema、系统注册、启动入口、项目常量或已知项目 quirk：读 `docs/PROJECT_LOGIC.md` 相关章节，并在同次改动里同步更新。
   - 查当前进度、验证、决策或交接状态：读 `docs/TASK_STATE.md` 所需部分；从 `## Active` 开始。

## 路由规则

- `FRAMEWORK.md` 是 SystemMgr 框架参考，也是编码习惯的权威来源。
- `PROJECT_LOGIC.md` 是当前 Flip A Coin 项目地图和运行事实来源。
- `TASK_STATE.md` 是实时任务看板、决策、验证记录和 backlog。
- `AGENTS.md` 是跨工具工作契约；维护文档或改代码时都要遵守。

## 快速护栏

- `SystemMgr.lua` 是活跃系统的运行时真相。
- 不要假设 `src/ReplicatedStorage/Systems` 下每个目录都已启用。
- 文档和代码冲突时信当前代码；如果任务触及该区域，顺手更新过时文档。
- 纯 Luau 代码改动不跑 `rojo build`；Rojo 映射、实例树、资源结构或配置变更才需要。
- MCP 工具能完成的操作优先走 MCP，`computer use` 只做兜底。
