# SwiftlyS2 Game Events 使用说明

对应官方文档：
- `Game Events`
- `Core Events`

## 关键提醒

- 官网已明确说明：Source 2 中很多 game event 已经偏废弃，部分事件并不可靠。
- 因此：
  - 若你只是需要玩家 / 地图 / 实体 / tick 生命周期，优先先看 `Core Events`
  - 只有在确认目标 Game Event 确实存在且行为已验证时，才使用 `Game Events`

## 适用场景

- 已确认可用的 typed game event fire / hook
- 某些客户端或服务端事件需要沿用现成 Game Event 定义

## 不适用场景

- 想找稳定生命周期入口
- 想监听 map / player attach / disconnect / 高频运行态
- 不确定某事件在 Source 2 当前版本是否仍然工作

## 建议路线

1. 先问：我需要的是 Game Event，还是 Core Event？
2. 若是稳定生命周期监听，先去 `../core-events/lifecycle-checklist.md`
3. 若确需 Game Event，再回官方 `Game Events` + API Reference 深挖

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

    Core.Scheduler.DelayBySeconds(0.5f, () =>
    {
        // 延迟等待死亡状态稳定后操作
        ProcessDeathEffects(victim);
    });
    return HookResult.Continue;
}
```
