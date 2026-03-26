# SwiftlyS2 官网文档导航图

本文件用于把 `https://swiftlys2.net/docs/` 整理成**适合 agent 快速检索与二次联网深挖**的公开导航。

目标不是把官网全文搬进工具包，而是：

- 保留稳定入口
- 提炼每页“这页是干什么的”
- 把对 SwiftlyS2 插件开发最关键的工程语义先压缩出来
- 避免把完整 API Reference 全量塞进工具包导致臃肿

## 使用规则

- **Installation**：保留入口，但本工具包不做正文提取。
- **API Reference**：只保留瘦导航与检索建议；需要详细 API 时由 agent 自行联网进入 `https://swiftlys2.net/docs/api/` 按需提取。
- **Development Flow**：当前官网页面仍是 `todo` 占位，不应作为可靠工程依据。

## Docs Root

- 总入口：`https://swiftlys2.net/docs/`
- 首页定位：介绍 SwiftlyS2 是基于 Metamod:Source 的 CS2 服务端插件框架，强调 Commands、Convars、Entity System、Events、GameEvents、Memory、Menus、Hooks、NetMessages、Profiler、Scheduler、Schemas、Sounds 等能力。
- 首页用途：适合作为**能力总览与栏目入口**，不适合作为细节参考。

## Development 区导航

### 1. Getting Started

- 地址：`https://swiftlys2.net/docs/development/getting-started/`
- 定位：新插件起步、模板安装、发布流程入口。
- 关键点：
  - 依赖 `.NET 10.0 SDK`
  - 通过 `SwiftlyS2.CS2.PluginTemplate` 创建插件模板
  - 模板版本可能落后，需要手动更新 `PackageReference`
  - 发布产物在 `build/publish`
  - 官网明确建议在正式写代码前先读 `Dependency Injection`
- 适用场景：创建新插件、检查模板工程结构、确认基础发布流程。

### 2. Swiftly Core

- 地址：`https://swiftlys2.net/docs/development/swiftly-core/`
- 定位：`ISwiftlyCore` 总入口说明。
- 关键点：
  - `ISwiftlyCore` 是框架中心单例
  - 汇总 Event、Engine、GameEvent、NetMessage、Helpers、Game、Command、EntitySystem、ConVar、Configuration、GameData、PlayerManager、Memory、Profiler、Trace、Scheduler、Database、Translation、Permission、Registrator、MenusAPI、PluginManager 等服务
  - 官方明确推荐通过依赖注入共享 `ISwiftlyCore`
  - 与插件生命周期、热重载紧密相关
- 适用场景：梳理 service 边界、查 core 服务入口、设计 DI 架构。

### 3. Using attributes

- 地址：`https://swiftlys2.net/docs/development/using-attributes/`
- 定位：解释 attribute 注册机制的适用边界。
- 关键点：
  - attribute 默认只在继承 `BasePlugin` 的主类中可直接使用
  - 若在其他类使用 attribute，需要先调用 `Core.Registrator.Register(this)`
- 适用场景：解释为什么 service / module 里的 `[Command]`、事件 attribute 不生效。

### 4. Thread Safety

- 地址：`https://swiftlys2.net/docs/development/thread-safety/`
- 定位：主线程敏感 API 清单。
- 关键点：
  - 非主线程调用线程不安全 API 可能直接导致崩溃
  - Async 变体在主线程会立即执行，非主线程会调度到下一 Tick
  - 明确列出主线程敏感调用：
    - `IPlayer.Send* / Kick / ChangeTeam / SwitchTeam / TakeDamage / Teleport / ExecuteCommand`
    - `IGameEventService.Fire*`
    - `IEngineService.ExecuteCommand*`
    - `CEntityInstance.AcceptInput / AddEntityIOEvent / DispatchSpawn / Despawn`
    - `IPlayerManagerService.Send*`
    - `ICommandContext.Reply`
    - `CBaseModelEntity.SetModel / SetBodygroupByName`
    - `IEngineService.DispatchParticleEffect`
    - `CCSPlayerController.Respawn`
    - `Projectile.EmitGrenade`
    - `CPlayer_ItemServices.* / CPlayer_WeaponServices.*`
- 适用场景：审计异步任务、菜单回调、后台 worker、Hook 热路径回写。

### 5. Commands

