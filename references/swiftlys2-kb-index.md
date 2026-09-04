# SwiftlyS2 Knowledge Base Quick Index

本索引用于快速定位 **公开可引用** 的 SwiftlyS2 资料入口。

若当前工作区还有本地参考仓库、项目映射、历史参考项目或定制经验，请登记在最近层级的 `AGENTS.md` 或其显式引用的项目本地 skill 中，不要把它们写回这里。

## 1. SwiftlyS2 官网入口

### 总入口

- Docs Root：`https://swiftlys2.net/docs/`
- Docs Map（本工具包精简导航）：`./swiftlys2-official-docs-map.md`
- Current Capability Map（本次官方快照对照）：`./swiftlys2-current-capability-map.md`
- API Reference：`https://swiftlys2.net/docs/api/`

### Development 区主入口

- Installation：`https://swiftlys2.net/docs/installation/`
- Getting Started：`https://swiftlys2.net/docs/development/getting-started/`
- Swiftly Core：`https://swiftlys2.net/docs/development/swiftly-core/`
- Using attributes：`https://swiftlys2.net/docs/development/using-attributes/`
- Thread Safety：`https://swiftlys2.net/docs/development/thread-safety/`
- Commands：`https://swiftlys2.net/docs/development/commands/`
- Configuration：`https://swiftlys2.net/docs/development/configuration/`
- Translations：`https://swiftlys2.net/docs/development/translations/`
- Entity：`https://swiftlys2.net/docs/development/entity/`
- Entity Key Values：`https://swiftlys2.net/docs/development/entitykeyvalues/`
- Game Events：`https://swiftlys2.net/docs/development/game-events/`
- Core Events：`https://swiftlys2.net/docs/development/core-events/`
- GameHooks API：`https://swiftlys2.net/docs/api/gamehooks/`
- Network Messages：`https://swiftlys2.net/docs/development/netmessages/`
- Menus：`https://swiftlys2.net/docs/development/menus/`
- Convars：`https://swiftlys2.net/docs/development/convars/`
- Native Functions and Hooks：`https://swiftlys2.net/docs/development/native-functions-and-hooks/`
- Scheduler：`https://swiftlys2.net/docs/development/scheduler/`
- Shared API：`https://swiftlys2.net/docs/development/shared-api/`
- Permissions：`https://swiftlys2.net/docs/development/permissions/`
- Profiler：`https://swiftlys2.net/docs/development/profiler/`
- Database：`https://swiftlys2.net/docs/development/database/`
- Sound Events：`https://swiftlys2.net/docs/development/soundevents/`
- Steamworks：`https://swiftlys2.net/docs/development/steamworks/`
- Custom HUD：`https://swiftlys2.net/docs/development/custom-hud/`

### Resources 区主入口

- CLI Options：`https://swiftlys2.net/docs/resources/cli-options/`
- Core Configuration：`https://swiftlys2.net/docs/resources/core-configuration/`
- Command Overrides：`https://swiftlys2.net/docs/resources/command-overrides/`
- Console Filter：`https://swiftlys2.net/docs/resources/console-filter/`

### Guides 区主入口

- Dependency Injection：`https://swiftlys2.net/docs/guides/dependency-injection/`
- Development Flow（当前官网仍为占位 todo）：`https://swiftlys2.net/docs/guides/development-flow/`
- Chat & CenterHTML Styling：`https://swiftlys2.net/docs/guides/chat-and-html-styling/`
- Porting from CounterStrikeSharp：`https://swiftlys2.net/docs/guides/porting-from-css/`
- Terminologies：`https://swiftlys2.net/docs/guides/terminologies/`

### API Reference 使用建议

- 本工具包不内置完整 API Reference 全量提取，避免体积膨胀。
- 先看：`./swiftlys2-official-docs-map.md` 中的 API Reference 瘦导航。
- 再按栏目联网深挖：如 `commands`、`netmessages`、`players`、`schemas`、`services`。
- 若现有导航仍不足，再把 `https://swiftlys2.net/llms-full.txt` 视为最后兜底全文源；读取前必须先询问用户，且只做局部关键词/分段检索。

