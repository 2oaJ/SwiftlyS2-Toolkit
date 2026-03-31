# SwiftlyS2 Plugin Agent Development Playbook

本手册是 `swiftlys2-toolkit` 的核心工程参考，专门收束**可公开复用**的 SwiftlyS2 开发方法论。

公共论据默认来自：

- SwiftlyS2 官网文档：`https://swiftlys2.net/docs/`
- 本工具包的官网精简导航：`./swiftlys2-official-docs-map.md`
- sw2-mdwiki：`https://github.com/himenekocn/sw2-mdwiki`
- SwiftlyS2 官方仓库：`https://github.com/swiftly-solution/swiftlys2`

若某个工作区还拥有本地参考仓库、当前项目映射、历史参考项目或专项经验，请把它们登记在 `../../copilot-instructions.md` 与 `../../knowledge-base.md`，不要把它们写成这里的永久硬依赖。

## 一、三类常见架构

### A. 模块化 gameplay 插件

适用于：

- 单插件内存在较多玩法逻辑
- 需要 `Commands / Events / Hooks / Modules / Workers / Models`
- 需要玩家运行态、状态同步、持久化协同

典型特点：

- 插件主类通常拆为 partial
- 命令、事件、Hook 入口与业务模块分层
- 高频计算与后台写回拆入 worker
- 玩家运行态有统一状态对象，不到处镜像复制

### B. DI / service 导向插件

适用于：

- 中大型插件
- 需要 interface → implementation 分层
- 需要显式 install / uninstall / initialize / cleanup 生命周期

典型特点：

- 使用 `ServiceCollection` 与 `AddSwiftly(Core)`
- root 负责装配
- service 自持监听、命令注册、条件性 hook、卸载闭环

### C. 混合架构

适用于：

- 主体更像 gameplay 模块化插件
- 但局部子系统更适合 service 化
- 需要在模块化主体里嵌入少量 DI / service 子能力

## 二、主线程与异步边界

根据官方 `Thread Safety` 文档，以下类型操作默认视为主线程敏感：

- `IPlayer` 的消息、控制、移动、实体相关调用
- `ICommandContext.Reply`
- `IGameEventService.Fire*`
- `IEngineService.ExecuteCommand*`
- `CEntityInstance.AcceptInput / DispatchSpawn / Despawn`
- `CBaseModelEntity.SetModel / SetBodygroupByName`
- `CCSPlayerController.Respawn`
- `CPlayer_ItemServices.*`
- `CPlayer_WeaponServices.*`

### 工程规则

1. **写游戏状态、写实体、写 Schema、写 protobuf：默认回主线程。**
2. **后台线程主要做计算、编码、磁盘 IO、网络 IO、批处理。**
3. **处于异步上下文时优先调用 `Async` API。**
4. **不要把 `.Wait()`、`.Result`、同步 join、阻塞 IO 带进主线程。**
5. **JSON 编解码默认放后台，不放 Hook / RuntimeLoop / 菜单回调。**

## 三、生命周期闭环

任何 SwiftlyS2 插件改动，至少应显式检查：

- map load / unload
- player connect / disconnect
- 长生命周期子系统 start / stop
- worker start / stop / flush / cancel

### 额外规则

- 延迟或异步逻辑不要默认信任旧 `IPlayer`
- map 级缓存要在地图生命周期显式清理
- 跨对象 / 跨会话的双向映射要在停止时原子解绑

## 四、IPlayer 与 bot/fakeclient 身份

- 真人玩家的长期身份通常用稳定玩家标识
- bot / fakeclient 不应想当然依赖 `SteamID`
- bot 的 `SteamID` 在实践上应视为固定为 `0`，不能作为可靠检索键
- bot 与真人混合存储时，优先使用 `SessionId` 作为运行态检索键
- 混合存储时应显式区分真人与 bot 的身份键策略，避免把真人长期身份键策略直接套到 bot 上
- 任何延迟任务执行时都必须重新校验玩家对象是否仍然有效

## 五、长期实体跟踪

- 跨帧、跨延迟、跨地图时，不要长期持有裸实体 wrapper
- 优先使用稳定 handle 思维
- 访问前先做有效性检查
- 需要延迟销毁、预览实体、beam/world text 之类的场景尤其要小心实体槽位复用问题

### `DispatchSpawn` / `SetModel` 与 staging list (EF_IN_STAGING_LIST)

引擎断言 `CModelState::SetupModel()` 要求：调用 `SetModel()` 时，该实体的 **OwnerEntity 不能处于 staging list 中**（`EF_IN_STAGING_LIST` 标记）。违反此断言会触发 tier0 写 `0xDEADBEEF` 到空指针，直接崩溃。

