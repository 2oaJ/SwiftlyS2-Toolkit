# SwiftlyS2 异步安全模式指南

对应官方文档：
- `Thread Safety`
- `Scheduler`
- `Core Events`

适用于：异步回调、延迟任务、后台写回、generation 校验、CancellationToken 管理。

## 一、同步入口当 fire-and-forget

SwiftlyS2 常与同步入口（命令、事件回调、菜单回调）配合异步任务使用时，直接 `_ = SomeAsync()` 会吐掉异常。推荐在插件内定义一个小工具方法：

```csharp
// 在插件内定义一次，多处复用
private static async void FireAndForget(Task task, ILogger logger, string context)
{
    try { await task; }
    catch (Exception ex) { logger.LogError(ex, "[{Context}] 未观察到的异步异常", context); }
}

// 同步入口启动异步任务
[Command("mycommand")]
public void OnMyCommand(ICommandContext context)
{
    FireAndForget(OnMyCommandAsync(context), Logger, "MyPlugin.OnMyCommand");
}

private async Task OnMyCommandAsync(ICommandContext context)
{
    var player = context.Sender;
    if (player is null || !player.IsValid) return;

    var data = await FetchDataAsync(player.SteamID);
    // FireAndForget 会在异常时自动记录到 Logger
}
```

**关键点**：
- `FireAndForget` 是需要插件处自行实现的小工具，SW2 SDK 不内置此方法
- `async void` 次层捕获并记录异常，避免未观察任务异常导致进程崩溃
- 不要在 `FireAndForget` 之后对返回结果做操作

## 二、异步回调后重新校验 IPlayer

异步方法 `await` 之后，IPlayer 可能已经断线或换了人。必须重取并校验：

```csharp
private async Task HandleSomeActionAsync(IPlayer player)
{
    var steamId = player.SteamID;  // 先快照不可变标识

    var result = await SomeLongRunningCall(steamId);

    // 异步完成后重新获取玩家
    var currentPlayer = Core.PlayerManager.GetPlayerBySteamId(steamId);
    if (currentPlayer is null || !currentPlayer.IsValid)
    {
        Logger.LogDebug("玩家 {SteamId} 在异步期间断开", steamId);
        return;
    }

    await currentPlayer.SendMessageAsync(MessageType.Chat, $"结果: {result}");
}
```

## 三、StopOnMapChange + CancellationTokenSource

`Core.Scheduler.StopOnMapChange(cts)` 把 `CancellationTokenSource` 与地图生命周期绑定：

```csharp
private CancellationTokenSource? _mapCts;

[EventListener<OnMapLoad>]
public void OnMapLoad(IOnMapLoadEvent @event)
{
    _mapCts?.Cancel();
    _mapCts?.Dispose();
    _mapCts = new CancellationTokenSource();

    // 地图切换时自动 Cancel
    Core.Scheduler.StopOnMapChange(_mapCts);

    // Scheduler 注册的周期任务会被自动取消
    Core.Scheduler.RepeatBySeconds(1.0f, () => PeriodicTask(_mapCts.Token));
}

// 异步任务中使用 token 传播取消
private async Task LoadMapDataAsync(string mapName, CancellationToken cancellationToken)
{
    var data = await FetchMapDataAsync(mapName).ConfigureAwait(false);

    cancellationToken.ThrowIfCancellationRequested();

    // 确保不在已换图后继续操作
    ApplyMapData(data);
}
```

## 四、Generation Counter（异步回写代际校验）

当异步任务需要回写状态时，用 generation counter 防止回写到已过期的槽位：

```csharp
// 发起异步任务时捕获当前代际
private async Task SavePlayerRecordAsync(int slot, int capturedGeneration, RecordData data)
{
    await DatabaseService.SaveAsync(data).ConfigureAwait(false);

    // 回写前校验
    if (!_registry.ValidateGeneration(slot, capturedGeneration))
    {
        Logger.LogDebug("代际失效（slot={Slot}），丢弃回写", slot);
        return;
    }

    // 安全回写到主线程
    Core.Scheduler.NextWorldUpdate(() =>
    {
        // 双重校验（回写到主线程时再确认一次）
        if (!_registry.ValidateGeneration(slot, capturedGeneration)) return;
        _registry.GetBySlot(slot)!.LastSavedRecord = data;
    });
}
```

## 五、Interlocked + Volatile（通用异步状态失效）

适合简单的"配置重载/缓存重载时使缓存失效"场景：

```csharp
private int _cacheGeneration;

private void OnConfigChanged(Config newConfig)
{
    Interlocked.Increment(ref _cacheGeneration);
    // 进行中的异步加载如果完成后发现代际不匹配，会自动丢弃
}

private async Task ReloadCacheAsync()
{
    var gen = Volatile.Read(ref _cacheGeneration);
    var data = await FetchFromRemoteAsync();

    if (Volatile.Read(ref _cacheGeneration) != gen)
    {
        // 加载期间配置又变了，丢弃本次结果
        return;
    }

    ApplyCache(data);
}
```

## 六、关键反模式

**不要这样做：**
```csharp
// ❌ 阻塞主线程
var result = SomethingAsync().Result;
var result2 = SomethingAsync().GetAwaiter().GetResult();
SomethingAsync().Wait();

// ❌ 吞掉异常
_ = SomethingAsync();

// ❌ 异步后使用旧玩家引用
await Task.Delay(1000);
player.SendMessage(MessageType.Chat, "可能已断线");  // 危险！

// ❌ 无取消令牌的无限循环
while (true) { await Task.Delay(1000); DoWork(); }
```

**应该这样做：**
```csharp
// ✅ fire-and-forget 带日志（自实现 FireAndForget 工具，见本文 一）
FireAndForget(SomethingAsync(), Logger, "MyPlugin.Context");

// ✅ 异步后重取玩家
var currentPlayer = Core.PlayerManager.GetPlayerBySteamId(steamId);
if (currentPlayer is not null && currentPlayer.IsValid) { ... }

// ✅ 带取消令牌
while (!token.IsCancellationRequested) { await Task.Delay(1000, token); }
```

## Checklist

- [ ] 从同步入口发起的异步任务是否使用自实现的 `FireAndForget` 包装（见本文 一）？
- [ ] 异步 `await` 后是否重新校验 `IPlayer` 有效性？
- [ ] map-scoped 异步任务是否绑定 `StopOnMapChange`？
- [ ] 异步回写是否使用 generation counter 或类似的代际校验？
- [ ] 是否避免 `.Wait()` / `.Result` / 同步阻塞？
- [ ] 后台循环是否携带 `CancellationToken`？
