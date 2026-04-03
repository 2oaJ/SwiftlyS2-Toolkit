# swiftlys2-toolkit Edit Prompt

使用 `swiftlys2-toolkit` skill，直接处理 SwiftlyS2 插件中的**添加功能 / 修改功能 / 删除功能**场景。

本 prompt 适用于用户明确希望**直接落地代码改动**的请求，而不是先做完整审计或输出长篇计划。

## 适用场景

当用户提出以下类型请求时，优先使用本 prompt：

- “添加一个功能”
- “修改这个功能”
- “删除这个功能”
- “直接改代码”
- “把这个逻辑接进去”
- “修这个功能，但不要先写一大堆方案”

## 目标

在直接编辑场景下，仍然保持 SwiftlyS2 Agent 开发质量：

- 先识别功能类型与所属子系统
- 再定位入口、状态归属、线程边界、生命周期闭环
- 再做最小必要改动
- 最后执行 build / 错误检查 / 回归验证

## 编辑风险分级

### P0：先计划或先审计再改
- 跨多个子系统，且边界不清楚
- 涉及长生命周期运行态 / 持久化 / 跨模块状态同步的广泛行为漂移
- 存在明显历史对齐要求，但尚未完成方法级映射
- 继续直接改动很可能破坏当前架构边界

### P1：可直接改，但必须高强度约束
- 高频 hook
- schema/entity 写回
- protobuf / usercmd
- 线程敏感 API 密集调用
- map lifecycle / disconnect cleanup / 自动控制实体生命周期

### P2：标准直接编辑场景
- 菜单
- 命令
- service 局部逻辑
- worker 局部流程
- 单模块行为修复

### P3：低风险直接编辑场景
- 小范围条件判断修正
- 动态文案绑定
- 无行为漂移的小清理

## 强制规则

1. 不要把所有“直接编辑”请求都强行升级成完整审计或 plan。
2. 若判断任务已经达到 P0 / 大型任务级别，先用一句话说明触发原因，并询问用户是否切换到 `SwiftlyS2-Plan`；用户未明确同意前，不要静默切换模式。
3. 但在动手前，必须至少完成一次**最小必要定位**。
4. 若任务要求与历史实现保持一致，玩家可感知能力都视为核心，不可静默删减。
5. 直接编辑也必须保持当前架构边界，不能为了省事把逻辑塞回主类或跨层乱写。
6. 涉及线程敏感 API 时：
   - 异步上下文优先用 `Async` 版本
   - 不要默认用 `NextTick` / `NextWorldUpdate` 兜底
7. menu 的 `Click` / `ValueChanged` 委托按异步上下文处理。
8. 动态菜单文本优先评估 `BindingText`。
9. 若存在 bot / fakeclient / 自动控制实体 或 bot/真人混合存储，禁止直接把 bot 身份键等同于真人策略。
10. 热路径或高频数据传递中，若 SwiftlyS2/当前 API 已按 `ref` 提供参数，优先评估继续使用 `ref`；若需要小块高频数据传递，可评估 `Span<T>` / `ReadOnlySpan<T>`，但不得跨 `await` 或线程边界滥用。
11. 所有注释必须遵循当前仓库既有规范；若无额外规范，必须有意义并解释非显而易见的意图。
12. 高风险改动必须补 build 与场景回归说明。
13. 若涉及 bot / 真人混合存储，默认优先使用 `SessionId` 作为运行态检索键，不得把 bot 的 `SteamID` 当作可靠主键。
14. 验证结论应尽量按“**检查项 / 实际执行 / 观察结果 / 结论**”表达，并在有直接证据时使用 `PASS / FAIL / PARTIAL`。
15. `PARTIAL` 只用于环境限制、依赖缺失或工具不可得，不得用来掩盖未执行、主观不确定或“还没来得及验证”。

## 语言输入要求