### LLM 全量文档

- 地址：`https://swiftlys2.net/llms-full.txt`
- 内容：SwiftlyS2 官网全部文档（介绍、安装、API Reference、Development 指南、Guides、Porting 指南等）的单文件 LLM 优化版本。
- 用途：**最后兜底**的 API 查找、全文搜索、接口签名确认与官方示例查阅。
- 使用约束：读取前必须先询问用户；获得同意后只做局部关键词或分段检索，禁止整文件扫描。

## 2. 本工具包 assets 导航

- Assets Root：`../assets/README.md`
- Current Capability Map：`./swiftlys2-current-capability-map.md`
- Performance Playbook：`./swiftlys2-performance-optimization-playbook.md`
- Development 主题资产：`../assets/development/`
- Guides 主题资产：`../assets/guides/`
- 非官方工程模式：`../assets/patterns/`
- 工作流模板：`../assets/workflows/`

## 3. sw2-mdwiki 快速入口

仓库：`https://github.com/himenekocn/sw2-mdwiki`

### 常查分类

- `SwiftlyS2/Shared/Players/IPlayer.md`
- `SwiftlyS2/Shared/Players/IPlayerManagerService.md`
- `SwiftlyS2/Shared/IInterfaceManager.md`
- `SwiftlyS2/Shared/ISwiftlyCore.md`
- `SwiftlyS2/Shared/Commands/ICommandContext.md`
- `SwiftlyS2/Shared/Commands/Command.md`
- `SwiftlyS2/Shared/Commands/CommandAlias.md`
- `SwiftlyS2/Shared/Events/`
- `SwiftlyS2/Shared/NetMessages/INetMessageService.md`
- `SwiftlyS2/Shared/ProtobufDefinitions/README.md`
- `SwiftlyS2/Shared/SchemaDefinitions/README.md`
- `SwiftlyS2/Shared/EntitySystem/IEntitySystemService.md`
- `SwiftlyS2/Shared/Menus/`
- `SwiftlyS2/Core/Menus/OptionsBase/`

## 4. SwiftlyS2 官方仓库入口

仓库：`https://github.com/swiftly-solution/swiftlys2`

### 结构速览

- `src/`：C++ core framework
- `managed/src/`：C# managed layer
- `natives/`：native definitions
- `generator/`：code generation tools
- `plugin_files/`：plugin/package assets

## 5. 先决策，再查文档

- **我要注册命令 / alias / chat hook** → `Commands`
- **我要监听地图 / 玩家 / 实体生命周期** → `Core Events`
- **我要写 typed entity/controller/movement/pawn/weapon Hook** → `GameHooks` API + `assets/development/game-hooks/`
- **我要写 raw native function / mid-hook** → `Native Functions and Hooks` + `Memory`
- **我要发送 typed protobuf / netmessage** → `Network Messages`
- **我要做跨插件接口** → `Shared API`
- **我在纠结 await / NextTick / 线程敏感 API** → `Thread Safety`
- **我在纠结 controller / pawn / player / entity handle** → `Terminologies` + `Entity`

## 6. 场景化索引（细化版）

### 我要写命令

#### 1）我要写 partial / attribute 命令

- 先看官方：
	1. `Commands`
	2. `Using attributes`
	3. `Thread Safety`
- 再看本地资产：
	- `../assets/development/commands/command-attribute-template.cs.md`
	- `../assets/development/using-attributes/attribute-registration-checklist.md`
- 常用 API / 关键词：
	- `ICommandContext`
	- `[Command]`
	- `[CommandAlias]`
	- `Reply` / `ReplyAsync`
- 常见坑：
	- 非主类对象用了 attribute 却没 `Core.Registrator.Register(this)`
	- 命令入口直接堆业务逻辑
	- 异步上下文里误用同步线程敏感 API

