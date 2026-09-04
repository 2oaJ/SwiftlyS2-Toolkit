# SwiftlyS2 Protobuf / NetMessage 模板

对应官方文档：
- `Network Messages`
- `Thread Safety`

适用于：`CSGOUserCmdPB`、typed netmessage、用户消息 hook、命令快照采样。

## 适用原则

- protobuf / usercmd 读写默认按主线程敏感处理
- 进入异步线程前，优先快照化为普通 C# 模型
- 不要把 protobuf handle / entity handle 直接跨线程传递
- typed protobuf / typed netmessage 优先于硬编码 message id
- hook callback 中的 `msg` 和 `msg.Accessor` 是临时 wrapper，只能在当前回调读取或复制，不能缓存

## 示例骨架

```csharp
using SwiftlyS2.Shared.Misc;
using SwiftlyS2.Shared.ProtobufDefinitions;

namespace MyNamespace;

public partial class MyPlugin
{
    public void HandleUserCmd(ulong steamId, CSGOUserCmdPB userCmd)
    {
        var snapshot = new UserCmdSnapshot(
            steamId,
            userCmd.Buttons,
            userCmd.Viewangles?.X ?? 0f,
            userCmd.Viewangles?.Y ?? 0f,
            userCmd.ForwardMove,
            userCmd.SideMove);

        _commandRecordingWorker.Enqueue(snapshot);
    }

    public void SendCustomMessage()
    {
        Core.NetMessage.Send<CUserMessageShake>(message =>
        {
            message.Duration = 1.0f;
            message.Frequency = 2.0f;
            message.Amplitude = 0.5f;
            message.Command = 0;
            message.Recipients.AddAllPlayers();
        });
    }
}

public sealed record UserCmdSnapshot(
    ulong SteamId,
    int Buttons,
    float Pitch,
    float Yaw,
    float ForwardMove,
    float SideMove);
```

## 发送模式

短的一次性消息使用 `Send<T>(configure)`。需要复用同一实例或自定义收件人时使用 `Create<T>()`，并在同一作用域 dispose：

```csharp
using var message = Core.NetMessage.Create<CUserMessageShake>();
message.Duration = 1.0f;
message.Frequency = 2.0f;
message.Amplitude = 0.5f;
message.Command = 0;

message.Recipients.RemoveAllPlayers();
message.Recipients.AddRecipient(playerId);
message.Send();
```

也可以使用 `SendToAllPlayers()` 或 `SendToPlayer(playerId)`。不要持久化 `INetMessage<T>` 到 worker 或下一帧。

## 接收管线与注销

| 管线 | 程序化 API | handler 形状 | `Stop` 含义 |
| --- | --- | --- | --- |
| client -> server | `HookClientMessage<T>` | `HookResult Handler(T msg, int playerId)` | 阻止消息到达服务器 |
| server -> client | `HookServerMessage<T>` | `HookResult Handler(T msg)` | 阻止消息发往客户端 |
| internal server -> client | `HookServerMessageInternal<T>` | `HookResult Handler(T msg, int playerId)` | 阻止该内部管线投递；不是所有 server 消息都会经过该管线 |

```csharp
private Guid _clientMoveHook;

public void Install()
{
    _clientMoveHook = Core.NetMessage.HookClientMessage<CCLCMsg_Move>(OnClientMove);
}

public void Uninstall()
{
    if (_clientMoveHook != Guid.Empty)
    {
        Core.NetMessage.Unhook(_clientMoveHook);
        _clientMoveHook = Guid.Empty;
    }
}

private HookResult OnClientMove(CCLCMsg_Move msg, int playerId)
{
    var lastCommandNumber = msg.LastCommandNumber;
    QueueSnapshot(playerId, lastCommandNumber);
    return HookResult.Continue;
}
```

声明式注册分别使用 `[ClientNetMessageHandler]`、`[ServerNetMessageHandler]`、`[ServerNetMessageInternalHandler]`。它们所在的对象必须已被 framework 注册。批量移除同型 hook 时才使用 `UnhookClientMessage<T>`、`UnhookServerMessage<T>` 或 `UnhookServerMessageInternal<T>`。

## Typed 属性与 Accessor

先使用 generated typed 属性。只有需要字段级兜底或诊断时才使用 `Accessor`：

```csharp
private HookResult OnServerSound(CMsgSosStartSoundEvent msg)
{
    uint soundHash = msg.SoundeventHash;
    if (msg.Accessor.HasField("soundevent_hash"))
    {
        soundHash = msg.Accessor.GetUInt32("soundevent_hash");
    }

    RecordSoundHash(soundHash);
    return HookResult.Continue;
}
```

## Checklist

- 是否在主线程读取/写入 protobuf？
- 是否在异步前完成快照化？
- 是否避免跨线程传递 protobuf handle？
- 是否优先使用 typed API？
- 是否考虑 usercmd / subtick 时序一致性？
- 是否根据方向选择 client/server/internal hook，并在 owner 卸载时精确 `Unhook(Guid)`？
- 是否只复制普通值到异步任务，而没有保存 `msg`、`Accessor` 或 protobuf wrapper？
