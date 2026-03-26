# SwiftlyS2 Thread Sensitivity Checklist

对应官方文档：
- `Thread Safety`
- `Using attributes`
- `Menus`

> 用途：检查线程敏感 API、异步上下文写法、scheduler 使用动机，以及 player / entity 生命周期风险。

## 一、先判断当前代码处在什么上下文

- 是命令入口、菜单回调、事件回调、hook、worker 还是延迟任务？
- 当前代码是否已经是 `async` / `await` 链路？
- 是否运行在高频热路径？
- 是否可能跨线程、跨帧、跨 map、跨断线重连？

## 二、若处于异步上下文，优先检查是否已有 Async API

优先使用：
- `PrintToChatAsync`
- `PrintToConsoleAsync`
- `ReplyAsync`
- `EmitSoundFilterAsync`
- `SetModelAsync`
- `AcceptInputAsync`
- `KickAsync`
- `SwitchTeamAsync`

硬规则：
- **若 Async API 已存在，且当前已在异步上下文中，优先直接使用 Async API。**
- **不要把 `NextTick` / `NextWorldUpdate` 当成线程敏感问题的默认解法。**

## 三、已知重点线程敏感方法清单

- `IPlayer.Send* / Kick / ChangeTeam / SwitchTeam / TakeDamage / Teleport / ExecuteCommand`
- `IGameEventService.Fire*`
- `IEngineService.ExecuteCommand*`
- `CEntityInstance.AcceptInput / AddEntityIOEvent / DispatchSpawn / Despawn`
- `ICommandContext.Reply`
- `CBaseModelEntity.SetModel / SetBodygroupByName`
- `CCSPlayerController.Respawn`
- `CPlayer_ItemServices.* / CPlayer_WeaponServices.*`

## 四、菜单回调是重点高危区

- `ButtonMenuOption.Click`
- `ToggleMenuOption.ValueChanged`
- `ChoiceMenuOption.ValueChanged`
- `SliderMenuOption.ValueChanged`
- `SubmenuMenuOption(async () => ...)`

复核问题：
- 回调内部是否优先使用 `Async` API？
- 是否跨 `await` 后重新检查 `args.Player.Valid()`？
- 是否避免在回调里做阻塞 IO / `.Wait()` / `.Result`？
- **回调中是否涉及实体创建/销毁、Schema 属性写回、模型操作？若是，是否已用 `Core.Scheduler.NextWorldUpdate()` 派发回主线程？**
- **`NextWorldUpdate` 回调内是否再次校验了 player / pawn 有效性？**

### 菜单回调主线程派发规则

菜单回调是 `async` 委托。以下操作**必须**包装在 `NextWorldUpdate` 中执行：

- 创建 / 销毁实体
- 写入 Schema 属性 + 调用 `*Updated()`
- `SetModel` / `AcceptInput` / `Teleport` / `Respawn` / `ExecuteCommand` 等主线程同步 API
- 任何直接操作 pawn / controller 游戏状态的代码

> ⚠️ 若该方法存在 Async 版本（如 `SetModelAsync`、`AcceptInputAsync`、`TeleportAsync`、`RespawnAsync`），在异步上下文中可直接使用 Async 版本而无需 `NextWorldUpdate`。

以下操作**不需要** `NextWorldUpdate`：

- `PrintToChatAsync` 等已有 Async API
- 线程安全容器读写
- 纯异步 IO（HTTP、数据库）

```csharp
// ✅ 正确：异步回调中通过 NextWorldUpdate 操作实体
btn.Click += async (sender, args) =>
{
    var p = args.Player;
    if (!p.Valid()) return;

    Core.Scheduler.NextWorldUpdate(() =>
    {
        if (!p.Valid()) return; // 再次校验
        runtimeService.StartAction(p);
    });
};
```

## 五、player / entity 生命周期复核

- `player != null && player.Valid()`
- `player.PlayerPawn != null`
- `pawn.Valid()` / `pawn.IsValid`
- map 是否已切换
- 当前运行态是否仍对应当前会话
- 跨 tick / 延迟长期持有实体时，是否改用 `CHandle<T>`？