#### 2）我要写 service 自持命令

- 先看官方：
	1. `Commands`
	2. `Dependency Injection`
	3. `Thread Safety`
- 再看本地资产：
	- `../assets/development/commands/command-service-template.cs.md`
	- `../assets/guides/dependency-injection/service-template.cs.md`
- 常用 API / 关键词：
	- `RegisterCommand`
	- `RegisterCommandAlias`
	- `UnregisterCommand`
	- `HookClientChat`
	- `HookClientCommand`
- 常见坑：
	- 没保存 `Guid`
	- 命令由 root 注册，却在 service 里想当然清理
	- alias 清理与主命令清理路径不一致

#### 3）我要给命令加权限

- 先看官方：
	1. `Commands`
	2. `Permissions`
- 再看本地资产：
	- `../assets/development/permissions/README.md`
	- `../assets/development/commands/command-attribute-template.cs.md`
- 常见坑：
	- 只做 UI 限制，没做真实权限检查
	- wildcard / sub-permission 关系没有梳理清楚

### 我要写菜单

#### 1）我要做菜单入口 / 子菜单 / 保存流程

- 先看官方：
	1. `Menus`
	2. `Thread Safety`
- 再看本地资产：
	- `../assets/development/menus/menu-template.cs.md`
	- `../assets/development/thread-safety/thread-sensitivity-checklist.md`
- 常用 API / 关键词：
	- `IMenuManagerAPI`
	- `ButtonMenuOption`
	- `ToggleMenuOption`
	- `ChoiceMenuOption`
	- `SubmenuMenuOption`
- 常见坑：
	- 回调里直接阻塞 IO
	- 跨 `await` 后不重校验 player
	- 状态保存在菜单里而非 runtime / service 中

#### 2）我要做 BindingText 动态文本

- 先看官方：
	1. `Menus`
	2. `HTML Styling`（若文本涉及 HTML）
- 再看本地资产：
	- `../assets/development/menus/menu-template.cs.md`
	- `../assets/guides/html-styling/README.md`
- 常见坑：
	- 用手工刷新 `Text` 代替绑定
	- 在绑定求值里塞重计算 / 重 IO

### 我要做 Custom HUD

#### 1）我要给玩家显示自定义 HUD 并由服务端更新状态

- 先看官方：
	1. `Custom HUD`
	2. `Thread Safety`
	3. `Entity`
- 再看本地参考：
	- `./swiftlys2-custom-hud.md`
- 常用 API / 关键词：
	- `CCSCustomHudLayout`
	- `SetDialogVariableString(ForPlayer)` / `RemoveDialogVariableStringForPlayer`
	- `SetHasClass(ForPlayer)` / `EHudPanelClassStatus_t`
	- `StrLayout` / `StrLayoutUpdated`
- 常见坑：
	- 每 tick 无脏检查地全量写变量
	- 后台任务直接调线程不安全 setter（应用 `Async` 变体）
	- 误以为 `GetDialogVariableStringForPlayer` 会回退全局值
	- map / 插件卸载不清理实体；点击事件订阅与退订不配对

#### 2）我要让 Custom HUD 内按钮可点击

- 先看官方：
	1. `Custom HUD`（Input Capture / Handling Button Clicks）
- 再看本地参考：
	- `./swiftlys2-custom-hud.md`
- 常用 API / 关键词：
	- `SetInputCaptureEnabled(ForPlayer)`
	- `Core.Event.OnCustomHudClicked`
	- `IOnCustomHudClickedEvent`（`PlayerId` / `ButtonId` / `CustomHudLayout`）
- 常见坑：
	- 多个 layout 时未比对 `CustomHudLayout` 实体就处理 ButtonId
	- 交互结束后忘关输入捕获，玩家光标被占用

### 我要写 Hook

#### 1）我要写 typed GameHooks / 高频运行态 Hook

