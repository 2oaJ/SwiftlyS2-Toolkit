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

## 示例骨架

```csharp
using SwiftlyS2.Shared.Protobufs;

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
        using var message = Core.NetMessage.Create<MyTypedMessage>();
        message.SetIntValue(1);
        message.SetStringValue("payload");
        message.Recipients.AddAllPlayers();
        message.Send();
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

## Checklist

- 是否在主线程读取/写入 protobuf？
- 是否在异步前完成快照化？
- 是否避免跨线程传递 protobuf handle？
- 是否优先使用 typed API？
- 是否考虑 usercmd / subtick 时序一致性？