**安全的实体创建顺序**：

```csharp
// ✅ 先 Spawn 再 SetModel — DispatchSpawn 完成后实体离开 staging list
var entity = Core.EntitySystem.CreateEntityByDesignerName<CBaseModelEntity>("prop_dynamic");
entity.DispatchSpawn();
entity.SetModel("path/to/model.vmdl");

// ❌ 先 SetModel 再 Spawn — 实体仍在 staging list，断言失败 → 崩溃
var entity = Core.EntitySystem.CreateEntityByDesignerName<CBaseModelEntity>("prop_dynamic");
entity.SetModel("path/to/model.vmdl"); // CRASH: EF_IN_STAGING_LIST
entity.DispatchSpawn();
```

**对已存在实体调用 `SetModel` 的陷阱**：

若目标实体的 OwnerEntity（如武器的 owner = pawn）恰好在当前帧被标记了 `EF_IN_STAGING_LIST`（常见于 `*Updated()` 触发后），对该实体调用 `SetModel` 同样会触发断言。此时需要将 `SetModel` 延迟到 `NextWorldUpdate`，等引擎 flush staging list 后再执行：

```csharp
// ✅ 延迟到下一帧执行 SetModel，避免 staging list 断言
Core.Scheduler.NextWorldUpdate(() =>
{
    if (weapon.IsValid)
        weapon.SetModel(string.Empty);
});
```

### 断线/换图时跳过 pawn schema 写入

玩家断线或换图后，pawn 即将被引擎销毁。此时对 pawn 的 schema 写入（Render、Collision、ViewEntity、ActiveWeapon 等）+ `*Updated()` 会标记 pawn 为 dirty，引擎在下一个 tick 处理 dirty flag 时 pawn 内存已释放 → 空指针崩溃。

清理路径应区分「破坏性清理」（Disconnect / MapUnload）与「正常清理」（死亡/退出/超时），前者跳过 pawn 写入。

### 实体父子关系清理

若实体之间存在 `SetParent` / `FollowEntity` 关系，Despawn 前应先调用 `AcceptInput("ClearParent")` 解除引擎侧 parent chain，防止 Despawn 后引擎遍历悬空父指针。

## 六、Hook 热路径

高频 Hook 的公共准则：

1. 尽早过滤无关对象
2. 避免不必要分配
3. 避免 JSON、IO、锁、同步等待
4. 避免高频日志
5. 尽量做 producer / consumer 分离
6. 牢记 64 tick 帧预算

### `Span<T>` / `stackalloc` / `ref`

只在满足以下条件时考虑：

- 当前确实位于同步热路径
- 数据量小且生命周期短
- 不跨 `await`
- 不跨线程
- 不会闭包捕获或逃逸

若收益没有证据，不要为了“高级一点”而滥用。### `ref` / `in` 参数传递：仅对 struct 使用

`ref` 和 `in` 关键字仅在传递 **struct（值类型）** 时有意义——避免结构体的栈拷贝开销。

**class（引用类型）本身就是引用传递**，传参时只复制一个指针大小的引用，不会复制整个对象。对 class 加 `ref` / `in` 没有性能收益，还会增加代码噪音和误导性。

```csharp
// ✅ struct 用 in — 避免大结构体拷贝
void Process(in Vector position) { ... }
void Modify(ref QAngle angle) { ... }

// ❌ class 用 ref / in — 毫无意义，class 已经是引用类型
void Handle(in IPlayer player) { ... }  // 不需要 in
void Update(ref Config config) { ... }  // 不需要 ref

// ✅ class 直接传递
void Handle(IPlayer player) { ... }
void Update(Config config) { ... }
```

例外：`ref` 用于 class 参数的唯一合法场景是需要**重新指向另一个实例**（即修改调用方的引用本身），这在 SwiftlyS2 插件中极其罕见。

## 七、Schema / NetMessages / Protobuf

### Schema

- 写入应在主线程
- 需要时补 `Updated()` / `SetStateChanged()` 一类通知
- 若异步链路要用到数据，主线程先采安全快照

### NetMessages / Protobuf

根据官方 `Network Messages` 文档：

- 网络消息基于 typed protobuf
- 发送、hook、unhook 都有显式 API
- 适合在主线程尽早读取并转成普通模型后，再交给异步链路处理

### Native Functions and Hooks

根据官方 `Native Functions and Hooks` 文档：

- 签名与地址解析要清楚来源
- delegate 原型必须严格匹配
- hook 必须能成对卸载
- mid-hook 功能强但风险高，错误改寄存器会直接崩服

