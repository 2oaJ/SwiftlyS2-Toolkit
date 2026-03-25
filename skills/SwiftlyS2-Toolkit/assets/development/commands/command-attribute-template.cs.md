# SwiftlyS2 Attribute Command Template

Official docs sections:
- `Commands`
- `Using attributes`
- `Thread Safety`

Suitable for: partial / small plugins that use `[Command]` and `[CommandAlias]` to declare fixed command entry points.

## Usage principles

- The command layer should own the entry point, permissions, argument validation, and player feedback.
- Complex business logic should be pushed down into modules or services.
- If the feature later needs dynamic install / uninstall, conditional start / stop, or precise cleanup, consider switching to programmatic registration.

## Example skeleton

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
            context.Reply("[Plugin] This command can only be executed by a valid player.");
            return;
        }

        var args = context.Arguments;
        if (args.Count < 2)
        {
            context.Reply("[Plugin] Invalid arguments. Please check the input format.");
            return;
        }

        var parsedArg = args[1].Trim();
        if (string.IsNullOrWhiteSpace(parsedArg))
        {
            context.Reply("[Plugin] The argument cannot be empty.");
            return;
        }

        var success = _myFeatureService.TryHandlePlayerAction(context.Sender.SteamID, parsedArg);
        if (!success)
        {
            context.Reply("[Plugin] This operation cannot be executed right now.");
            return;
        }

        context.Reply("[Plugin] Operation completed successfully.");
    }
}
```

## Checklist

- Are `[Command]` / `[CommandAlias]` being used appropriately instead of mistakenly using programmatic registration?
- Are `context.IsSentByPlayer`, `context.Sender`, and `Sender.IsValid` validated first?
- Are the permission semantics and alias semantics preserved?
- Does the command entry avoid directly writing cross-module internal state?