- 先看官方：
	1. `GameHooks` API
	2. `Thread Safety`
	3. `Profiler`
- 再看本地资产：
	- `./swiftlys2-performance-optimization-playbook.md`
	- `../assets/development/game-hooks/game-hooks-pre-post-guide.md`
	- `../assets/development/thread-safety/thread-sensitivity-checklist.md`
	- `../assets/development/profiler/hotpath-gc-checklist.md`
- 常见坑：
	- 热路径中做 JSON / IO / 高频日志
	- 不做 player / pawn / fakeclient 过滤
	- 把复杂逻辑直接塞进 Hook 回调
	- 让 `ref struct` context / usercmd / temporary wrapper 跨 callback
	- 在 Post 中依赖取消语义

#### 2）我要写 generated Game Event

- 先看官方：
	1. `Game Events`
	2. `GameEventDefinitions` API
- 再看本地资产：
	- `../assets/development/game-events/game-events-usage-notes.md`
- 常用 API / 关键词：
	- `HookPre<T>` / `HookPost<T>`
	- `Unhook(Guid)`
	- `FireAsync<T>`
	- `DontBroadcast` / `Accessor`
- 常见坑：
	- 将 event / accessor 保存到延迟或 async 回调
	- 把不可靠 Game Event 当作 Core lifecycle

#### 3）我要写 native function hook / mid-hook

- 先看官方：
	1. `Native Functions and Hooks`
	2. `Thread Safety`
- 再看本地资产：
	- `./swiftlys2-performance-optimization-playbook.md`
	- `../assets/development/native-functions-and-hooks/hook-handler-template.cs.md`
- 常见坑：
	- delegate 原型不匹配
	- 不知道 `Call()` 与 `CallOriginal()` 的差异
	- mid-hook 乱改寄存器

### 我要写 NetMessage / Protobuf

#### 1）我要发送 typed netmessage

- 先看官方：
	1. `Network Messages`
	2. `Thread Safety`
- 再看本地资产：
	- `../assets/development/netmessages/protobuf-handler-template.cs.md`
- 常用 API / 关键词：
	- `Core.NetMessage.Send<T>`
	- `Core.NetMessage.Create<T>`
	- `Recipients`
- 常见坑：
	- 忘记释放可复用 message
	- 用 magic number 代替 typed API

#### 2）我要 hook client/server message

- 先看官方：
	1. `Network Messages`
	2. API Reference 的 `INetMessageService`
- 再看本地资产：
	- `../assets/development/netmessages/protobuf-handler-template.cs.md`
	- `../assets/development/thread-safety/thread-sensitivity-checklist.md`
- 常见坑：
	- 直接把 protobuf handle 丢给后台线程
	- 不区分 hook client message 与 server message

### 我要写 Shared API

#### 1）我要提供 shared interface

- 先看官方：
	1. `Shared API`
	2. `Dependency Injection`
- 再看本地资产：
	- `../assets/development/shared-api/shared-interface-template.cs.md`
	- `../assets/guides/dependency-injection/di-service-plugin-template.cs.md`
- 常见坑：
	- 不做 contracts DLL
	- key 命名过于模糊
	- 没考虑版本化

#### 2）我要消费 shared interface

- 先看官方：
	1. `Shared API`
- 再看本地资产：
	- `../assets/development/shared-api/shared-interface-template.cs.md`
- 常见坑：
	- 不使用 `TryGetSharedInterface(...)` 处理 optional dependency
	- provider 未加载就假定接口已存在
	- unload 后继续持有旧接口引用

### 我要写 Scheduler / Worker / 后台任务

#### 1）我要决定用 Scheduler 还是后台 Worker

- 先看官方：
	1. `Scheduler`
	2. `Thread Safety`
- 再看本地资产：
	- `./swiftlys2-performance-optimization-playbook.md`
	- `../assets/development/scheduler/scheduler-vs-worker-guide.md`
	- `../assets/patterns/background-workers/worker-template.cs.md`
	- `../assets/development/core-events/lifecycle-checklist.md`
