# SwiftlyS2 Game Events 使用说明

对应官方文档：
- `Game Events`
- `Core Events`

## 关键提醒

- 官网已明确说明：Source 2 中很多 game event 已经偏废弃，部分事件并不可靠。
- 因此：
  - 若你只是需要玩家 / 地图 / 实体 / tick 生命周期，优先先看 `Core Events`
  - 若你需要 typed entity / movement / controller / pawn / weapon hook，优先看 `Core.GameHooks`，不要继续使用已废弃的 `Core.Event.On*Hook`
  - 只有在确认目标 Game Event 确实存在且行为已验证时，才使用 `Game Events`

## 适用场景

- 已确认可用的 typed game event fire / hook
- 某些客户端或服务端事件需要沿用现成 Game Event 定义

## 不适用场景

- 想找稳定生命周期入口
- 想监听 map / player attach / disconnect / 高频运行态
- 不确定某事件在 Source 2 当前版本是否仍然工作

## 建议路线

1. 先问：我需要的是 Game Event、Core Event，还是 GameHooks？
2. 若是稳定生命周期监听，先去 `../core-events/lifecycle-checklist.md`
3. 若是 typed native hook，先去 `../game-hooks/game-hooks-pre-post-guide.md`
4. 若确需 Game Event，再回官方 `Game Events` + API Reference 深挖

## Pre vs Post Hook 选择

### `[GameEventHandler(HookMode.Pre)]`

- 事件生效**前**触发
- 可返回 `HookResult.Stop` 拦截事件传播
- 适合：
  - 阻止某些行为（如阻止特定武器购买）
  - 在事件影响游戏前做条件判断
  - 修改事件参数

### `[GameEventHandler(HookMode.Post)]`

- 事件生效**后**触发
- 适合：
  - 基于事件结果做统计、记录、奖励
  - 状态更新（玩家死亡后处理尸体、显隐等）
  - 触发后续异步任务

### 注意事项

- Post Hook 中涉及实体操作时，常需 `NextTick` / `DelayBySeconds` 等待状态稳定
- 不确定用 Pre 还是 Post 时，优先选 Post（更安全，不影响事件传播）
- Pre Hook 中的 `HookResult.Stop` 要谨慎使用（会影响其他插件收到该事件）
- `HookResult.Handled` 和 `HookResult.Stop` 不适用于 Post 的取消控制；Post 只用于观察已发生的事件

```csharp
// Pre Hook 示例：条件性拦截
[GameEventHandler(HookMode.Pre)]
public HookResult OnPlayerHurt(EventPlayerHurt @event)
{
    if (ShouldIgnore(@event))
        return HookResult.Stop;
    return HookResult.Continue;
}

// Post Hook 示例：延迟处理
[GameEventHandler(HookMode.Post)]
public HookResult OnPlayerDeath(EventPlayerDeath @event)
{
    var victim = @event.UserIdPlayer;
    if (victim is null || !victim.IsValid) return HookResult.Continue;

    // 只保存稳定会话标识；不要把当前 IPlayer 捕获进延迟回调。
    var sessionId = victim.SessionId;

    Core.Scheduler.DelayBySeconds(0.5f, () =>
    {
        var currentVictim = Core.PlayerManager.GetPlayerFromSessionId(sessionId);
        if (currentVictim is null || !currentVictim.IsValid)
        {
            return;
        }

        ProcessDeathEffects(currentVictim);
    });
    return HookResult.Continue;
}
```

## 动态注册与清理

固定监听可用 `[GameEventHandler]`。需要由 service 动态启停时，保存 API 返回的 `Guid` 并精确取消：

```csharp
private Guid _playerDeathPre;
private Guid _playerDeathPost;

public void Install()
{
    _playerDeathPre = Core.GameEvent.HookPre<EventPlayerDeath>(OnPlayerDeathPre);
    _playerDeathPost = Core.GameEvent.HookPost<EventPlayerDeath>(OnPlayerDeathPost);
}

public void Uninstall()
{
    if (_playerDeathPre != Guid.Empty)
    {
        Core.GameEvent.Unhook(_playerDeathPre);
        _playerDeathPre = Guid.Empty;
    }

    if (_playerDeathPost != Guid.Empty)
    {
        Core.GameEvent.Unhook(_playerDeathPost);
        _playerDeathPost = Guid.Empty;
    }
}
```

批量移除同一 event type 时可使用 `UnhookPre<T>()` / `UnhookPost<T>()`，但不能用它替代明确的 owning-service 生命周期管理。

## 临时对象、Accessor 与异步 fire

- hook callback 的 `@event` 与 `@event.Accessor` 仅在当前 callback 内有效；需要延迟处理时复制普通字段、`SessionId` 或 `CHandle<T>`。
- fire 配置 lambda 中的 `@event` 也只在 lambda 内有效。
- 非主线程 fire 使用并 await `FireAsync<T>`、`FireToPlayerAsync<T>` 或 `FireToServerAsync<T>`。
- typed 属性优先；只有字段级诊断或生成类型未覆盖时才使用 `Accessor`。`DontBroadcast` 控制该 event 是否广播给客户端。
- 使用前可用 `IsListeningToEvent(...)` 确认目标 player slot 是否监听对应 event。

## Checklist

- [ ] 是否已在目标服务器验证当前 Game Event 实际存在且可靠？
- [ ] attribute 或动态 hook 是否有明确所有权和反注册路径？
- [ ] 是否没有让 event / accessor / player wrapper 跨 callback 或 async 边界？
- [ ] 是否正确选择 Pre/Post，且仅在 Pre 中依赖取消行为？
