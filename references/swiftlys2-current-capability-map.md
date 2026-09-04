# SwiftlyS2 当前能力对照矩阵

本矩阵是工具包同步用的能力边界，不是官方文档镜像。它记录本次与最新官方 `llms-full.txt` 的对照范围、可直接复用的本地资产，以及必须继续到官方 API 页确认的生成型接口。

## 快照来源

- URL：`https://swiftlys2.net/llms-full.txt`
- 拉取时间：`2026-07-14`
- HTTP `Last-Modified`：`2026-07-13T19:34:14Z`
- 文件大小：`16,960,204` bytes
- SHA-256：`C491BB1B58CFA420294AF83F652679F333CE7E0BFB89BDF54410AD6D71EF4E33`

“新增”在本文件中仅表示**当前官方快照已经公开、而旧工具包未覆盖或表述失准**，不声称某 API 在哪个版本首次发布。

## 对照原则

1. 手工 Development、Guides 和 Resources 页面逐页纳入矩阵。
2. API Reference 当前包含大量 generated 页面（本次快照约 6,253 个 API H1，含 Protobuf、Schema、Game Event 和 GameHooks 类型）；工具包只维护分类入口和使用边界，不静态复制成员签名。
3. 有过期本地模板时，删掉旧 API 路径，收敛到当前单一路径；不为 CSS 或旧 SwiftlyS2 调用保留 fallback。
4. 每次 SDK/服务器升级后，先复查本页快照和相关官方分类页，再修改可执行模板。

## 1. Development 页面

| 官方主题 | 当前能力重点 | 本地入口 |
| --- | --- | --- |
| Commands | attribute、service 注册、client command/chat hook、查询和 help text | `assets/development/commands/` |
| Configuration | JSONC/TOML、template init、options monitor、base path | `assets/development/configuration/` |
| Convars | typed/string API、replication、client query、safe min/max/default | `assets/development/convars/convar-template.cs.md` |
| Core Events | 生命周期、事件订阅/退订、高频事件边界 | `assets/development/core-events/` |
| Database | global config、`IDbConnection`、ADO.NET/ORM、secret handling | `assets/development/database/database-connection-template.cs.md` |
| Entity | create/spawn、handles、input/output、schema boundary | `assets/development/entity/` |
| Entity Key Values | typed key value container、dispose、spawn integration | `assets/development/entity/entity-key-values-guide.md` |
| Game Events | generated event fire/hook、Pre/Post、temporary wrappers | `assets/development/game-events/game-events-usage-notes.md` |
| Getting Started | project/plugin baseline | `assets/development/getting-started/partial-plugin-template.cs.md` |
| Menus | builder、option types、dynamic binding、async callback | `assets/development/menus/menu-template.cs.md` |
| Native Functions and Hooks | gamedata, memory, exact delegate, function/mid hook | `assets/development/native-functions-and-hooks/hook-handler-template.cs.md` |
| Network Messages | typed send/create、client/server/internal hook、temporary wrapper | `assets/development/netmessages/protobuf-handler-template.cs.md` |
| Permissions | check, group, hierarchy, current clear/remove APIs | `assets/development/permissions/README.md` |
| Profiler | record/measure and hot-path evidence | `assets/development/profiler/hotpath-gc-checklist.md` |
| Scheduler | main-loop dispatch, timer CTS, `AddTimer` | `assets/development/scheduler/scheduler-vs-worker-guide.md` |
| Shared API | provider/consumer callbacks and interface lifecycle | `assets/development/shared-api/shared-interface-template.cs.md` |
| Sound Events | recipient filter, typed fields, `Emit`/`EmitAsync` | `assets/development/sound-events/sound-event-guide.md` |
| Steamworks | server API, activation, callback lifetime, workshop/auth | `assets/development/steamworks/steamworks-server-guide.md` |
| Swiftly Core | service entrypoints and thread awareness | `assets/development/swiftly-core/core-service-entrypoints.md` |
| Thread Safety | `[ThreadUnsafe]`, async pairs, explicit main-loop dispatch | `assets/development/thread-safety/thread-sensitivity-checklist.md` |
| Translations | player/server localizer and placeholders | `assets/development/translations/README.md` |
| Using attributes | discovery, registration and signature validation | `assets/development/using-attributes/attribute-registration-checklist.md` |

## 2. Guides 和 Resources

