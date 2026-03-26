# SwiftlyS2 Shared API 模板

对应官方文档：
- `Shared API`
- `Dependency Injection`

适用于：跨插件暴露共享服务、消费其他插件接口、contracts DLL 设计。

## Provider / Consumer 的最小结构

- Contracts DLL：定义接口，供 provider / consumer 共用
- Provider：在 `ConfigureSharedInterface` 中注册接口实现
- Consumer：在 `UseSharedInterface` 中检测并获取共享接口

## Contracts 示例

```csharp
namespace MyPlugin.Contracts;

public interface IEconomyService : IDisposable
{
    int GetPlayerBalance(int playerId);
    void AddPlayerBalance(int playerId, int amount);
    bool RemovePlayerBalance(int playerId, int amount);
}
```

## Provider 示例

```csharp
using MyPlugin.Contracts;
using SwiftlyS2.Shared;
using SwiftlyS2.Shared.Plugins;

public sealed class EconomyPlugin(ISwiftlyCore core) : BasePlugin(core)
{
    public override void ConfigureSharedInterface(IInterfaceManager interfaceManager)
    {
        var economyService = new EconomyService();
        interfaceManager.AddSharedInterface<IEconomyService, EconomyService>(
            "Economy.Service.v1",
            economyService);
    }
}
```

## Consumer 示例

```csharp
using MyPlugin.Contracts;
using SwiftlyS2.Shared;
using SwiftlyS2.Shared.Plugins;

public sealed class ShopPlugin(ISwiftlyCore core) : BasePlugin(core)
{
    private IEconomyService? _economyService;

    public override void UseSharedInterface(IInterfaceManager interfaceManager)
    {
        if (!interfaceManager.HasSharedInterface("Economy.Service.v1"))
        {
            Core.Logger.LogWarning("Economy.Service.v1 尚未加载。");
            return;
        }

        _economyService = interfaceManager.GetSharedInterface<IEconomyService>("Economy.Service.v1");
    }
}
```

## Checklist

- 是否把 interface 放在单独 contracts DLL？
- key 是否使用清晰命名并考虑版本化？
- consumer 获取前是否先 `HasSharedInterface(...)`？
- interface 是否考虑继承 `IDisposable`？
- provider / consumer 卸载时是否有 cleanup 闭环？

## 延迟初始化守卫模式

当 consumer 的核心功能强依赖共享接口时，不应在 `Load()` 中初始化业务，而应延迟到 `UseSharedInterface()` 中：

```csharp
public sealed class MyPlugin(ISwiftlyCore core) : BasePlugin(core)
{
    private bool _servicesInitialized;

    public override void Load(bool hotReload)
    {
        // 不在此初始化依赖共享接口的业务
        Core.Logger.LogInformation("MyPlugin loading...");
    }

    public override void UseSharedInterface(IInterfaceManager interfaceManager)
    {
        if (_servicesInitialized) return;

        if (!interfaceManager.HasSharedInterface("Economy.Service.v1"))
        {
            Core.Logger.LogWarning("Economy.Service.v1 尚未可用，延迟初始化");
            return;
        }

        var economyService = interfaceManager.GetSharedInterface<IEconomyService>("Economy.Service.v1");
        InitializeServices(economyService);
        _servicesInitialized = true;
    }

    private void InitializeServices(IEconomyService economyService)
    {
        // 在此初始化 DI 容器、注册服务、启动 Scheduler 等
    }
}
```

**关键点**：
- `UseSharedInterface` 可能被多次调用（每当有新插件注册接口时）
- 使用 `_servicesInitialized` 布尔守卫避免重复初始化
- 依赖不可用时记录 warning 并提前返回，不要抛异常
- 在延迟初始化完成后才启动 Scheduler、Worker 等持续性工作

## 两阶段跨插件依赖

当两个插件互相依赖时（如 Plugin A 提供某个 trigger，Plugin B 消费并反向注入自己的 manager），使用两阶段模式：

1. **Phase 1（ConfigureSharedInterface）**：Plugin A 注册接口
2. **Phase 2（UseSharedInterface）**：Plugin B 获取 A 的接口，并对 A 进行反向注入

```csharp
// Plugin B（消费者 + 反向注入）
public override void UseSharedInterface(IInterfaceManager interfaceManager)
{
    if (!interfaceManager.HasSharedInterface("PluginA.FeatureTrigger"))
        return;

    var trigger = interfaceManager.GetSharedInterface<IFeatureTrigger>(
        "PluginA.FeatureTrigger");

    // 反向注入 manager 到 trigger
    if (trigger is IFeatureTriggerInitializable initializable)
    {
        initializable.SetManager(_featureManager);
    }
}
```
