# SwiftlyS2 Knowledge Base Quick Index

本索引用于快速定位 **公开可引用** 的 SwiftlyS2 资料入口。

若当前工作区还有本地参考仓库、项目映射、历史参考项目或定制经验，请改去 `../../knowledge-base.md` 与 `../../copilot-instructions.md` 中登记，不要把它们写回这里。

## 1. SwiftlyS2 官网入口

### 总入口

- Docs Root：`https://swiftlys2.net/docs/`
- Docs Map（本工具包精简导航）：`./swiftlys2-official-docs-map.md`
- API Reference：`https://swiftlys2.net/docs/api/`

### Development 区主入口

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

### Guides 区主入口

- Dependency Injection：`https://swiftlys2.net/docs/guides/dependency-injection/`
- Development Flow（当前官网仍为占位 todo）：`https://swiftlys2.net/docs/guides/development-flow/`
- HTML Styling：`https://swiftlys2.net/docs/guides/html-styling/`
- Porting from CounterStrikeSharp：`https://swiftlys2.net/docs/guides/porting-from-css/`
- Terminologies：`https://swiftlys2.net/docs/guides/terminologies/`

### API Reference 使用建议

- 本工具包不内置完整 API Reference 全量提取，避免体积膨胀。
- 先看：`./swiftlys2-official-docs-map.md` 中的 API Reference 瘦导航。
- 再按栏目联网深挖：如 `commands`、`netmessages`、`players`、`schemas`、`services`。

## 2. 本工具包 assets 导航

- Assets Root：`../assets/README.md`
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
- **我要写高频 Hook / native hook / movement 采样** → `Native Functions and Hooks`
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

### 我要写 Hook

#### 1）我要写 typed core event / 高频运行态 Hook

- 先看官方：
	1. `Core Events`
	2. `Thread Safety`
	3. `Profiler`
- 再看本地资产：
	- `../assets/development/native-functions-and-hooks/hook-handler-template.cs.md`
	- `../assets/development/thread-safety/thread-sensitivity-checklist.md`
	- `../assets/development/profiler/hotpath-gc-checklist.md`
- 常见坑：
	- 热路径中做 JSON / IO / 高频日志
	- 不做 player / pawn / fakeclient 过滤
	- 把复杂逻辑直接塞进 Hook 回调

#### 2）我要写 native function hook / mid-hook

- 先看官方：
	1. `Native Functions and Hooks`
	2. `Thread Safety`
- 再看本地资产：
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
	- 不先 `HasSharedInterface(...)`
	- provider 未加载就假定接口已存在
	- unload 后继续持有旧接口引用

### 我要写 Scheduler / Worker / 后台任务

#### 1）我要决定用 Scheduler 还是后台 Worker

- 先看官方：
	1. `Scheduler`
	2. `Thread Safety`
- 再看本地资产：
	- `../assets/development/scheduler/scheduler-vs-worker-guide.md`
	- `../assets/patterns/background-workers/worker-template.cs.md`
	- `../assets/development/core-events/lifecycle-checklist.md`
- 常见坑：
	- 把后台 worker 当成 Scheduler
	- 在 worker 线程直接访问主线程敏感 API
	- 没有 stop / flush / cancel 闭环

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

- `OnClientProcessUsercmds`
- `OnMovementServicesRunCommandHook`
- `DynamicHook`
- `MidHookContext`

### NetMessages / Protobuf

- `INetMessageService`
- `ITypedProtobuf`
- `IProtobufAccessor`

### Shared API

- `IInterfaceManager`
- `ConfigureSharedInterface`
- `UseSharedInterface`
- `HasSharedInterface`

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

## 8. 使用建议

- **先定场景，再定资料源。**
- **先看官网与 mdwiki，再决定是否需要当前工作区定制补充。**
- **官网细节优先从 `swiftlys2-official-docs-map.md` 进入，再按需联网下钻到具体页面。**
- **本地模板与 checklist 优先从 `../assets/README.md` 进入，不要直接猜文件名。**
- **公共文档负责 API 与框架边界；工作区知识库负责当前工作区经验。**