- 常见坑：
	- 把后台 worker 当成 Scheduler
	- 在 worker 线程直接访问主线程敏感 API
	- 没有 stop / flush / cancel 闭环

### 我要接入数据库、声音、Steamworks、Memory 或服务器运行配置

| 场景 | 先看官方 | 再看本地资产 |
| --- | --- | --- |
| 插件数据库连接与 ADO.NET/ORM | `Database` | `../assets/development/database/database-connection-template.cs.md` |
| 实体 spawn 前 key values | `Entity Key Values` | `../assets/development/entity/entity-key-values-guide.md` |
| 自定义声音与接收者 | `Sound Events` + `Thread Safety` | `../assets/development/sound-events/sound-event-guide.md` |
| Steam server/Workshop/auth callback | `Steamworks` | `../assets/development/steamworks/steamworks-server-guide.md` |
| signature/vtable/xref/alloc | `Memory` API | `../assets/development/memory/memory-service-guide.md` |
| 启动参数、core config、命令权限覆盖、console filter | `Resources` | `../assets/resources/runtime-configuration-guide.md` |
| CSS 迁移 | `Porting from CounterStrikeSharp` | `../assets/guides/porting-from-css/porting-checklist.md` |

## 7. 推荐检索关键词

### 生命周期

- `OnClientPutInServer`
- `OnClientDisconnected`
- `OnMapLoad`
- `OnMapUnload`

### 命令

- `ICommandContext`
- `Command`
- `CommandAlias`
- `Reply`

### Hooks / movement

- `Core.GameHooks`
- `ProcessUsercmdsPreContext` / `ProcessUsercmdsPostContext`
- `RunCommandMovementPreContext` / `RunCommandMovementPostContext`
- `TakeDamageEntityPreContext`
- `GameHookHandler`
- `MidHookContext`

### Performance / GC

- `AggressiveInlining`
- `stackalloc`
- `Span`
- `StringBuilder`
- `PeriodicTimer`
- `Generation`
- `Backpressure`
- `StructLayout`

### NetMessages / Protobuf

- `INetMessageService`
- `ITypedProtobuf`
- `IProtobufAccessor`

### Shared API

- `IInterfaceManager`
- `ConfigureSharedInterface`
- `UseSharedInterface`
- `HasSharedInterface`
- `TryGetSharedInterface`
- `OnSharedInterfaceInjected`

### Database / Sound / Steam / Memory

- `IDatabaseService` / `GetConnectionInfo`
- `SoundEvent` / `EmitAsync`
- `SteamGameServerUGC` / `Callback<T>` / `CallResult<T>`
- `IMemoryService` / `GetAddressBySignature` / `GetUnmanagedFunctionByAddress`

### Schema / Entity

- `IEntitySystemService`
- `AcceptInput`
- `DispatchSpawn`
- `Despawn`
- `Updated`

### Menus

- `IMenuAPI`
- `IMenuOption`
- `ButtonMenuOption`
- `ToggleMenuOption`
- `SliderMenuOption`
- `SubmenuMenuOption`
- `BindingText`

### Custom HUD

- `CCSCustomHudLayout`
- `EHudPanelClassStatus_t`
- `IOnCustomHudClickedEvent`
- `SetDialogVariableStringForPlayer`
- `SetHasClassForPlayer`
- `SetInputCaptureEnabledForPlayer`

## 8. 使用建议

- **先定场景，再定资料源。**
- **先看官网与 mdwiki，再决定是否需要当前工作区定制补充。**
- **官网细节优先从 `swiftlys2-official-docs-map.md` 进入，再按需联网下钻到具体页面。**
- **本地模板与 checklist 优先从 `../assets/README.md` 进入，不要直接猜文件名。**
- **公共文档负责 API 与框架边界；工作区知识库负责当前工作区经验。**