| 官方主题 | 当前能力重点 | 本地入口 |
| --- | --- | --- |
| Chat & CenterHTML Styling | chat colors and Panorama HTML | `assets/guides/html-styling/README.md` |
| Dependency Injection | `AddSwiftly`, service ownership, attribute registration | `assets/guides/dependency-injection/` |
| Development Flow | 官方当前仍是占位内容，不作为实现依据 | `references/swiftlys2-official-docs-map.md` |
| Porting from CounterStrikeSharp | current API migration and CSS-only API removal | `assets/guides/porting-from-css/porting-checklist.md` |
| Terminologies | controller/pawn/player/entity/handle vocabulary | `assets/guides/terminologies/README.md` |
| CLI Options | startup path/log level/log visibility | `assets/resources/runtime-configuration-guide.md` |
| Core Configuration | `core.jsonc` global runtime policy | `assets/resources/runtime-configuration-guide.md` |
| Command Overrides | deployment-side command permission remapping | `assets/resources/runtime-configuration-guide.md` |
| Console Filter | verified noise filtering and reload workflow | `assets/resources/runtime-configuration-guide.md` |

## 3. API 分类覆盖

以下分类均在本次官方快照中存在。工具包按“先从分类页查当前签名”的方式覆盖，不为 generated 类型建立过时的本地 copy。

| 类别 | API 分类 |
| --- | --- |
| Core / DI | `ConsoleOutput`、`FileSystem`、`Helpers`、`HtmlGradient`、`IInterfaceManager`、`ISwiftlyCore`、`PluginMetadata`、`Scheduler`、`Shared`、`SwiftlyCoreInjection`、`SwiftlyInject`、`SwiftlyOptionsFactory` |
| Runtime services | `CommandLine`、`Commands`、`Convars`、`Database`、`Engine`、`EntitySystem`、`Events`、`GameEvents`、`Memory`、`Menus`、`NetMessages`、`Permissions`、`Plugins`、`Players`、`Profiler`、`Services`、`Sounds`、`SteamAPI`、`StringTable`、`Trace`、`Translation` |
| Native/generated surfaces | `Datamaps`、`GameEventDefinitions`、`GameHooks`、`Natives`、`Schemas`、`ProtobufDefinitions`、`SchemaDefinitions`、`Misc`、`Helper` |

优先跟踪的新增或易漂移分类：

- `GameHooks`：typed Pre/Post Context，替代多项旧 `Core.Event.On*Hook`。
- `GameEventDefinitions`：generated Game Event 字段随游戏/SDK 变化。
- `Datamaps`、`Schemas`、`SchemaDefinitions`：native layout 和 generated schema 不能从旧示例推断。
- `ProtobufDefinitions`、`NetMessages`：消息字段和 hook pipeline 以当前 API 为准。
- `CommandLine`、`Engine`、`EntitySystem`、`Profiler`、`Trace`：过去本地导航容易漏掉的运行时诊断入口。

## 4. 本次同步的高优先级差异

| 旧工具包问题 | 当前同步结论 |
| --- | --- |
| 把 `DynamicHook` / `[HookCallback]` 当 SwiftlyS2 native hook 模板 | 删除；typed hook 走 `Core.GameHooks`，raw hook 走 `Core.Memory` + exact delegate + `next()` chain |
| Core event hook 仍用于 usercmd、touch、damage、movement、weapon | 标记为迁移目标，改用相应 `Core.GameHooks` 分类 |
| Game Event 仅有 attribute 说明 | 补 `HookPre` / `HookPost` 的 `Guid`、`Unhook`、temporary event/accessor、`FireAsync*` |
| Post hook 可暗示取消 | 明确 `Handled` / `Stop` 对 Post 不生效 |
| Client command hook 依赖 `registerRaw` | 删除该前提；`registerRaw` 只控制 `sw_` 前缀 |
| 命令模板使用 `Arguments` 和旧 attributes namespace | 改为 `ICommandContext.Args` 与 `SwiftlyS2.Shared.Commands` |
| `SERVER_CAN_EXECUTE` 被当作权限限制 | 改为 `ConvarFlags.NONE` 默认；权限由 command/RCON/permission 层控制 |
| 旧 scheduler 示例假定 timer 自动绑定 map CTS | timer 自己返回 CTS，显式传给 `StopOnMapChange`；禁止 async scheduler lambda |
| `GetPlayerBySteamId`、`.Valid()`、`SetStateChanged()` | 改为当前 `GetPlayerFromSteamId` / `GetPlayerFromSessionId`、`IsValid`、`Updated()` |
| Resources 和若干 Development 页只有官方链接无本地入口 | 补数据库、Key Values、声音、Steamworks、Memory、迁移和运行维护资产 |

## 5. 未静态复制的范围

以下项目需要按任务从官网/API 分类页继续验证，而不是将当前快照全文写入 skill：

- 各 generated Game Event、Protobuf、Schema、Datamap 的具体字段和可用性。
- 每个 GameHook 的精确 Params、Pre/Post context 和允许写回的值。
- raw signature、vtable index、calling convention、mid-hook register layout。
- Steam callback 类型、游戏 app id、服务器/Workshop 当前环境行为。
- Resources 配置的实际安装路径和当前服务器部署覆盖。

这不是遗漏，而是防止本地静态副本再次变成过期 API 真相源。
