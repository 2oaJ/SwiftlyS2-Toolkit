# SwiftlyS2 传统模块化插件模板

对应官方文档：
- `Getting Started`
- `Swiftly Core`
- `Using attributes`

适用于：模块化 gameplay 类、需要 `Commands / Events / Hooks / Modules / Workers` 的插件。

## 目录建议

```text
MyPlugin/
├── MyPlugin.cs
├── MyPlugin.Commands.cs
├── MyPlugin.Events.cs
├── MyPlugin.GameEvents.cs
├── MyPlugin.Functions.cs
├── Modules/
├── Workers/
├── Models/
├── Players/
├── Interfaces/
└── Helpers/
```

## 基本骨架

```csharp
using Microsoft.Extensions.Logging;
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
    public partial class MyPlugin(ISwiftlyCore core) : BasePlugin(core)
    {
        public override void Load(bool hotReload)
        {
            Core.Logger.LogInformation("MyPlugin 加载完成");
        }

        public override void Unload()
        {
            Core.Logger.LogInformation("MyPlugin 卸载完成");
        }
    }
}
```

## 约束

- 命令、事件、Hooks 不要直接堆业务逻辑，优先下沉到 module / service
- 高频路径严禁直接做 IO
- 涉及玩家态时，尽早确定 SSOT 对象
- 小型 partial 项目中的少量 `Events` / `GameEvents` / `Hooks`，优先直接用 attribute 管理即可
- 若监听需要独立安装/卸载、动态开关或与 DI 生命周期强绑定，再升级为 service 自持监听模式