- 地址：`https://swiftlys2.net/docs/development/commands/`
- 定位：命令、命令别名、客户端命令/聊天 Hook。
- 关键点：
  - 可用 `[Command]` 或 `Core.Command.RegisterCommand`
  - 可用 `[CommandAlias]` 或 `Core.Command.RegisterCommandAlias`
  - `registerRaw` 控制是否跳过 `sw_` 前缀
  - 支持内建 permission 参数
  - 客户端命令/聊天 Hook 均返回 `HookResult`
  - 卸载时自动清理，但也支持手动 `Unregister` / `Unhook`
- 适用场景：命令系统设计、聊天拦截、客户端命令过滤。

### 6. Configuration

- 地址：`https://swiftlys2.net/docs/development/configuration/`
- 定位：插件配置初始化、加载、热重载。
- 关键点：
  - 入口为 `Core.Configuration`
  - 支持通过模板初始化配置文件
  - 支持 `InitializeJsonWithModel<T>` / `InitializeTomlWithModel<T>` 根据 C# 模型生成默认配置
  - `Configure(builder => ...)` 可追加 `json/jsonc/toml` 配置源
  - 推荐搭配 `IOptionsMonitor<T>` 使用，并支持 `reloadOnChange`
  - 支持 fluent method chaining
- 适用场景：配置模型设计、热重载、DI + Options 模式。

### 7. Translations

- 地址：`https://swiftlys2.net/docs/development/translations/`
- 定位：翻译资源组织与本地化读取。
- 关键点：
  - 翻译文件位于 `resources/translations/*.jsonc`
  - 使用语言代码命名，如 `en.jsonc`、`zh-CN.jsonc`
  - 常用入口：`Core.Translation.GetPlayerLocalizer(player)`
  - 支持参数化占位 `{0}`, `{1}`
  - 缺失 key 时默认返回 key 本身
  - 推荐始终提供 `en.jsonc` 作为兜底
  - 推荐统一 key 命名：`category.subcategory.key`
- 适用场景：玩家本地化消息、命令提示、菜单文本国际化。

### 8. Entity

- 地址：`https://swiftlys2.net/docs/development/entity/`
- 定位：实体创建、查询、句柄安全。
- 关键点：
  - `Core.EntitySystem.CreateEntity<T>()` 或按 designer name 创建实体
  - 可枚举全部实体或按类筛选
  - 官网明确强调：**长期持有裸实体非常危险**
  - 长期跟踪应使用 `CHandle<T>` / `GetRefEHandle(entity)`
  - `handle.Value` 可能为空，`handle.IsValid` 需先检查
- 适用场景：跨帧实体跟踪、预览实体、beam/worldtext、延迟任务里的实体引用。

### 9. Entity Key Values

- 地址：`https://swiftlys2.net/docs/development/entitykeyvalues/`
- 定位：`CEntityKeyValues` 的类型安全键值写入。
- 关键点：
  - `CEntityKeyValues` 实现 `IDisposable`
  - 提供 `SetBool/SetInt32/SetUInt32/SetInt64/SetFloat/SetString/...`
  - 也支持 `Set<T>` 与 `Get<T>` 泛型访问
  - 非支持类型会抛 `InvalidOperationException`
- 适用场景：构造实体 keyvalues、spawn 前配置实体属性。

### 10. Game Events

- 地址：`https://swiftlys2.net/docs/development/game-events/`
- 定位：Game Event 的 fire 与 hook。
- 关键点：
  - 可用 `Core.GameEvent.Fire<T>`、`FireToPlayer`
  - 支持 `HookPre<T>` / `HookPost<T>`
  - `@event` 是当前 Tick 的临时对象，不能跨 Tick 长期持有
  - 官网特别提醒：**Source 2 中很多 game event 已经偏废弃，部分不工作**
- 适用场景：仅在确有对应 Game Event 且验证可用时使用；不要盲目信任所有事件都可靠。

### 11. Core Events

- 地址：`https://swiftlys2.net/docs/development/core-events/`
- 定位：SwiftlyS2 自身 typed core listener 体系。
- 关键点：
  - Core event 不是 game event
  - 监听器在 hot reload / unload 时会销毁
  - 各事件参数类型承载字段信息
  - 详细事件列表查 `EventDelegates`
- 适用场景：地图、玩家、实体、tick、hook 回调等生命周期监听。

### 12. Network Messages

