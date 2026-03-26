# swiftlys2-toolkit 资产清单

本清单用于说明当前 `.github/` 中与 SwiftlyS2 工程工作流直接相关的**公共资产**。

## 1. 核心资产

### Skill
- `skills/swiftlys2-toolkit/SKILL.md`

### Prompts
- `prompts/swiftlys2-toolkit-Plan.prompt.md`
- `prompts/swiftlys2-toolkit-Audit.prompt.md`
- `prompts/swiftlys2-toolkit-Edit.prompt.md`

### References
- `skills/swiftlys2-toolkit/references/swiftlys2-plugin-playbook.md`
- `skills/swiftlys2-toolkit/references/swiftlys2-kb-index.md`
- `skills/swiftlys2-toolkit/references/swiftlys2-official-docs-map.md`
- `skills/swiftlys2-toolkit/references/swiftlys2-asset-inventory.md`

### Templates / Assets
- `skills/swiftlys2-toolkit/assets/README.md`
- `skills/swiftlys2-toolkit/assets/development/getting-started/partial-plugin-template.cs.md`
- `skills/swiftlys2-toolkit/assets/development/using-attributes/attribute-registration-checklist.md`
- `skills/swiftlys2-toolkit/assets/development/swiftly-core/core-service-entrypoints.md`
- `skills/swiftlys2-toolkit/assets/development/commands/command-attribute-template.cs.md`
- `skills/swiftlys2-toolkit/assets/development/commands/command-service-template.cs.md`
- `skills/swiftlys2-toolkit/assets/development/menus/menu-template.cs.md`
- `skills/swiftlys2-toolkit/assets/development/netmessages/protobuf-handler-template.cs.md`
- `skills/swiftlys2-toolkit/assets/development/native-functions-and-hooks/hook-handler-template.cs.md`
- `skills/swiftlys2-toolkit/assets/development/thread-safety/thread-sensitivity-checklist.md`
- `skills/swiftlys2-toolkit/assets/development/profiler/hotpath-gc-checklist.md`
- `skills/swiftlys2-toolkit/assets/development/entity/schema-write-checklist.md`
- `skills/swiftlys2-toolkit/assets/development/core-events/lifecycle-checklist.md`
- `skills/swiftlys2-toolkit/assets/development/scheduler/scheduler-vs-worker-guide.md`
- `skills/swiftlys2-toolkit/assets/development/shared-api/shared-interface-template.cs.md`
- `skills/swiftlys2-toolkit/assets/development/game-events/game-events-usage-notes.md`
- `skills/swiftlys2-toolkit/assets/development/configuration/README.md`
- `skills/swiftlys2-toolkit/assets/development/translations/README.md`
- `skills/swiftlys2-toolkit/assets/development/permissions/README.md`
- `skills/swiftlys2-toolkit/assets/guides/dependency-injection/di-service-plugin-template.cs.md`
- `skills/swiftlys2-toolkit/assets/guides/dependency-injection/service-template.cs.md`
- `skills/swiftlys2-toolkit/assets/guides/terminologies/README.md`
- `skills/swiftlys2-toolkit/assets/guides/html-styling/README.md`
- `skills/swiftlys2-toolkit/assets/patterns/background-workers/worker-template.cs.md`
- `skills/swiftlys2-toolkit/assets/workflows/planning/method-level-plan-template.md`
- `skills/swiftlys2-toolkit/assets/workflows/audit/audit-report-template.md`

### Toolkit Docs
- `skills/swiftlys2-toolkit/README.md`

### Workspace Layer
- `.github/copilot-instructions.md`
- `.github/knowledge-base.md`

## 2. 统计口径

- Skill：1
- Prompts：3
- References：4
- Templates / Assets：26
- Toolkit README：1
- Workspace Layer：2

**合计：37 个核心资产**

## 3. 分层原则

### 公共层

以下内容适合公开随工具包发布：

- Skill
- 通用 prompts
- 通用 references
- 通用模板与检查清单

### 工作区层

以下内容用于承接当前工作区中的定制信息：

- `copilot-instructions.md`
- `knowledge-base.md`

这些文件可以记录：

- 当前工作区项目映射
- 本地参考仓库路径
- 工作区定制构建命令
- 当前维护团队约束

但这些信息不应再次写回公共 skill / prompt / template。

## 4. 命名规范

当前通用工具包采用以下命名策略：

- skill / prompt / reference 统一使用 `swiftlys2-` 前缀
- assets 改为“目录承担语义、文件名承担职责”，优先按官方 Development / Guides 分类命名
- 便于检索，也避免 assets 文件名在深层目录里重复携带冗长前缀

## 5. 维护建议

- 新增通用 SwiftlyS2 工具时，优先放入当前工具包体系，并保持 `swiftlys2-` 前缀
- 新增的是一次性任务文档时，应与公共 toolkit 分离
- 若发现本地路径、工作区专属项目名、个人仓库名泄漏到公共文档，应优先回收至 `copilot-instructions.md` 或 `knowledge-base.md`