## 八、Menu 回调

菜单回调默认按异步上下文审查：

- `Click`
- `ValueChanged`
- `Submenu` 构建回调

推荐规则：

- 动态文本优先评估 `BindingText`
- 回调里优先使用 `Async` API
- 跨等待点后重新校验 player / pawn / runtime 对象
- 菜单是 UI 壳，状态读写尽量下沉到 module / service

## 九、Worker / Scheduler

### 更适合 Scheduler 的场景

- 轻量、低频、主线程安全的周期任务

### 更适合后台 worker 或可取消异步循环的场景

- 磁盘 / 网络 IO
- JSON 编解码
- 批处理
- 密集轮询
- 不应阻塞主线程的持续性工作

### 必查点

- Start / Stop / Flush / Cancel 是否成对
- 是否存在悬空 fire-and-forget
- 回写前是否重新校验对象与代际

## 十、DI 建议

根据官方 `Dependency Injection` 文档：

- 新插件优先考虑 DI
- `ServiceCollection` + `AddSwiftly(Core)` 是基础入口
- service 构造函数注入 `ISwiftlyCore`、日志、配置等依赖
- 若 service 使用 attribute 注册机制，需要显式注册

工程上再补三条：

1. root 负责装配，不负责代管所有局部监听状态
2. service 自己注册的命令、事件、hook，应由自己卸载
3. 条件性 hook 应显式维护启停状态，而不是永久挂着再在回调里空转

## 十一、Configuration 热加载

### 标准初始化流程

```csharp
Core.Configuration.InitializeJsonWithModel<Config>("config.jsonc", "Main")
    .Configure(builder => builder.AddJsonFile("config.jsonc", optional: false, reloadOnChange: true));

var monitor = ServiceProvider.GetRequiredService<IOptionsMonitor<Config>>();
Config = monitor.CurrentValue;
monitor.OnChange(newConfig => { Config = newConfig; /* 可选副作用 */ });
```

### 工程规则

1. **Config 类字段必须给默认值**，确保首次序列化生成完整配置文件。
2. **使用 JSONC 格式**（`config.jsonc`），支持注释便于维护。
3. **热加载回调中处理副作用**：Scheduler 重启、缓存清理、服务重连等。
4. **不要在热加载回调中做阻塞 IO**。

详见模板：`../assets/development/configuration/config-hot-reload-template.cs.md`。

## 十二、ConVar

根据官方 `Convars` 文档：

- ConVar 用于运行时可即时调整的服务器参数。
- 使用 `Core.ConVar.CreateOrFind()` 创建，幂等可重入。
- 支持 bool / int / float / string 类型，int/float 支持 min/max 范围约束。

### ConVar vs Config 分流

- **ConVar**：管理员在控制台即时调参、运行时开关、临时微调。
- **Config**：结构化配置、嵌套对象、数组、持久化默认值。
- **混用**：ConVar 做开关/微调，Config 做结构化默认值。

### 声明式组织

推荐在 partial 文件 `MyPlugin.ConVars.cs` 中集中声明，使用 `required` 修饰符强制初始化：

```csharp
public required IConVar<bool> ConVar_Enable { get; set; }
public required IConVar<int> ConVar_Limit { get; set; }
```

### 范围惯例

- `-1` = 不限制
- `0` = 禁用
- `>0` = 具体数值

详见模板：`../assets/development/convars/convar-template.cs.md`。

## 十三、Per-Player 状态管理

### 模式梯度

1. **轻量键值**：`ConcurrentDictionary<ulong, T>`（单值状态、小型插件）
2. **运行时状态对象**：`ConcurrentDictionary<ulong, PlayerRuntime>`（多字段、中型插件）
3. **带 DB 恢复**：connect 时异步从 DB 恢复，disconnect 时持久化
4. **槽位数组 + 代际计数**：`PlayerState?[64]` + generation counter（大型 gameplay、高频 Hook O(1) 查找）

### 身份键策略

- 真人长期存储 → `SteamID (ulong)`
- bot / fakeclient → `SessionId`（bot SteamID 固定为 0）
- 高频 Hook 内查找 → 槽位数组 O(1)

### 清理时机

必须在 `OnClientDisconnected` 移除、`OnMapLoad/Unload` 清理 map 缓存、`Unload()` 清空全部。

### 并发安全

- 优先 `TryAdd` / `TryRemove` / `GetOrAdd` / `AddOrUpdate`
- 避免 `ContainsKey + Add`、`ContainsKey + Remove` 双步写法
- `AddOrUpdate` 的 merge predicate 防止状态降级

