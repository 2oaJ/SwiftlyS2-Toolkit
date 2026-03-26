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

## 五、player / entity 生命周期复核

- `player != null && player.Valid()`
- `player.PlayerPawn != null`
- `pawn.Valid()` / `pawn.IsValid`
- map 是否已切换
- 当前运行态是否仍对应当前会话
- 跨 tick / 延迟长期持有实体时，是否改用 `CHandle<T>`？