- 地址：`https://swiftlys2.net/docs/development/netmessages/`
- 定位：typed protobuf net message 发送与 hook。
- 关键点：
  - net message 基于 protobuf + message id
  - 可直接 `Core.NetMessage.Send<T>`
  - 高频复用时可 `Create<T>()` 后复用并 `using` 释放
  - 支持 client/server message hook 与对应 unhook
  - 详细类型参考 `ProtobufDefinitions` 与 `INetMessageService`
- 适用场景：Shake、声音、HUD、客户端/服务端网络消息拦截与发送。

### 13. Menus

- 地址：`https://swiftlys2.net/docs/development/menus/`
- 定位：完整菜单系统。
- 关键点：
  - 入口是 `Core.Menus` / `IMenuManagerAPI`
  - 支持 builder fluent API
  - 内建选项类型：`Button / Toggle / Slider / Choice / Text / Input / ProgressBar / Submenu`
  - 支持层级菜单、动态内容、全局事件、per-player 校验与格式化
  - 支持 `BeforeFormat` / `AfterFormat` / `Validating` / `Click` / `ValueChanged`
  - 支持滚动风格、按键覆盖、冻结玩家、自动关闭等行为
- 适用场景：交互式菜单、动态 HUD 菜单、权限感知菜单。

### 14. Convars

- 地址：`https://swiftlys2.net/docs/development/convars/`
- 定位：ConVar 创建、查找、复制到客户端、客户端查询。
- 关键点：
  - `Core.ConVar.Create<T>()` / `Find<T>()`
  - `.Value` 赋值会进入内部事件队列，不一定立即生效
  - 临时即时修改应优先考虑 `.SetInternal(T value)`
  - 支持 `ReplicateToClient`、`QueryClient`
  - 支持 flag 增删改查
- 适用场景：临时切换 cvar、读取游戏 convar、客户端 convar 查询。

### 15. Native Functions and Hooks

- 地址：`https://swiftlys2.net/docs/development/native-functions-and-hooks/`
- 定位：签名、地址、delegate、函数 hook、中间 hook。
- 关键点：
  - 可从 gamedata 获取签名，再解析地址
  - delegate 原型必须与原生签名严格匹配
  - `Call()` 会经过当前可能已被其他 mod hook 的地址；`CallOriginal()` 走原始调用
  - 支持函数 hook 与 mid-hook 地址 hook
  - mid-hook 可读写寄存器，但错误修改可能直接崩服
  - hook 都必须成对卸载；插件 unload 时框架会自动清理
- 适用场景：高阶原生调用、虚表函数、Detour / MidHook 级别扩展。

### 16. Scheduler

- 地址：`https://swiftlys2.net/docs/development/scheduler/`
- 定位：NextTick 与 Tick-based timer。
- 关键点：
  - `NextTick` 用于调度到下一 Tick
  - `Delay / Repeat / DelayAndRepeat` 默认单位是**游戏 Tick**
  - 秒级调用应使用 `*BySeconds` 变体
  - 返回 `CancellationTokenSource` 可取消
  - `StopOnMapChange(token)` 可在换图时自动取消
- 适用场景：主线程延迟、小型周期任务、地图切换时自动收尾。

### 17. Shared API

- 地址：`https://swiftlys2.net/docs/development/shared-api/`
- 定位：插件间共享接口。
- 关键点：
  - 通过 `ConfigureSharedInterface` 提供接口
  - 通过 `UseSharedInterface` 消费接口
  - interface 应放在单独 contracts DLL，供 provider / consumer 共用
  - 推荐 interface 继承 `IDisposable`
  - key 应使用明确命名并考虑版本化
  - 使用前先 `HasSharedInterface`
- 适用场景：跨插件共享服务、积分/权限/经济系统暴露。

### 18. Permissions

- 地址：`https://swiftlys2.net/docs/development/permissions/`
- 定位：权限检查、组、子权限。
- 关键点：
  - `Core.Permission.PlayerHasPermission(steamId, permission)`
  - 支持通配符 `*`
  - 可 `AddPermission` / `RemovePermission`
  - `permissions.jsonc` 支持玩家分组与 `__default`
  - 支持 `AddSubPermission(parent, child)` 形成层级权限
  - 推荐命名：`plugin.category.action`
- 适用场景：命令权限、菜单可见性、模块访问控制。

