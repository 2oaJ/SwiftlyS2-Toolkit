# SwiftlyS2 Service Factory / Keyed Service 模式

对应官方文档：
- `Dependency Injection`

适用于：同一接口有多个实现、需要策略选择、或需要按 key/type 动态解析服务的插件。

## 一、Service Factory 模式

适合：一个功能接口有多个策略实现，需要在运行时按名称/类型选择。

### 接口定义

```csharp
public interface IMyService
{
    string Key { get; }
    void Execute(IPlayer player);
    void OnPrecacheResource(IOnPrecacheResourceEvent @event);
}

public interface IMyServiceFactory
{
    IMyService? GetService(string key);
    IEnumerable<IMyService> GetAllServices();
}
```

### 工厂实现

```csharp
public class MyServiceFactory : IMyServiceFactory
{
    private readonly ConcurrentDictionary<string, IMyService> _services = new();

    public void Register(IMyService service)
    {
        _services.TryAdd(service.Key, service);
    }

    public IMyService? GetService(string key)
    {
        _services.TryGetValue(key, out var service);
        return service;
    }

    public IEnumerable<IMyService> GetAllServices() => _services.Values;
}
```

### DI 注册

```csharp
var services = new ServiceCollection();
services.AddSwiftly(Core);
services.AddSingleton<IMyServiceFactory, MyServiceFactory>();
services.AddSingleton<IMyService, StrategyA>();
services.AddSingleton<IMyService, StrategyB>();

var sp = services.BuildServiceProvider();
var factory = sp.GetRequiredService<IMyServiceFactory>();
foreach (var svc in sp.GetServices<IMyService>())
{
    factory.Register(svc);
}
```

## 二、Keyed Singleton 模式

适合：同一接口的多个实例需要独立配置（如多个 GameData Patch、多个修复项）。

### 注册

```csharp
services.AddKeyedSingleton<IGameFixService>("FixA",
    (sp, key) => new GameDataPatchService(Core, sp.GetRequiredService<ILogger<GameDataPatchService>>(), "FixA"));
services.AddKeyedSingleton<IGameFixService>("FixB",
    (sp, key) => new GameDataPatchService(Core, sp.GetRequiredService<ILogger<GameDataPatchService>>(), "FixB"));
```

### 解析

```csharp
var fixA = sp.GetRequiredKeyedService<IGameFixService>("FixA");
var fixB = sp.GetRequiredKeyedService<IGameFixService>("FixB");
```

### 批量管理

```csharp
var allFixes = new IGameFixService[]
{
    sp.GetRequiredKeyedService<IGameFixService>("FixA"),
    sp.GetRequiredKeyedService<IGameFixService>("FixB"),
};

// 统一安装
foreach (var fix in allFixes)
{
    try { fix.Install(); }
    catch (Exception ex) { Logger.LogError(ex, "安装 {Name} 失败", fix.ServiceName); }
}

// 统一卸载
foreach (var fix in allFixes)
{
    try { fix.Uninstall(); }
    catch (Exception ex) { Logger.LogError(ex, "卸载 {Name} 失败", fix.ServiceName); }
}
```

## 三、Multi-Implementation 解析（`GetServices<T>()`）

适合：一个接口的所有实现都需要被调用（如多种触发器类型服务）。

```csharp
// 注册多个实现到同一接口
services.AddSingleton<ITriggerTypeService, AreaTeleportService>();
services.AddSingleton<ITriggerTypeService, AreaPushService>();
services.AddSingleton<ITriggerTypeService, AirWallService>();

// 解析所有实现
var sp = services.BuildServiceProvider();
foreach (var triggerService in sp.GetServices<ITriggerTypeService>())
{
    triggerService.Install();
    _typeIndex[triggerService.TriggerType] = triggerService;  // 按类型建索引
}
```

## 四、模式对比

| 模式 | 适合场景 | 解析方式 |
|------|---------|---------|
| Factory | 运行时按名称/配置选择策略 | `factory.GetService(key)` |
| Keyed Singleton | 同接口多个独立配置实例 | `sp.GetRequiredKeyedService(key)` |
| `GetServices<T>()` | 所有实现都需遍历调用 | `sp.GetServices<T>()` |

## Checklist

- [ ] 多实现是否选择了正确的 DI 模式（factory / keyed / multi-resolve）？
- [ ] 工厂注册是否在 `ServiceProvider` 构建后完成？
- [ ] 批量管理是否有异常隔离（一个失败不影响其他）？
- [ ] 各实现是否都遵循 `Install() / Uninstall()` 生命周期闭环？
- [ ] Keyed 服务的 key 是否具有业务语义且不易冲突？
