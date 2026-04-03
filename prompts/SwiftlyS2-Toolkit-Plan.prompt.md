# swiftlys2-toolkit Plan Prompt

使用 `swiftlys2-toolkit` skill，为 SwiftlyS2 插件任务生成**可执行、方法级、带参考来源的实施计划**。

## 目标

当用户要创建、修改、优化、重构、迁移、审计 SwiftlyS2 插件项目时：

- 先识别任务类型与目标插件
- 再判定应参考哪类架构
- 再输出方法级计划与回归矩阵
- 若存在历史实现或旧版本，可将其作为**临时经验源**提取行为与设计经验

## 强制规则

1. 若任务要求与历史实现保持行为一致，**所有玩家可感知的能力都视为核心功能**，不得标记为可延期。
2. 必须保持当前项目现有架构边界，不能为了“快速对齐”而简单回退目录结构。
3. 任何计划都必须细化到：
   - 文件
   - 方法
   - 参考来源
   - 修改动作
   - 回归点
4. 涉及高频 Hook、Schema、Protobuf、IPlayer 生命周期时，必须显式说明线程/生命周期边界。
5. 所有代码注释必须遵循当前仓库既有规范；若无额外规范，必须保持有意义且不得添加噪音注释。
6. 必须考虑 CS2 server 64 tick 帧预算，避免计划产出会拖慢主线程的实现。
7. 若计划建议使用 `Span<T>` / `ReadOnlySpan<T>` / `stackalloc` / `ref` 做热路径优化，必须同时写清安全边界。
8. 若工作区中存在历史仓库，只能将其作为临时参考，不得把它写成未来长期依赖。
9. 若涉及 bot / 真人混合存储，必须显式设计身份键策略；默认优先使用 `SessionId` 作为运行态检索键，不得把 bot 的 `SteamID` 当作稳定键。
10. 若输入中已经提供 build / test / 场景回归等直接证据，必须显式区分 `PASS / FAIL / PARTIAL`；若没有直接证据，不得把计划中的预期写成“已验证”。
11. `PARTIAL` 只用于环境受限、依赖缺失或工具不可得等客观阻塞，不得用来掩盖未执行或主观不确定。

## 语言输入要求

- 每次输出前先识别用户**最新一条消息**的主语言，并以该语言输出整份计划、讨论结论和后续提问。
- 如果用户后续切换语言，则以最新一条用户消息为准。
- 如果输入是混合语言，以用户意图最明确的主语言为准。
- 除非用户明确要求双语输出，否则不要在同一份计划里混用中英文。

## 参考资料（生成计划前必须优先使用）

### Skill 内参考文档

- `./skills/swiftlys2-toolkit/references/swiftlys2-plugin-playbook.md`
- `./skills/swiftlys2-toolkit/references/swiftlys2-kb-index.md`
- `./skills/swiftlys2-toolkit/references/swiftlys2-asset-inventory.md`

### 公开来源

- SwiftlyS2 官网文档：`https://swiftlys2.net/docs/`
- Getting Started：`https://swiftlys2.net/docs/development/getting-started/`
- Dependency Injection：`https://swiftlys2.net/docs/guides/dependency-injection/`
- Thread Safety：`https://swiftlys2.net/docs/development/thread-safety/`
- Native Functions and Hooks：`https://swiftlys2.net/docs/development/native-functions-and-hooks/`
- Network Messages：`https://swiftlys2.net/docs/development/netmessages/`
- Swiftly Core：`https://swiftlys2.net/docs/development/swiftly-core/`
- sw2-mdwiki：`https://github.com/himenekocn/sw2-mdwiki`
- SwiftlyS2 官方仓库：`https://github.com/swiftly-solution/swiftlys2`

### 当前工作区定制参考（如存在）

若 `./copilot-instructions.md` 或 `./knowledge-base.md` 记录了当前工作区的本地映射、当前项目约束或专项规则，可按需补充读取；但在输出公共计划时，不要把这些本地路径或工作区专属项目名写成永久依赖。

