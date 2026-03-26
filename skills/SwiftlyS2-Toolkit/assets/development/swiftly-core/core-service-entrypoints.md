# SwiftlyS2 Core 服务入口速查

对应官方文档：
- `Swiftly Core`

用于：当 agent 已经知道要做什么，但还不确定该从 `ISwiftlyCore` 的哪个服务入口进入时，快速分流。

## 高频入口

- `Core.Command`
  - 命令注册、别名、client command/chat hook
- `Core.Event`
  - Core Events、tick、map、player、entity 生命周期监听
- `Core.GameEvent`
  - Game Event fire / hook
- `Core.NetMessage`
  - typed netmessage 发送与 hook
- `Core.EntitySystem`
  - 实体创建、查找、handle 获取
- `Core.ConVar`
  - cvar 创建、查找、复制到客户端
- `Core.Configuration`
  - 插件配置初始化、配置源、热重载
- `Core.Translation`
  - 本地化、玩家语言 localizer
- `Core.Permission`
  - 权限、组、子权限、wildcard
- `Core.Scheduler`
  - NextTick、Delay、Repeat、StopOnMapChange
- `Core.Database`
  - 全局数据库连接
- `Core.Profiler`
  - 轻量性能采样
- `Core.Registrator`
  - 非主类对象 attribute 注册
- `Core.Menus` / `Core.MenusAPI`
  - 菜单 builder、打开/关闭、菜单事件

## 使用建议

- 不确定入口时，先定“我要做的是命令、事件、菜单、实体、NetMessage、配置还是跨插件接口”。
- 再去 `references/swiftlys2-kb-index.md` 找场景化路线。
- 需要更细的官方页面时，再转 `references/swiftlys2-official-docs-map.md`。
