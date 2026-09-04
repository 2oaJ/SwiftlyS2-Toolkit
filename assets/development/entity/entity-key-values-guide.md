# SwiftlyS2 Entity Key Values 指南

对应官方文档：`Entity Key Values`、`Entity`、`Thread Safety`。

`CEntityKeyValues` 用于在 spawn 前构造或修改实体 key values。它是 `IDisposable`，只适合短生命周期的创建/配置过程。

## 基本模式

```csharp
using var keyValues = new CEntityKeyValues();
keyValues.SetString("targetname", "my_plugin_entity");
keyValues.SetVector("origin", new Vector(0f, 0f, 64f));

var entity = Core.EntitySystem.CreateEntityByDesignerName<CBaseEntity>("logic_relay");

entity.DispatchSpawn(keyValues);
```

在非主线程流程中，使用 `DispatchSpawnAsync` 并 await；不要直接跨线程调用同步 spawn。

## 类型边界

- 使用 typed `Set` / `Get` 或 `Set<T>` / `Get<T>`，不要用字符串拼接模拟结构化值。
- API 不支持的泛型类型会抛出 `InvalidOperationException`，因此把不确定的复杂对象拆成官方支持的值或查 API Reference。
- 除 API 要求的紧邻 `await entity.DispatchSpawnAsync(keyValues)` 外，不要把 `CEntityKeyValues`、entity wrapper 或 raw native address 保存并交给任意 async/worker、地图切换或插件卸载后的流程。

## 与实体句柄配合

创建不等于 spawn。跨帧跟踪实体时不要把 `CBaseEntity` wrapper 当成长生命周期状态；应持有 `CHandle<T>`，每次访问前检查 `handle.IsValid`，再读取可空的 `handle.Value`。

## Checklist

- [ ] `CEntityKeyValues` 是否在同一同步作用域内 dispose？
- [ ] 是否确认实体创建和 spawn 两步都成功？
- [ ] 是否选择了 `DispatchSpawn` 或 `DispatchSpawnAsync` 对应线程上下文？
- [ ] 跨帧引用是否改为 `CHandle<T>`？
- [ ] 是否避免把 native ref、`Address` 或 wrapper 带到后台？