详见指南：`../assets/patterns/per-player-state/player-state-management-guide.md`。

## 十四、异步安全模式

### `.Forget()` 模式

从同步入口（命令、事件回调）发起异步任务时，使用 `.Forget(Logger, "Context")` 而非 `_ = Task`：

```csharp
OnMyCommandAsync(context).Forget(Logger, "MyPlugin.OnMyCommand");
```

### StopOnMapChange

`Core.Scheduler.StopOnMapChange(cts)` 将 `CancellationTokenSource` 绑定到 map 生命周期，map 切换时自动 cancel。

### 异步后重取 IPlayer

任何 `await` 之后，`IPlayer` 必须通过 `SteamID` 重新获取并校验 `Valid()`。

### Generation Counter

异步回写前用代际计数（`Interlocked.Increment` + `Volatile.Read`）校验状态是否仍然有效。

详见指南：`../assets/patterns/async-patterns/async-safety-guide.md`。

## 十五、Service Factory / Keyed Service / Multi-Implementation

### 工厂模式

一个功能接口有多个策略实现，运行时按名称/配置选择。

### Keyed Singleton

同一接口的多个独立配置实例，通过 `AddKeyedSingleton` + `GetRequiredKeyedService` 管理。

### `GetServices<T>()` 多实现解析

所有实现都需遍历调用时（如多种触发器类型），用 `sp.GetServices<T>()` 获取全部。

### 批量生命周期管理

所有服务统一 `Install() / Uninstall()`，异常隔离（一个失败不影响其他）。

详见模板：`../assets/patterns/service-factory/service-factory-template.cs.md`。

## 十六、GameEvent Pre vs Post

### Pre Hook (HookMode.Pre)

- 在事件生效前触发
- 可返回 `HookResult.Stop` 拦截事件
- 适合：阻止事件传播、修改最终行为、条件性取消

### Post Hook (HookMode.Post)

- 在事件生效后触发
- 适合：基于事件结果做后续处理（记录、奖励、状态更新）
- 常见模式：Post Hook + `DelayBySeconds` 等待状态稳定后操作

### 工程规则

- 不确定用 Pre 还是 Post 时，优先 Post（更安全）
- Pre Hook 中拦截要确认确实需要阻止
- Post Hook 中涉及实体操作时，常需 NextTick / DelayBySeconds 等待状态稳定

## 十七、ClientCommandHookHandler

### 适用场景

- 全局拦截客户端命令（jointeam、radio、buy 等）
- 在命令处理流水线最早期做权限检查或行为替换

### 关键点

- 配合 `[Command("xxx", registerRaw: true)]` 确保底层识别
- `HookResult.Stop` 阻止命令、`HookResult.Continue` 放行
- 需自行解析 `commandLine` 原始字符串

详见模板：`../assets/development/commands/client-command-hook-template.cs.md`。

## 十八、OnPrecacheResource

- 在 map load 早期触发，用于预加载模型、声音、粒子资源。
- 未 precache 的资源在 `SetModel`、`EmitSound` 等调用时会静默失败。
- 支持静态资源与配置驱动的动态资源。
- 多服务场景可委托各服务各自注册资源。

详见模板：`../assets/development/core-events/precache-resource-template.cs.md`。

## 十九、跨插件命令跳转

中大型插件枢纽通过 `player.ExecuteCommand("sw_目标插件命令")` 跳转到其他插件菜单：

- 松耦合：不直接依赖其他插件代码
- 可通过 `CloseAfterClick = true` 关闭当前菜单后跳转
- 需确保目标命令已注册且对当前玩家可用

## 二十、注释与输出

- 注释应解释意图、线程边界、生命周期原因、引擎限制
- 避免噪音注释
- 计划、审计、实施记录应尽量方法级落地

## 二十一、公开参考入口

- Docs Map：`./swiftlys2-official-docs-map.md`
- Getting Started：`https://swiftlys2.net/docs/development/getting-started/`
- Swiftly Core：`https://swiftlys2.net/docs/development/swiftly-core/`
- Dependency Injection：`https://swiftlys2.net/docs/guides/dependency-injection/`
- Thread Safety：`https://swiftlys2.net/docs/development/thread-safety/`
- Native Functions and Hooks：`https://swiftlys2.net/docs/development/native-functions-and-hooks/`
- Network Messages：`https://swiftlys2.net/docs/development/netmessages/`
- sw2-mdwiki：`https://github.com/himenekocn/sw2-mdwiki`
- SwiftlyS2 官方仓库：`https://github.com/swiftly-solution/swiftlys2`
