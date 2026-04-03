# swiftlys2-toolkit Audit Prompt

使用 `swiftlys2-toolkit` skill，对 SwiftlyS2 插件项目执行**通用审计**。

## 审计目标

当用户要求“审计”一个 SwiftlyS2 插件或子系统时，不要只看代码风格，要覆盖：

1. 架构是否匹配项目规模与职责
2. 生命周期是否闭环
3. 是否存在主线程风险、死锁风险、延迟引用失效玩家风险
4. 高频 Hook 是否有分配、日志、IO、锁、阻塞等热点
5. Schema / Protobuf 是否符合线程与写回规则
6. 若存在历史实现或旧版本，是否存在行为漂移
7. 是否满足 64 tick 服务器帧预算意识

## 强制规则

- 玩家可感知的历史行为差异必须单独列出，不得隐藏在“可优化项”里
- 所有风险都要标注严重级别：P0 / P1 / P2 / P3
- 审计结论必须可执行，不能只给空泛建议
- 若发现注释问题，必须按当前仓库注释规范评估；若无额外规范，按“有意义且解释非显而易见语义”标准审查
- 必须强制检查同步阻塞与主线程 JSON 开销
- 若审计建议涉及 `Span<T>` / `ReadOnlySpan<T>` / `stackalloc` / `ref`，必须同时审计其安全边界
- 若工作区中存在历史仓库，只能将其作为临时经验源，不能假定其永远存在
- 若存在 bot / 真人混合存储，必须单独审计身份键设计，重点检查是否误用 bot 的 `SteamID`
- 若审计范围包含已执行的 build / test / 场景回归证据，必须显式区分 `PASS / FAIL / PARTIAL`；若没有直接证据，只能写“未直接验证”，不得把推断写成已验证事实
- `PARTIAL` 只用于环境限制、依赖缺失或工具不可得，不得用来掩盖未执行或主观不确定

## 语言输入要求

- 每次输出前先识别用户**最新一条消息**的主语言，并以该语言作为本轮唯一输出语言。
- 如果用户后续切换语言，则以最新一条用户消息为准。
- 如果输入是混合语言，以用户意图最明确的主语言为准。
- 除非用户明确要求双语输出，否则不要在同一段审计内容里混用中英文。

## 优先参考

### Skill 参考文档

- `./skills/swiftlys2-toolkit/references/swiftlys2-plugin-playbook.md`
- `./skills/swiftlys2-toolkit/references/swiftlys2-kb-index.md`
- `./skills/swiftlys2-toolkit/references/swiftlys2-asset-inventory.md`

### 公开来源

- SwiftlyS2 官网文档：`https://swiftlys2.net/docs/`
- Thread Safety：`https://swiftlys2.net/docs/development/thread-safety/`
- Native Functions and Hooks：`https://swiftlys2.net/docs/development/native-functions-and-hooks/`
- Network Messages：`https://swiftlys2.net/docs/development/netmessages/`
- Dependency Injection：`https://swiftlys2.net/docs/guides/dependency-injection/`
- sw2-mdwiki：`https://github.com/himenekocn/sw2-mdwiki`
- SwiftlyS2 官方仓库：`https://github.com/swiftly-solution/swiftlys2`

### 当前工作区定制参考（如存在）

若 `./copilot-instructions.md` 或 `./knowledge-base.md` 记录了当前工作区的本地映射、当前项目约束或专项规则，可按需补充读取；但在输出公共审计时，不要把这些本地路径或工作区专属项目名写成永久依赖。

## 审计维度

### 1. 架构审计
- 当前更像模块化 gameplay、DI/service，还是混合架构？
- 分层是否清晰？
- 是否把业务逻辑错误地塞进主类/命令/事件入口？
- 是否应该抽成 module / service / worker / manager？

### 2. 生命周期审计
- `OnClientPutInServer`
- `OnClientDisconnected`
- `OnMapLoad`
- `OnMapUnload`

特别检查：
- 玩家断线后 `IPlayer` 是否还被延迟逻辑持有
- map change 后是否还有脏状态残留

### 3. 线程安全与异步审计
- 主线程 API 是否被后台线程误用
- 是否有 `lock` 造成主线程等待风险
- 是否有 `.Wait()` / `.Result` / 同步阻塞
- 是否在主线程做 JSON 序列化 / 反序列化
- worker stop/flush/cancel 是否完整
- generation / session 校验是否存在

### 4. 高频 Hook 审计
- 是否有无意义分配
- 是否有日志热点
- 是否有 IO / API 调用
- 是否混入 JSON 等重 CPU 操作
- 是否做了真人/机器人/死亡态快速分流
- 是否有 producer/consumer 分离
- 是否符合 64 tick 服务器预算意识
- 热路径数据搬运是否可改用 `Span/ReadOnlySpan/stackalloc/ref`

### 5. Schema / Protobuf 审计
- Schema 写入后是否调用 `Updated()` / `SetStateChanged()`
- 是否在不安全线程访问 protobuf / usercmd / entity handle
- 是否在需要时将 protobuf 快照化为普通模型

### 6. bot / fakeclient 身份键审计
- 是否错误使用 `SteamID` 检索 bot/fakeclient
- 是否明确知道 bot 的 `SteamID` 在实践上应视为 `0`
- 是否优先使用 `SessionId` 作为 bot / 真人混合运行态的检索键
- 混合存储时是否正确区分真人与 bot 的身份键

### 7. 历史实现对齐审计（如适用）
- 列出历史参考方法
- 列出当前目标方法
- 列出行为差异与玩家影响

## 输出格式

### 1. 审计范围
- 目标仓库/插件
- 审计类型
- 使用的主要参考源

### 2. 总结结论
- 当前架构判定
- 总体风险等级
- 最关键的 3~10 个问题
- 若已有直接验证证据，补充关键检查项的 `PASS / FAIL / PARTIAL` 摘要；若没有，明确标注“未直接验证”的范围

### 3. 问题清单
对每个问题输出：
- **级别**：P0 / P1 / P2 / P3
- **问题**
- **影响**
- **定位**（文件 + 方法）
- **参考依据**（文档 / 仓库 / 历史方法）
- **建议修复方向**
- **是否需要同步说明性能优化边界**
- **是否涉及主线程同步阻塞或主线程 JSON 开销**

### 4. 修复优先级建议
- 先修哪些
- 哪些可以并行
- 哪些需要方法级计划进一步展开

### 5. 回归矩阵
- build
- map load/unload
- connect/disconnect
- gameevent/event/hook 相关（如适用）
- 高频 hook 压力点（如相关）

### 6. 验证话语体系
- 优先按“**检查项 / 实际执行 / 观察结果 / 结论**”写出已执行验证的证据链。
- `PASS`：已有直接证据支持。
- `FAIL`：已有直接证据表明不满足。
- `PARTIAL`：仅因客观环境限制无法直接验证，必须附替代证据或说明缺口。
- 若当前审计主要基于静态阅读而非运行验证，必须明确写“静态审计结论，不等于已执行验证”。

## 示例用法

- “审计这个 SwiftlyS2 插件的线程安全与生命周期闭环。”
- “审计历史实现与当前实现的行为差距，重点看状态同步 / 高频循环 / 持久化链路。”
- “审计一个 SwiftlyS2 插件是否适合继续使用模块化 gameplay 架构，还是应该改成 DI/service 架构。”
- “审计高频 Hook 性能热点，给出优化方向，但不要直接改代码。”