## 架构判定规则

### 如果是 gameplay / 状态同步 / 玩家运行态插件

优先判定为：

- **模块化 gameplay 架构**
- 典型分层：`Commands + Events + Hooks + Modules + Workers + Services + Models`

### 如果是 infra / manager / system / 全局能力插件

优先判定为：

- **DI / service 架构**
- 典型分层：`ServiceCollection + interface / implementation + install / uninstall`

### 如果同时具备两边特征

可判定为：

- **混合架构**

## 必须提取的专项经验

若任务涉及以下内容，计划必须显式写出处理原则：

### 1. 异步与并发
- 哪些逻辑必须主线程
- 哪些逻辑可以后台执行
- 是否需要 queue / flush / cancel / generation 校验
- map unload / plugin unload 是否需要 drain
- 是否有 `lock`、阻塞等待、主线程等待风险

### 2. 高频 Hook
- 是否需要尽早过滤真人/机器人/死亡态
- 是否需要减少分配与日志
- 是否应采用 producer/consumer 分离
- 哪个阶段负责采样，哪个阶段负责计算或写回

### 3. Schema 读写
- 是否需要 `Updated()` / `SetStateChanged()` / 原生同步方法
- 是否需要先主线程采快照再异步消费

### 4. Protobuf / NetMessages
- 是否必须在主线程读写
- 是否应立即转换为普通模型后再异步处理
- 是否涉及 typed protobuf / hook / send / create / dispose

### 5. IPlayer 生命周期
- 连接/断开/换图/玩家态重建如何闭环
- 该功能的状态按什么身份键管理
- 若涉及 bot / fakeclient，是否明确使用 `SessionId` 作为运行态检索键
- 是否错误依赖 bot 的 `SteamID`
- 是否需要 detach / cleanup / generation 防串写
- 延迟代码是否会引用已销毁的 `IPlayer`

## 输出格式

### 1. 任务归类
- 任务类型：创建 / 修改 / 优化 / 重构 / 迁移 / 审计
- 目标插件
- 推荐架构参考：模块化 gameplay / DI-service / 混合

### 2. 关键约束
- 玩家可见行为要求
- 线程安全要求
- 生命周期闭环要求
- 历史实现对齐要求（如有）
- 64 tick 性能预算要求
- `Span` / `ReadOnlySpan` / `stackalloc` / `ref` 的安全使用边界（如相关）
- 注释与代码风格要求

### 3. 方法级实施计划
对每个 gap / 子任务输出：
- **Gap**
- **影响**
- **参考来源**（文档 / 仓库 / 方法）
- **目标文件**
- **目标方法**
- **具体修改步骤**
- **注意的线程/生命周期边界**
- **注意的性能优化边界**
- **回归验证点**

### 4. 验证矩阵
至少覆盖：
- build
- map load / unload
- connect / disconnect
- 关键状态切换链路（如相关）
- bot / 长生命周期运行态（如相关）
- 持久化 / 状态恢复 / 跨模块同步（如相关）

### 5. 验证话语体系
- 若已有直接验证证据，建议按“**检查项 / 实际执行 / 观察结果 / 结论**”表达。
- `PASS`：已有直接证据支持该检查项成立。
- `FAIL`：已有直接证据表明该检查项不满足。
- `PARTIAL`：仅因环境限制、依赖缺失或工具不可得而无法直接验证；必须同时说明缺口与替代证据。
- 若当前只是计划阶段且尚未执行验证，必须明确写“未直接验证/待实施验证”，不能伪装成已通过。

## 示例用法

- “为 SwiftlyS2 插件新增一个带 DI 的状态同步模块，请生成方法级计划。”
- “审计一个 SwiftlyS2 插件的 RuntimeLoop 与 Hook 热路径，给出优化计划。”
- “把历史 SwiftlyS2 插件的行为经验迁移到新架构，要求全部核心功能不可延期。”
- “为新插件在模块化 gameplay 与 DI/service 架构之间选型，并给出落地计划。”
