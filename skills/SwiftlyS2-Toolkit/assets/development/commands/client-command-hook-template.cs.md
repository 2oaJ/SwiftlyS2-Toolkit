# SwiftlyS2 ClientCommandHookHandler 模板

对应官方文档：
- `Commands`
- `Native Functions and Hooks`

适用于：拦截客户端发送的原始命令（如 jointeam、radio 命令等），在命令到达正常处理流程前决定放行或拦截。

## 适用场景

- 拦截并限制 `jointeam`（禁止非管理员切观察者）
- 拦截并替换无线电命令（自定义 cheer、roger 等行为）
- 拦截购买命令
- 任何需要在命令层面全局拦截的场景

## 基本模式

```csharp
using SwiftlyS2.Shared.Hooks;

namespace MyNamespace;

public partial class MyPlugin
{
    // 1. 可选：声明式注册命令（确保底层识别）
    [Command("jointeam", registerRaw: true)]
    public void OnJoinTeamCommand(ICommandContext context) { }

    // 2. 安装全局命令拦截 Hook
    [ClientCommandHookHandler]
    public HookResult OnClientCommandHook(int playerId, string commandLine)
    {
        // 快速分流：只处理关心的命令
        if (!commandLine.StartsWith("jointeam"))
            return HookResult.Continue;

        var player = Core.PlayerManager.GetPlayer(playerId);
        if (player is null || !player.IsValid)
            return HookResult.Continue;

        // 示例：禁止非管理员切观察者
        if (commandLine.StartsWith("jointeam 1")
            && !Core.Permission.PlayerHasPermission(player.SteamID, "admin.spectate"))
        {
            player.SendMessage(MessageType.Chat, "[插件] 非管理员无法切换到观察者");
            return HookResult.Stop;  // 拦截命令
        }

        return HookResult.Continue;  // 放行
    }
}
```

## 多命令拦截模式

```csharp
private static readonly HashSet<string> InterceptedCommands =
    ["roger", "negative", "cheer", "thanks", "holdpos", "followme"];

[Command("roger", registerRaw: true)]
[CommandAlias("negative", registerRaw: true)]
[CommandAlias("cheer", registerRaw: true)]
[CommandAlias("thanks", registerRaw: true)]
[CommandAlias("holdpos", registerRaw: true)]
[CommandAlias("followme", registerRaw: true)]
public void OnRadioCommand(ICommandContext context) { }

[ClientCommandHookHandler]
public HookResult OnClientCommandHook(int playerId, string commandLine)
{
    // 提取命令名
    var spaceIndex = commandLine.IndexOf(' ');
    var commandName = spaceIndex < 0 ? commandLine : commandLine[..spaceIndex];

    if (!InterceptedCommands.Contains(commandName))
        return HookResult.Continue;

    var player = Core.PlayerManager.GetPlayer(playerId);
    if (player is null || !player.IsValid)
        return HookResult.Continue;

    // 按命令名分发
    return commandName switch
    {
        "cheer" => HandleCheerCommand(player),
        _ => HookResult.Continue
    };
}
```

## 关键点

- `registerRaw: true` 确保命令在底层被识别，`ClientCommandHookHandler` 才能正确拦截
- `HookResult.Stop` 完全阻止命令继续传播
- `HookResult.Continue` 让命令正常执行
- commandLine 是原始字符串，需自行解析参数
- 该 Hook 在命令处理流水线的最早期，`ICommandContext` 等高级包装可能尚不可用
- 高频命令（如移动类）的拦截要注意性能

## Checklist

- [ ] 是否尽早过滤不关心的命令（避免每个命令都走完整逻辑）？
- [ ] 是否在 Hook 内先校验 `player is not null && player.IsValid`？
- [ ] 需要 `registerRaw: true` 的命令是否都已声明？
- [ ] `HookResult.Stop` 是否只用于确实需要拦截的场景？
- [ ] 参数解析是否安全处理了空参数/异常格式？
