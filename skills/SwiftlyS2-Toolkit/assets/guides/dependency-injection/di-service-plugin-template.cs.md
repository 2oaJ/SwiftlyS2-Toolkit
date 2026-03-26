# SwiftlyS2 DI / Service 插件模板

对应官方文档：
- `Dependency Injection`
- `Swiftly Core`
- `Using attributes`

适用于：DI / service 导向、共享服务导向、或混合架构中的中/大型插件。

## 目录建议

```text
MyPlugin/
├── MyPlugin.cs
├── Interface/
├── Impl/
├── Models/
├── Extensions.cs
└── Config.cs
```

## 基本骨架

```csharp
using Microsoft.Extensions.DependencyInjection;
using SwiftlyS2.Shared;
using SwiftlyS2.Shared.Plugins;

namespace MyNamespace
{
    [PluginMetadata(
        Id = "MyNamespace.MyPlugin",
        Name = "My Plugin",
        Author = "YourName",
        Version = "1.0.0",
        Description = "插件描述",
        Website = "https://example.com"
    )]
    public class MyPlugin(ISwiftlyCore core) : BasePlugin(core)
    {
        private IServiceProvider? _serviceProvider;

        public override void Load(bool hotReload)
        {
            var services = new ServiceCollection();
            services.AddSwiftly(Core);
            services.AddSingleton<IMyService, MyService>();

            _serviceProvider = services.BuildServiceProvider();
            _serviceProvider.GetRequiredService<IMyService>().Install();
        }

        public override void Unload()
        {
            if (_serviceProvider?.GetService<IMyService>() is { } service)
            {
                service.Uninstall();
            }
        }
    }
}
```

## 模块型监听所有权建议

- 插件 root 只负责 `ServiceCollection`、安装顺序、卸载顺序
- `Event` / `GameEvent` / `Hook` / `Command` 的注册与反注册，优先由各自 service 自己持有
- 若某个 hook 只在特定配置开启时需要，service 应维护自己的布尔标记并动态挂/卸，而不是永久挂着再在回调里空转
- root 只 orchestrate，service 自己完成监听闭环

## Keyed Singleton 与多实现

当同一接口有多个独立实例时，使用 Keyed Singleton：

```csharp
// 注册
services.AddKeyedSingleton<IMyService>("VariantA",
    (sp, key) => new MyServiceImpl(core, "VariantA"));
services.AddKeyedSingleton<IMyService>("VariantB",
    (sp, key) => new MyServiceImpl(core, "VariantB"));

// 解析
var a = sp.GetRequiredKeyedService<IMyService>("VariantA");
var b = sp.GetRequiredKeyedService<IMyService>("VariantB");
```

当所有实现都需要遍历时，使用 `GetServices<T>()`：

```csharp
services.AddSingleton<IMyService, ImplA>();
services.AddSingleton<IMyService, ImplB>();

// 获取全部
foreach (var svc in sp.GetServices<IMyService>())
{
    svc.Install();
}
```

详见：`../../patterns/service-factory/service-factory-template.cs.md`