### 19. Profiler

- 地址：`https://swiftlys2.net/docs/development/profiler/`
- 定位：性能测量与命名约定。
- 关键点：
  - `StartRecording` / `StopRecording`
  - 也可用 `RecordTime` 手动记录微秒值
  - 推荐用层级名字，如 `Database.Players.Load`
- 适用场景：热路径性能采样、复杂流程分段计时。

### 20. Database

- 地址：`https://swiftlys2.net/docs/development/database/`
- 定位：统一数据库连接配置入口。
- 关键点：
  - `Core.Database.GetConnection(key)` 读取 SwiftlyS2 全局 `configs/database.jsonc`
  - key 不存在时回退到 default connection
  - 官方建议用 ORM / ADO.NET 工具，如 Dapper、FreeSql、EF Core
  - 官网提醒连接串中的用户名/密码/host/database 不应包含 `@ : /`
- 适用场景：插件数据库接入、全局连接复用。

### 21. Sound Events

- 地址：`https://swiftlys2.net/docs/development/soundevents/`
- 定位：声音事件创建与发送。
- 关键点：
  - `SoundEvent` 需 `using` / dispose
  - 发送前必须添加 recipients
  - 可设置 `Name / Volume / Pitch / SourceEntityIndex`
  - 可附加 position 与各类字段参数
- 适用场景：自定义提示音、武器音、环境音效广播。

### 22. Steamworks

- 地址：`https://swiftlys2.net/docs/development/steamworks/`
- 定位：精简版 Steamworks.NET（Game Server 侧）接入。
- 关键点：
  - 通过 `using SwiftlyS2.Shared.SteamAPI;` 使用
  - 包含 Steam ID、鉴权、服务器信息、Workshop 下载、回调处理等内容
  - callback 引用必须保活，避免被 GC 回收
  - 使用前应验证 Steamworks 是否初始化成功
  - `SteamAPI` 完整签名查 API Reference
- 适用场景：所有权校验、Workshop 下载、服务器信息上报。

## Guides 区导航

### 1. Dependency Injection

- 地址：`https://swiftlys2.net/docs/guides/dependency-injection/`
- 定位：SwiftlyS2 官方首推设计模式。
- 关键点：
  - 推荐 `ServiceCollection().AddSwiftly(Core)`
  - 常见注入对象：`ISwiftlyCore`、`ILogger<T>`、`IOptionsMonitor<T>`
  - 若 service 里使用 attribute，需要自行注册对象
- 适用场景：新插件架构、service 分层、Options 模式。

### 2. Development Flow

- 地址：`https://swiftlys2.net/docs/guides/development-flow/`
- 当前状态：官网正文仍是 `todo`
- 使用建议：可保留入口，但**不要把这页当作正式依据**。

### 3. HTML Styling

- 地址：`https://swiftlys2.net/docs/guides/html-styling/`
- 定位：Panorama UI HTML 样式指南。
- 关键点：
  - 官方列出常用可用标签：`div`、`span`、`p`、`a`、`img`、`br`、`hr`、`h1-h6`、`strong`、`em`、`b`、`i`、`u`、`pre`
  - 样式不是标准 `style="..."`，而是直接写属性，如 `color="red"`
  - 推荐优先使用内建 class，如 `fontSize-l`、`fontSize-xl`、`fontWeight-bold`、`CriticalText`
  - `class` 与 `color` 可组合使用，适合“动态颜色 + 固定字号/字重”模式
  - 官方示例覆盖 ready 计数、倒计时、进度条、比分显示、多行规则说明等提示类 UI
  - 复杂布局、深层嵌套、非常规 class 都必须进游戏实测
  - 官方还给出 SteamDatabase 的 Panorama styles 参考入口，可继续查 `panorama_base.css`、`gamestyles.css` 等文件
- 适用场景：`SendCenterHTML`、中心提示、菜单格式化、`BindingText` / `BeforeFormat` / `AfterFormat` 这类富文本 UI 场景。
- 工具包内详细说明：`../assets/guides/html-styling/README.md`

### 4. Porting from CounterStrikeSharp

