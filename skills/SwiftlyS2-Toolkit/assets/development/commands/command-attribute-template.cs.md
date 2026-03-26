# SwiftlyS2 Attribute 命令模板

对应官方文档：
- `Commands`
- `Using attributes`
- `Thread Safety`

适用于：partial / 小型插件中，使用 `[Command]`、`[CommandAlias]` 声明固定命令入口。

## 适用原则

- 命令层负责入口、权限、参数校验、玩家反馈
- 复杂业务逻辑下沉到 module / service
- 若未来需要动态挂卸、条件启停、精确回收，考虑改为程序化注册

## 示例骨架

```csharp
using SwiftlyS2.Shared.Commands;
using SwiftlyS2.Shared.Core.Attributes.Commands;

namespace MyNamespace;

public partial class MyPlugin
{
    [Command("mycommand", permission: "myplugin.commands.use")]
    [CommandAlias("mc")]
    public void OnMyCommand(ICommandContext context)
    {
        if (!context.IsSentByPlayer || context.Sender is null || !context.Sender.IsValid)
        {
            context.Reply("[插件] 该命令只能由有效玩家执行。");
            return;
        }

        var args = context.Arguments;
        if (args.Count < 2)
        {
            context.Reply("[插件] 参数错误，请检查输入格式。");
            return;
        }

        var parsedArg = args[1].Trim();
        if (string.IsNullOrWhiteSpace(parsedArg))
        {
            context.Reply("[插件] 参数不能为空。");
            return;
        }

        var success = _myFeatureService.TryHandlePlayerAction(context.Sender.SteamID, parsedArg);
        if (!success)
        {
            context.Reply("[插件] 当前无法执行该操作。");
            return;
        }

        context.Reply("[插件] 操作执行成功。");
    }
}
```

## Checklist

- 是否采用 `[Command]` / `[CommandAlias]`，而不是误用程序化注册？
- 是否先校验 `context.IsSentByPlayer`、`context.Sender`、`Sender.IsValid`？
- 是否保留权限语义与 alias 语义？
- 是否避免在命令入口直接写跨模块内部状态？
