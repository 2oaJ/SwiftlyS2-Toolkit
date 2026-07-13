# swiftlys2-toolkit 资产清单

本清单用于说明 `swiftlys2-toolkit` skill 中与 SwiftlyS2 工程工作流直接相关的公共资产。

## 1. 核心资产

### Skill
- `skills/swiftlys2-toolkit/SKILL.md`

### Workflow References
- `references/plan-workflow.md`
- `references/audit-workflow.md`
- `references/edit-workflow.md`

### References
- `skills/swiftlys2-toolkit/references/swiftlys2-plugin-playbook.md`
- [skills/swiftlys2-toolkit/references/swiftlys2-performance-optimization-playbook.md](./swiftlys2-performance-optimization-playbook.md)
- `skills/swiftlys2-toolkit/references/swiftlys2-kb-index.md`
- `skills/swiftlys2-toolkit/references/swiftlys2-official-docs-map.md`
- `skills/swiftlys2-toolkit/references/swiftlys2-current-capability-map.md`
- `skills/swiftlys2-toolkit/references/swiftlys2-asset-inventory.md`

### Templates / Assets
- `skills/swiftlys2-toolkit/assets/README.md`
- `skills/swiftlys2-toolkit/assets/development/getting-started/partial-plugin-template.cs.md`
- `skills/swiftlys2-toolkit/assets/development/using-attributes/attribute-registration-checklist.md`
- `skills/swiftlys2-toolkit/assets/development/swiftly-core/core-service-entrypoints.md`
- `skills/swiftlys2-toolkit/assets/development/commands/command-attribute-template.cs.md`
- `skills/swiftlys2-toolkit/assets/development/commands/command-service-template.cs.md`
- `skills/swiftlys2-toolkit/assets/development/commands/client-command-hook-template.cs.md`
- `skills/swiftlys2-toolkit/assets/development/menus/menu-template.cs.md`
- `skills/swiftlys2-toolkit/assets/development/netmessages/protobuf-handler-template.cs.md`
- `skills/swiftlys2-toolkit/assets/development/game-hooks/game-hooks-pre-post-guide.md`
- `skills/swiftlys2-toolkit/assets/development/native-functions-and-hooks/hook-handler-template.cs.md`
- `skills/swiftlys2-toolkit/assets/development/database/database-connection-template.cs.md`
- `skills/swiftlys2-toolkit/assets/development/entity/entity-key-values-guide.md`
- `skills/swiftlys2-toolkit/assets/development/sound-events/sound-event-guide.md`
- `skills/swiftlys2-toolkit/assets/development/steamworks/steamworks-server-guide.md`
- `skills/swiftlys2-toolkit/assets/development/memory/memory-service-guide.md`
- `skills/swiftlys2-toolkit/assets/development/thread-safety/thread-sensitivity-checklist.md`
- `skills/swiftlys2-toolkit/assets/development/profiler/hotpath-gc-checklist.md`
- `skills/swiftlys2-toolkit/assets/development/entity/schema-write-checklist.md`
- `skills/swiftlys2-toolkit/assets/development/core-events/lifecycle-checklist.md`
- `skills/swiftlys2-toolkit/assets/development/core-events/precache-resource-template.cs.md`
- `skills/swiftlys2-toolkit/assets/development/scheduler/scheduler-vs-worker-guide.md`
- `skills/swiftlys2-toolkit/assets/development/shared-api/shared-interface-template.cs.md`
- `skills/swiftlys2-toolkit/assets/development/game-events/game-events-usage-notes.md`
- `skills/swiftlys2-toolkit/assets/development/configuration/README.md`
- `skills/swiftlys2-toolkit/assets/development/configuration/config-hot-reload-template.cs.md`
- `skills/swiftlys2-toolkit/assets/development/translations/README.md`
- `skills/swiftlys2-toolkit/assets/development/permissions/README.md`
- `skills/swiftlys2-toolkit/assets/development/convars/convar-template.cs.md`
- `skills/swiftlys2-toolkit/assets/guides/dependency-injection/di-service-plugin-template.cs.md`
- `skills/swiftlys2-toolkit/assets/guides/dependency-injection/service-template.cs.md`
- `skills/swiftlys2-toolkit/assets/guides/terminologies/README.md`
- `skills/swiftlys2-toolkit/assets/guides/html-styling/README.md`
- `skills/swiftlys2-toolkit/assets/guides/porting-from-css/porting-checklist.md`
- `skills/swiftlys2-toolkit/assets/resources/runtime-configuration-guide.md`
- `skills/swiftlys2-toolkit/assets/patterns/background-workers/worker-template.cs.md`
- `skills/swiftlys2-toolkit/assets/patterns/async-patterns/async-safety-guide.md`
- `skills/swiftlys2-toolkit/assets/patterns/per-player-state/player-state-management-guide.md`
- `skills/swiftlys2-toolkit/assets/patterns/service-factory/service-factory-template.cs.md`
- `skills/swiftlys2-toolkit/assets/workflows/planning/method-level-plan-template.md`
- `skills/swiftlys2-toolkit/assets/workflows/audit/audit-report-template.md`

### Codex Metadata
- `agents/openai.yaml`

### Optional Workspace Layer

下游工作区的最近层级 `AGENTS.md` 及其显式引用的项目本地 skills 属于可选工作区层，不计入本 skill 核心资产。

## 2. 统计口径

- Skill：1
- Workflow References：3
- Domain References：6
- Templates / Assets：41
- Codex Metadata：1
- Optional Workspace Layer：0

**合计：52 个核心资产**

## 3. 分层原则

### 公共层

以下内容适合公开随工具包发布：

- Skill
- 通用 workflow references
- 通用 references
- 通用模板与检查清单

### 工作区层

以下内容用于承接当前工作区中的定制信息：

- 最近层级的 `AGENTS.md`
- 由 `AGENTS.md` 显式引用的项目本地 skills 或参考资料

这些文件可以记录：

- 当前工作区项目映射
- 本地参考仓库路径
- 工作区定制构建命令
- 当前维护团队约束

但这些信息不应再次写回公共 skill / workflow reference / template。

## 4. 命名规范

当前通用工具包采用以下命名策略：

- skill / domain reference 统一使用 `swiftlys2-` 前缀；工作流统一使用 `<intent>-workflow.md`
- assets 改为“目录承担语义、文件名承担职责”，优先按官方 Development / Guides 分类命名
- 便于检索，也避免 assets 文件名在深层目录里重复携带冗长前缀

## 5. 维护建议

- 新增通用 SwiftlyS2 工具时，优先放入当前工具包体系，并保持 `swiftlys2-` 前缀
- 新增的是一次性任务文档时，应与公共 toolkit 分离
- 若发现本地路径、工作区专属项目名、维护者私有仓库名泄漏到公共文档，应回收到下游仓库的 `AGENTS.md` 或项目本地 skill
