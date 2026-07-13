# SwiftlyS2 Service 模板

对应官方文档：
- `Dependency Injection`
- `Swiftly Core`
- `Thread Safety`

适用于：抽取共享业务逻辑、外部依赖集成、模块间复用能力，以及 DI / service 或混合架构下的 service 层。

## 目录建议

```text
Interface/
└── IMyFeatureService.cs

Impl/
└── MyFeatureService.cs
```

## 接口示例

```csharp
namespace MyNamespace.Interface;

public interface IMyFeatureService
{
    void Install();
    void Uninstall();
    bool TryHandlePlayerAction(ulong steamId);
}
```

## 实现示例

```csharp
using System;
using Microsoft.Extensions.Logging;
using MyNamespace.Interface;
using SwiftlyS2.Shared;
using SwiftlyS2.Shared.Commands;
using SwiftlyS2.Shared.Events;
using SwiftlyS2.Shared.GameHooks;
using SwiftlyS2.Shared.Misc;

namespace MyNamespace.Impl;

public sealed class MyFeatureService(ISwiftlyCore core, ILogger<MyFeatureService> logger) : IMyFeatureService
{
    private readonly ISwiftlyCore _core = core;
    private readonly ILogger<MyFeatureService> _logger = logger;
    private bool _installed;
    private bool _runtimeHooked;
    private Guid _commandGuid;
    private Guid _clientCommandHookGuid;

    public void Install()
    {
        if (_installed)
        {
            return;
        }

        _core.Event.OnConVarValueChanged += OnConVarValueChanged;
        _commandGuid = _core.Command.RegisterCommand("myfeature", OnMyFeatureCommand, helpText: "MyFeatureService 命令");
        _clientCommandHookGuid = _core.Command.HookClientCommand(OnClientCommand);
        _installed = true;
        _logger.LogInformation("MyFeatureService 安装完成");
    }

    public void Uninstall()
    {
        if (!_installed)
        {
            return;
        }

        _core.Event.OnConVarValueChanged -= OnConVarValueChanged;
        _core.Command.UnregisterCommand(_commandGuid);
        _core.Command.UnhookClientCommand(_clientCommandHookGuid);
        UnhookRuntimeEvent();
        _installed = false;
        _logger.LogInformation("MyFeatureService 卸载完成");
    }

    public bool TryHandlePlayerAction(ulong steamId)
    {
        return _installed;
    }

    private void OnConVarValueChanged(IOnConVarValueChanged @event)
    {
        EnsureRuntimeEventHooked();
    }

    private void EnsureRuntimeEventHooked()
    {
        if (_runtimeHooked)
        {
            return;
        }

        _core.GameHooks.Controller.ProcessUsercmds.Pre += OnProcessUsercmdsPre;
        _runtimeHooked = true;
    }

    private void UnhookRuntimeEvent()
    {
        if (!_runtimeHooked)
        {
            return;
        }

        _core.GameHooks.Controller.ProcessUsercmds.Pre -= OnProcessUsercmdsPre;
        _runtimeHooked = false;
    }

    private void OnProcessUsercmdsPre(ref ProcessUsercmdsPreContext ctx)
    {
        var player = ctx.Params.Player;
        if (!player.IsValid || player.IsFakeClient)
        {
            return;
        }

        // 只在同步回调内读取 ctx；不要让 context 或 Usercmds 跨 async/worker 边界。
    }

    private void OnMyFeatureCommand(ICommandContext context)
    {
    }

    private HookResult OnClientCommand(int playerId, string commandLine)
    {
        return HookResult.Continue;
    }
}
```

## Checklist

- 是否有清晰接口边界
- 是否具备 Install / Uninstall 或 Initialize / Cleanup 闭环
- 是否由 owning service 自己注册并清理命令、事件、Hook
- 是否避免长期持有会失效的 `IPlayer` / entity wrapper
- typed runtime hook 是否优先使用 `Core.GameHooks`，并以 `+=` / `-=` 在 service 内闭环？
