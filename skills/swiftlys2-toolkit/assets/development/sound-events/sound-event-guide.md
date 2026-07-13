# SwiftlyS2 SoundEvent 指南

对应官方文档：`Sound Events`、`Thread Safety`。

`SoundEvent` 是一次性可配置的声音事件对象。它实现 `IDisposable`，应在发送的同一作用域内释放。

## 广播与指定接收者

```csharp
using SwiftlyS2.Shared.Sounds;

using var sound = new SoundEvent("UI.CounterBeep", volume: 1.0f, pitch: 1.0f);
sound.SourceEntityIndex = -1;
sound.Recipients.AddAllPlayers();

uint guid = sound.Emit();
```

```csharp
using SwiftlyS2.Shared.Sounds;

using var sound = new SoundEvent("UI.CounterBeep");
sound.Recipients.RemoveAllPlayers();
sound.Recipients.AddRecipient(player.PlayerID);
sound.SetFloat3("public.position", position);
sound.Emit();
```

`SourceEntityIndex = -1` 表示使用接收者位置。已有实体时可使用 `SetSourceEntity(entity)`。字段级自定义使用 `SetBool`、`SetInt32`、`SetUInt32`、`SetFloat`、`SetFloat3` 等 typed API。

## 线程规则

- 主线程调用 `Emit()`。
- 非主线程或无法保证线程上下文时，使用并 await `EmitAsync()`。
- 除紧邻 `await sound.EmitAsync()` 外，不要将 `SoundEvent`、它的 recipient filter 或 entity wrapper 保存并交给其他 async continuation / worker。

## Checklist

- [ ] 是否用 `using` 释放 SoundEvent？
- [ ] 是否明确接收者，避免误广播？
- [ ] 是否正确选择 `Emit` / `EmitAsync`？
- [ ] 是否只使用当前游戏版本已验证的 sound event name 与字段？
