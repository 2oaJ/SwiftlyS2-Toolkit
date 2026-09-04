# SwiftlyS2 OnPrecacheResource 模板

对应官方文档：
- `Core Events`

适用于：预加载模型、声音、粒子等资源，确保运行时可用。

## 为什么需要 Precache

在 Source 2 中，模型、粒子、声音事件等资源必须在使用前 precache。
未 precache 的资源在 `SetModel`、`EmitSound` 等调用时会静默失败或崩溃。

## 基本模式

```csharp
[EventListener<OnPrecacheResource>]
public void OnPrecacheResource(IOnPrecacheResourceEvent @event)
{
    // 静态资源
    @event.AddItem("characters/models/my_custom_model.vmdl");
    @event.AddItem("soundevents/soundevents_custom.vsndevts");
    @event.AddItem("particles/my_particle_effect.vpcf");
}
```

## 配置驱动的动态 Precache

当资源路径来自配置文件或数据库时，需要动态预加载：

```csharp
[EventListener<OnPrecacheResource>]
public void OnPrecacheResource(IOnPrecacheResourceEvent @event)
{
    // 从配置中收集所有模型路径
    foreach (var skin in Config.Skins)
    {
        if (!string.IsNullOrWhiteSpace(skin.ModelPath))
            @event.AddItem(skin.ModelPath);

        if (!string.IsNullOrWhiteSpace(skin.SoundPath))
            @event.AddItem(skin.SoundPath);
    }
}
```

## 服务委托 Precache

当多个服务各自有资源需要 precache 时：

```csharp
[EventListener<OnPrecacheResource>]
public void OnPrecacheResource(IOnPrecacheResourceEvent @event)
{
    // 统一入口资源
    @event.AddItem("soundevents/soundevents_plugin.vsndevts");

    // 委托工厂管理的各服务
    if (_serviceProvider is not null)
    {
        foreach (var service in _serviceProvider.GetServices<IMyService>())
        {
            try
            {
                service.OnPrecacheResource(@event);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "预加载资源失败 - 服务: {Service}", service.GetType().Name);
            }
        }
    }
}
```

## 关键点

- `OnPrecacheResource` 在地图加载早期触发，此时部分服务可能尚未完全初始化
- 资源路径字符串必须精确匹配游戏内实际路径
- 重复添加同一路径是安全的（引擎会去重）
- 配置驱动的资源列表变化后，需要下一次 map load 才能生效
- 不要在此事件中做 IO 或阻塞操作

## Checklist

- [ ] 插件使用的所有自定义模型是否都在 `OnPrecacheResource` 中注册？
- [ ] 声音事件文件（`.vsndevts`）是否已注册？
- [ ] 粒子效果（`.vpcf`）是否已注册？
- [ ] 配置驱动的动态资源是否已遍历注册？
- [ ] 服务委托 precache 是否有异常保护？
