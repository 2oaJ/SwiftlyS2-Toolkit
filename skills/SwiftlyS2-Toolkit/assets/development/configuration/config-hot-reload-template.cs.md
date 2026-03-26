# SwiftlyS2 Config 热加载模板

对应官方文档：
- `Configuration`
- `Dependency Injection`

适用于：任何需要运行时修改配置并自动生效的 SwiftlyS2 插件。

## 设计要点

- 使用 `Core.Configuration.InitializeJsonWithModel<T>()` 初始化配置。
- 使用 `IOptionsMonitor<T>.OnChange()` 监听变更，实现热加载。
- Config 类建议定义在单独文件 `Config.cs` 中。
- JSONC 格式（`config.jsonc`）支持注释，便于维护。
- 热加载回调中可触发缓存刷新、Scheduler 重启、状态重置等副作用。

## 配置定义

```csharp
namespace MyNamespace;

public class Config
{
    // 基础类型
    public bool Enabled { get; set; } = true;
    public int MaxRetries { get; set; } = 3;
    public float UpdateInterval { get; set; } = 1.0f;
    public string ServerName { get; set; } = "Default";

    // 数组/列表
    public string[] AllowedMaps { get; set; } = [];

    // 嵌套对象
    public RewardConfig Reward { get; set; } = new();
}

public class RewardConfig
{
    public int BaseAmount { get; set; } = 100;
    public float Multiplier { get; set; } = 1.0f;
}
```

## 初始化与热加载

```csharp
public partial class MyPlugin(ISwiftlyCore core) : BasePlugin(core)
{
    private Config Config { get; set; } = new();

    public override void Load(bool hotReload)
    {
        // 1. 初始化配置（创建默认文件 + 注册变更监听来源）
        Core.Configuration.InitializeJsonWithModel<Config>("config.jsonc", "Main")
            .Configure(builder => builder.AddJsonFile("config.jsonc", optional: false, reloadOnChange: true));

        // 2. 获取 IOptionsMonitor
        // 前提：需先通过 ServiceCollection + AddOptionsWithValidateOnStart<Config>().BindConfiguration("Main") 注册
        // DI 插件骨架详见：../../guides/dependency-injection/di-service-plugin-template.cs.md
        var monitor = ServiceProvider.GetRequiredService<IOptionsMonitor<Config>>();
        Config = monitor.CurrentValue;

        // 3. 注册热加载回调
        monitor.OnChange(OnConfigChanged);

        // 4. 使用 Config 初始化业务
        if (Config.Enabled)
        {
            StartFeature();
        }
    }

    private void OnConfigChanged(Config newConfig)
    {
        var oldConfig = Config;
        Config = newConfig;

        // 按需触发副作用
        if (oldConfig.Enabled != newConfig.Enabled)
        {
            if (newConfig.Enabled)
                StartFeature();
            else
                StopFeature();
        }

        if (Math.Abs(oldConfig.UpdateInterval - newConfig.UpdateInterval) > 0.001f)
        {
            RestartScheduler(newConfig.UpdateInterval);
        }

        Core.Logger.LogInformation("配置已热加载");
    }
}
```

## Checklist

- [ ] Config 类字段是否都有合理默认值？
- [ ] 是否使用 `config.jsonc` 格式（支持注释）？
- [ ] 是否通过 `IOptionsMonitor<T>.OnChange()` 监听变更？
- [ ] 热加载回调中是否正确处理新旧配置的差异？
- [ ] 复杂副作用（Scheduler 重启、缓存清理）是否在回调中正确触发？
- [ ] 是否避免在热加载回调中做阻塞 IO？
