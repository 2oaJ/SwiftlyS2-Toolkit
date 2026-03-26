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

## 关键约束

### 处理器返回类型必须是 `void`

`[Command]` 属性对应的处理器签名必须保持为 `void OnMyCommand(ICommandContext context)`。不要把入口改成 `async ValueTask`、`async Task` 或其它异步返回类型。底层委托类型是 `delegate void CommandListener(ICommandContext context);`。

如果命令处理过程中确实需要异步工作，可以在 `void` 处理器内部触发一个 fire-and-forget 的异步方法，但入口本身必须保持 `void`。

### `[CommandAlias]` 只是短别名，不是前缀变体

`[CommandAlias("mc")]` 的作用是给玩家一个更短、更好记的替代命令名，例如 `!mc` 替代 `!mycommand`。它**不是**用来添加框架前缀、命名空间分组或 `sw_` 之类的系统标记。

别名应该是命令名的短缩写或常见替代叫法，而不是一套额外的命名规则。

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

- 处理器返回类型是否为 `void`（而不是 `async ValueTask`、`async Task` 或其它异步返回类型）？
- 是否正确使用 `[Command]` / `[CommandAlias]`，而不是误用程序化注册？
- `[CommandAlias]` 是否只用于短别名，而不是前缀或命名空间标记？
- 是否先校验 `context.IsSentByPlayer`、`context.Sender`、`Sender.IsValid`？
- 是否保留权限语义与 alias 语义？
- 是否避免在命令入口直接写跨模块内部状态？