- 每次输出前先识别用户**最新一条消息**的主语言，并以该语言作为本轮唯一输出语言。
- 如果用户后续切换语言，则以最新一条用户消息为准。
- 如果输入是混合语言，以用户意图最明确的主语言为准。
- 除非用户明确要求双语输出，否则不要在同一段改动说明或验证说明里混用中英文。

## 使用前的最小导航

根据任务内容，优先配套以下资产：

### 命令相关
- `./skills/swiftlys2-toolkit/assets/development/commands/command-attribute-template.cs.md`
- `./skills/swiftlys2-toolkit/assets/development/commands/command-service-template.cs.md`
- `./skills/swiftlys2-toolkit/assets/development/commands/client-command-hook-template.cs.md`
- `./skills/swiftlys2-toolkit/assets/development/using-attributes/attribute-registration-checklist.md`

### 菜单相关
- `./skills/swiftlys2-toolkit/assets/development/menus/menu-template.cs.md`
- `./skills/swiftlys2-toolkit/assets/development/thread-safety/thread-sensitivity-checklist.md`

### Hook / Runtime / 高频路径
- `./skills/swiftlys2-toolkit/assets/development/native-functions-and-hooks/hook-handler-template.cs.md`
- `./skills/swiftlys2-toolkit/assets/development/thread-safety/thread-sensitivity-checklist.md`
- `./skills/swiftlys2-toolkit/assets/development/profiler/hotpath-gc-checklist.md`

### Schema / Entity 写回
- `./skills/swiftlys2-toolkit/assets/development/entity/schema-write-checklist.md`
- `./skills/swiftlys2-toolkit/assets/development/thread-safety/thread-sensitivity-checklist.md`

### 配置 / ConVar
- `./skills/swiftlys2-toolkit/assets/development/configuration/config-hot-reload-template.cs.md`
- `./skills/swiftlys2-toolkit/assets/development/convars/convar-template.cs.md`

### Worker / 异步持久化 / 后台任务
- `./skills/swiftlys2-toolkit/assets/development/scheduler/scheduler-vs-worker-guide.md`
- `./skills/swiftlys2-toolkit/assets/patterns/background-workers/worker-template.cs.md`
- `./skills/swiftlys2-toolkit/assets/patterns/async-patterns/async-safety-guide.md`
- `./skills/swiftlys2-toolkit/assets/development/core-events/lifecycle-checklist.md`

### DI / Service
- `./skills/swiftlys2-toolkit/assets/guides/dependency-injection/di-service-plugin-template.cs.md`
- `./skills/swiftlys2-toolkit/assets/guides/dependency-injection/service-template.cs.md`
- `./skills/swiftlys2-toolkit/assets/patterns/service-factory/service-factory-template.cs.md`

### 资源预缓存 / 生命周期
- `./skills/swiftlys2-toolkit/assets/development/core-events/precache-resource-template.cs.md`
- `./skills/swiftlys2-toolkit/assets/development/core-events/lifecycle-checklist.md`

### 玩家运行态
- `./skills/swiftlys2-toolkit/assets/patterns/per-player-state/player-state-management-guide.md`

### 需要更高层工程规则时
- `./skills/swiftlys2-toolkit/references/swiftlys2-plugin-playbook.md`
- `./skills/swiftlys2-toolkit/references/swiftlys2-kb-index.md`
- `./skills/swiftlys2-toolkit/references/swiftlys2-asset-inventory.md`

## 直接编辑工作流

### 1. 先判断任务类型
- **添加**：新增能力、入口、配置、流程
- **修改**：调整现有逻辑、修 bug、改行为
- **删除**：移除功能、清理入口、删无效分支

### 2. 再判断风险级别
- 当前是 P0 / P1 / P2 / P3 哪一级？
- 若是 P0，先简短说明它为什么已属于大型/高不确定任务，并询问用户是否切换到 `plan` 或 `audit`；用户未同意前，不要静默切模式
- 若是 P1/P2/P3，继续执行直接编辑流程