- 地址：`https://swiftlys2.net/docs/guides/porting-from-css/`
- 定位：从 CounterStrikeSharp 迁移到 SwiftlyS2 的系统指南。
- 关键点：
  - 对比 .csproj、事件、命令、菜单、配置、数据库、ConVar、监听器、GameData Hook、迁移顺序
  - 强调 SwiftlyS2 使用 `.NET 10`
  - 强调用 `Updated()` 代替 CSS 里的 `SetStateChanged`
  - 给出从工具类到 `Core.*` 服务的替换思路
- 适用场景：历史仓库迁移、对齐 CSS 语义、做结构迁移计划。

### 5. Terminologies

- 地址：`https://swiftlys2.net/docs/guides/terminologies/`
- 定位：统一 managed / native / controller / pawn / player object / handle 概念。
- 关键点：
  - 解释 managed 与 native 边界
  - 区分 controller、pawn、slot/playerId、player object
  - 说明实体 index 范围与 handle 概念
  - 区分 temporary / permanent entities
- 适用场景：术语对齐、减少迁移与审计中的概念混乱。

## API Reference 瘦导航

### 总入口

- API Root：`https://swiftlys2.net/docs/api/`

### 官方首页给出的核心入口

- Core Object：`https://swiftlys2.net/docs/api/iswiftlycore/`
- Game Events：`https://swiftlys2.net/docs/api/gameevents/`
- Core Listeners：`https://swiftlys2.net/docs/api/events/`
- SteamWorks API：`https://swiftlys2.net/docs/api/steamapi/`
- Commands：`https://swiftlys2.net/docs/api/commands/`

### 首页侧边栏可见的高价值分类

- Memory：`https://swiftlys2.net/docs/api/memory/`
- Menus：`https://swiftlys2.net/docs/api/menus/`
- Natives：`https://swiftlys2.net/docs/api/natives/`
- NetMessages：`https://swiftlys2.net/docs/api/netmessages/`
- Permissions：`https://swiftlys2.net/docs/api/permissions/`
- Players：`https://swiftlys2.net/docs/api/players/`
- Plugins：`https://swiftlys2.net/docs/api/plugins/`
- ProtobufDefinitions：`https://swiftlys2.net/docs/api/protobufdefinitions/`
- Scheduler：`https://swiftlys2.net/docs/api/scheduler/`
- SchemaDefinitions：`https://swiftlys2.net/docs/api/schemadefinitions/`
- Schemas：`https://swiftlys2.net/docs/api/schemas/`
- Services：`https://swiftlys2.net/docs/api/services/`
- Sounds：`https://swiftlys2.net/docs/api/sounds/`
- SteamAPI：`https://swiftlys2.net/docs/api/steamapi/`
- StringTable：`https://swiftlys2.net/docs/api/stringtable/`
- Translation：`https://swiftlys2.net/docs/api/translation/`
- Helper：`https://swiftlys2.net/docs/api/helper/`
- Helpers：`https://swiftlys2.net/docs/api/helpers/`
- Misc：`https://swiftlys2.net/docs/api/misc/`

### 建议的联网检索方式

当工具包内摘要不足时，优先按下面顺序自行联网：

1. 先确定所属栏目：如 `Commands`、`Menus`、`NetMessages`、`Schemas`
2. 先打开对应 API 分类首页，而不是直接全站乱搜
3. 再进入具体接口，例如：
   - `ICommandService`
   - `ICommandContext`
   - `INetMessageService`
   - `IEntitySystemService`
   - `ISchedulerService`
   - `IInterfaceManager`
   - `IPermissionManager`
4. 若是 generated type（如 protobuf、schema definitions、game events），优先从分类页继续下钻

## 推荐阅读路线

### 新建插件

1. `Getting Started`
2. `Dependency Injection`
3. `Swiftly Core`
4. `Thread Safety`
5. 对应子系统页面（Commands / Menus / Configuration / Translations ...）

### 审计现有插件

1. `Thread Safety`
2. `Core Events`
3. `Entity`
4. `Scheduler`
5. `Profiler`
6. 对应子系统页面

### 做跨插件共享

1. `Shared API`
2. `Dependency Injection`
3. `Permissions`
4. API Reference 中的 `IInterfaceManager`

### 做 UI / 菜单 / HUD

1. `Menus`
2. `HTML Styling`
3. `Translations`
4. `NetMessages`

### 做迁移

1. `Terminologies`
2. `Porting from CounterStrikeSharp`
3. `Dependency Injection`
4. `Thread Safety`
5. 对应原有功能模块页面
