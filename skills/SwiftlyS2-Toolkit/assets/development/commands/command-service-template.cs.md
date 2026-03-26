# SwiftlyS2 Service 自持命令模板

对应官方文档：
- `Commands`
- `Dependency Injection`
- `Thread Safety`

适用于：由 service 自己持有命令 / alias / client chat hook / client command hook 生命周期的场景。

## 适用原则

- root 负责装配 service，不代管局部命令句柄
- service 注册了什么，就由该 service 自己卸载什么
- 需要动态启停、保存 `Guid`、条件挂卸时，优先选择这一模式

## 示例骨架

```csharp
using System;
using SwiftlyS2.Shared;
using SwiftlyS2.Shared.Commands;
using SwiftlyS2.Shared.Misc;

namespace MyNamespace.Impl;

public sealed class MyCommandService(ISwiftlyCore core) : IMyCommandService
{
    private Guid _commandGuid;
    private Guid _clientChatHookGuid;
    private bool _installed;

    public void Install()
    {
        if (_installed)
        {
            return;
        }

        _commandGuid = core.Command.RegisterCommand(
            "mycommand",
            OnMyCommand,
            registerRaw: false,
            permission: "myplugin.commands.use",
            helpText: "我的模块命令");

        core.Command.RegisterCommandAlias("mycommand", "mc");
        _clientChatHookGuid = core.Command.HookClientChat(OnClientChat);
        _installed = true;
    }

    public void Uninstall()
    {
        if (!_installed)
        {
            return;
        }

        core.Command.UnregisterCommand(_commandGuid);
        core.Command.UnhookClientChat(_clientChatHookGuid);
        _installed = false;
    }

    private void OnMyCommand(ICommandContext context)
    {
        context.Reply("[插件] 命令已触发。");
    }

    private HookResult OnClientChat(int playerId, string text, bool teamonly)
    {
        return HookResult.Continue;
    }
}
```

## Checklist

- 是否由 owning service 保存 `Guid` 并在 `Uninstall()` 精确回收？
- 是否真的需要动态启停或独立生命周期？
- 是否把命令实现和命令注册放在同一个 service 中闭环？
- 是否区分 `RegisterCommandAlias`、`HookClientChat`、`HookClientCommand` 的不同卸载路径？