### 3. 做最小必要定位
至少回答：
- 入口文件 / 方法在哪？
- 状态由哪个 module / service / runtime context 管？
- 是否涉及命令、菜单、事件、hook、worker、schema、protobuf？
- 是否涉及 `IPlayer` / `Pawn` / entity 生命周期？
- 是否涉及线程敏感 API？
- 是否涉及 bot / fakeclient 身份检索或混合存储键设计？
- 若涉及 bot / fakeclient，是否误把 `SteamID` 当作可靠键，是否应改用 `SessionId`？
- 是否存在可避免的高频对象拷贝，需评估 `ref` / `Span`？

### 4. 选择合适的资产
- command（attribute）→ command attribute template + attribute checklist
- command（service-owned）→ command service template
- command（client command hook）→ client-command-hook-template + hook-handler-template
- menu → menu template + thread checklist
- hook → hook template + thread checklist + hotpath checklist
- schema → schema checklist
- worker → scheduler-vs-worker guide + worker template + lifecycle checklist
- service/DI → service template / di template
- service factory / keyed DI → service-factory-template + di-service-plugin-template
- config / 配置热重载 → config-hot-reload-template
- convar → convar-template
- precache / 资源预缓存 → precache-resource-template + lifecycle-checklist
- per-player state / 玩家运行态 → player-state-management-guide
- async safety / 异步安全 → async-safety-guide + lifecycle-checklist

### 5. 实施时的要求
- 尽量做最小改动
- 不改无关格式
- 不复制粘贴跨层逻辑
- 不引入“临时 TODO 逻辑”进入主流程
- 任何跨 `await` / 延迟任务都重新检查 player/entity 是否有效
- 若只是动态文本更新，优先 `BindingText`
- 若是 async context 下的线程敏感调用，优先 `Async` API
- 若位于热路径，顺手检查是否存在可去除的拷贝、装箱、临时数组分配

### 6. 验证要求
至少执行：
- 文件问题检查
- 目标插件 build（如改动是实际代码而非纯文档）

按风险补充：
- map load / unload
- connect / disconnect
- 关键状态切换链路（如相关）
- bot / 长生命周期运行态
- 持久化 / 状态恢复 / 跨模块同步

## 输出格式

### 1. 任务判定
- 类型：添加 / 修改 / 删除
- 风险级别：P0 / P1 / P2 / P3
- 目标插件 / 子系统
- 入口定位
- 主要状态归属

### 2. 编辑策略
- 采用的 toolkit 资产
- 为什么这样落地
- 需要注意的线程 / 生命周期边界

### 3. 实际改动
按文件列出：
- **文件**
- **方法 / 区域**
- **修改内容**
- **为什么这样改**

### 4. 验证结果
- 问题检查结果
- build 结果（如适用）
- 已覆盖回归点
- 尚未执行但建议执行的高风险场景
- 若已有直接证据，建议把关键检查项标为 `PASS / FAIL / PARTIAL`
- 若某项仍未直接验证，必须明确写“未直接验证”，不要把预期或推断包装成已通过

## 何时不要继续直接编辑

遇到以下情况，应先切到 plan 或 audit 思维：

- 改动跨多个子系统且行为边界不清楚
- 存在明显历史行为对齐需求，但差距尚未厘清
- 涉及大范围长生命周期运行态 / 持久化 / 状态同步漂移
- 无法确认状态归属，继续改会破坏架构边界

此时不要静默跳到 plan 模式；先向用户解释原因并询问是否切换。

## 示例用法

- “直接给这个 SwiftlyS2 插件加一个设置菜单，并接上保存逻辑。”
- “修改这个命令的权限与提示，不要动别的行为。”
- “删除旧的奖励入口，并把清理逻辑补完整。”
- “为现有 menu 改成 BindingText 动态文本绑定。”
- “把这个线程敏感同步调用改成更合适的异步安全写法。”
