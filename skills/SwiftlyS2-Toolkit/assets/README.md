# SwiftlyS2 Toolkit Assets 导航

本目录把工作区沉淀的 SwiftlyS2 经验资产，按 **SwiftlyS2 官网 Development / Guides** 的语义重新整理。

目标不是复制官网正文，而是让 agent 在遇到实际任务时：

1. 先找到正确的官方主题
2. 再落到最贴近该主题的本地模板 / checklist
3. 最后再结合 `references/swiftlys2-official-docs-map.md` 联网深挖

## 目录分层

### `development/`

与官网 `https://swiftlys2.net/docs/development/` 对齐的本地资产。

### `guides/`

与官网 `https://swiftlys2.net/docs/guides/` 对齐的本地资产。

### `patterns/`

来自维护经验、但不适合硬塞进某一张官方页面的工程模式。

### `workflows/`

计划、审计、实施等工作流模板，不映射到官网单页。

## 官方主题 -> 本地资产映射

| 官方主题 | 本地资产 | 用途 |
| --- | --- | --- |
| Getting Started | `development/getting-started/partial-plugin-template.cs.md` | partial / 模块化插件骨架 |
| Using attributes | `development/using-attributes/attribute-registration-checklist.md` | attribute 注册边界与自检 |
| Swiftly Core | `development/swiftly-core/core-service-entrypoints.md` | `ISwiftlyCore` 常用服务分流 |
| Commands | `development/commands/command-attribute-template.cs.md` | attribute 命令模板 |
| Commands | `development/commands/command-service-template.cs.md` | service 自持命令模板 |
| Commands | `development/commands/client-command-hook-template.cs.md` | ClientCommandHookHandler 拦截模板 |
| Menus | `development/menus/menu-template.cs.md` | 菜单、BindingText、异步回调 |
| Network Messages | `development/netmessages/protobuf-handler-template.cs.md` | typed protobuf / netmessage 模板 |
| Native Functions and Hooks | `development/native-functions-and-hooks/hook-handler-template.cs.md` | 高频 hook / native hook 模板 |
| Configuration | `development/configuration/config-hot-reload-template.cs.md` | Config + IOptionsMonitor 热重载 |
| Configuration | `development/configuration/README.md` | 配置入口建议 |
| ConVars | `development/convars/convar-template.cs.md` | ConVar 创建、范围、标志 |
| Thread Safety | `development/thread-safety/thread-sensitivity-checklist.md` | 线程敏感 API 审查 |
| Profiler | `development/profiler/hotpath-gc-checklist.md` | 热路径 / GC / 性能审查 |
| Entity | `development/entity/schema-write-checklist.md` | schema 写回与实体有效性审查 |
| Core Events | `development/core-events/lifecycle-checklist.md` | 生命周期闭环审查 |
| Core Events | `development/core-events/precache-resource-template.cs.md` | OnPrecacheResource 模板 |
| Scheduler | `development/scheduler/scheduler-vs-worker-guide.md` | Scheduler vs 后台 worker 分流 |
| Shared API | `development/shared-api/shared-interface-template.cs.md` | provider / consumer / contracts 模板 |
| Game Events | `development/game-events/game-events-usage-notes.md` | Game Event 使用边界说明 |
| Translations | `development/translations/README.md` | 翻译资源入口建议 |
| Permissions | `development/permissions/README.md` | 权限与权限组入口建议 |
| Dependency Injection | `guides/dependency-injection/di-service-plugin-template.cs.md` | DI 插件骨架 |
| Dependency Injection | `guides/dependency-injection/service-template.cs.md` | service 骨架 |
| Terminologies | `guides/terminologies/README.md` | controller / pawn / player / handle 术语分流 |
| HTML Styling | `guides/html-styling/README.md` | Panorama HTML 样式入口 |

## 非官方但高频使用的工程模式

- `patterns/background-workers/worker-template.cs.md`
  - 后台队列、`Task.Run`、`CancellationTokenSource`、Flush / Cancel / Stop 语义
  - **注意**：它不等于官方 `Scheduler`，请先看 `development/scheduler/scheduler-vs-worker-guide.md`
- `patterns/per-player-state/player-state-management-guide.md`
  - 四档玩家状态管理模式：轻量字典 → 运行时对象 → DB 还原 → 槽位数组 + generation counter
- `patterns/async-patterns/async-safety-guide.md`
  - `.Forget()` 安全启动、StopOnMapChange、generation counter 失效策略、IPlayer 重获取
- `patterns/service-factory/service-factory-template.cs.md`
  - 工厂模式、Keyed Singleton、多实现遍历、策略选择

## 工作流模板

- `workflows/planning/method-level-plan-template.md`
- `workflows/audit/audit-report-template.md`

## 迁移说明（旧路径 -> 新路径）

- `swiftlys2-partial-plugin-template.cs.md` -> `development/getting-started/partial-plugin-template.cs.md`
- `swiftlys2-di-service-plugin-template.cs.md` -> `guides/dependency-injection/di-service-plugin-template.cs.md`
- `swiftlys2-service-template.cs.md` -> `guides/dependency-injection/service-template.cs.md`
- `swiftlys2-command-handler-template.cs.md` ->
  - `development/commands/command-attribute-template.cs.md`
  - `development/commands/command-service-template.cs.md`
- `swiftlys2-menu-template.cs.md` -> `development/menus/menu-template.cs.md`
- `swiftlys2-hook-handler-template.cs.md` -> `development/native-functions-and-hooks/hook-handler-template.cs.md`
- `swiftlys2-protobuf-handler-template.cs.md` -> `development/netmessages/protobuf-handler-template.cs.md`
- `swiftlys2-schema-write-checklist.md` -> `development/entity/schema-write-checklist.md`
- `swiftlys2-thread-sensitivity-checklist.md` -> `development/thread-safety/thread-sensitivity-checklist.md`
- `swiftlys2-hotpath-gc-checklist.md` -> `development/profiler/hotpath-gc-checklist.md`
- `swiftlys2-lifecycle-checklist.md` -> `development/core-events/lifecycle-checklist.md`
- `swiftlys2-worker-template.cs.md` -> `patterns/background-workers/worker-template.cs.md`
- `swiftlys2-method-level-plan-template.md` -> `workflows/planning/method-level-plan-template.md`
- `swiftlys2-audit-report-template.md` -> `workflows/audit/audit-report-template.md`

## 使用建议

- 想找官网脉络：先看 `../references/swiftlys2-official-docs-map.md`
- 想按任务找入口：先看 `../references/swiftlys2-kb-index.md`
- 想直接找模板 / checklist：从本 README 的映射表进入
