# SwiftlyS2 Per-Player 状态管理指南

对应官方文档：
- `Core Events`
- `Thread Safety`
- `Terminologies`

适用于：需要为每个玩家维护运行时状态的插件。

## 模式选型

按插件复杂度递增，有以下几种 per-player 状态管理模式：

### Level 1：轻量键值（小型插件）

适合：状态简单、只有一两个字段。

```csharp
private readonly ConcurrentDictionary<ulong, bool> _playerEnabled = new();

[EventListener<OnClientPutInServer>]
public void OnClientPutInServer(IOnClientPutInServerEvent @event)
{
    Core.Scheduler.NextWorldUpdate(() =>
    {
        var player = Core.PlayerManager.GetPlayer(@event.PlayerId);
        if (player is null || !player.IsValid) return;
        _playerEnabled.TryAdd(player.SteamID, true);
    });
}

[EventListener<OnClientDisconnected>]
public void OnClientDisconnected(IOnClientDisconnectedEvent @event)
{
    _playerEnabled.TryRemove(@event.SteamID, out _);
}
```

### Level 2：运行时状态对象（中等插件）

适合：每个玩家有多个字段需要同步管理。

```csharp
public class PlayerRuntime
{
    public ulong SteamId { get; init; }
    public string? SelectedStyle { get; set; }
    public bool IsEnabled { get; set; } = true;
    public DateTime LastAction { get; set; } = DateTime.UtcNow;
}

private readonly ConcurrentDictionary<ulong, PlayerRuntime> _playerStates = new();

[EventListener<OnClientPutInServer>]
public void OnClientPutInServer(IOnClientPutInServerEvent @event)
{
    Core.Scheduler.NextWorldUpdate(() =>
    {
        var player = Core.PlayerManager.GetPlayer(@event.PlayerId);
        if (player is null || !player.IsValid) return;

        // GetOrAdd 保证原子性，避免竞态
        _playerStates.GetOrAdd(player.SteamID, steamId => new PlayerRuntime
        {
            SteamId = steamId
        });
    });
}

[EventListener<OnClientDisconnected>]
public void OnClientDisconnected(IOnClientDisconnectedEvent @event)
{
    if (_playerStates.TryRemove(@event.SteamID, out var runtime))
    {
        // 可选：异步持久化（需先实现 FireAndForget，见 async-safety-guide.md 一）
        FireAndForget(PersistPlayerStateAsync(runtime), Logger, "MyPlugin.PersistOnDisconnect");
    }
}
```

### Level 3：带 DB 恢复的状态对象

适合：需要在断线重连后恢复玩家偏好。

```csharp
[EventListener<OnClientPutInServer>]
public void OnClientPutInServer(IOnClientPutInServerEvent @event)
{
    if (@event.Kind != ClientKind.Player) return;

    Core.Scheduler.NextWorldUpdate(() =>
    {
        var player = Core.PlayerManager.GetPlayer(@event.PlayerId);
        if (player is null || !player.IsValid) return;

        // 从 DB 或远端恢复（需先实现 FireAndForget，见 async-safety-guide.md 一）
        FireAndForget(LoadPlayerStateAsync(player), Logger, "MyPlugin.LoadPlayerState");
    });
}

private async Task LoadPlayerStateAsync(IPlayer player)
{
    var steamId = player.SteamID;
    var dbRecord = await SomeService.GetPlayerDataAsync(steamId);

    // 异步完成后重新校验玩家
    var currentPlayer = Core.PlayerManager.GetPlayerBySteamId(steamId);
    if (currentPlayer is null || !currentPlayer.IsValid) return;

    var runtime = new PlayerRuntime
    {
        SteamId = steamId,
        SelectedStyle = dbRecord?.Style,
        IsEnabled = dbRecord?.Enabled ?? true
    };

    _playerStates.AddOrUpdate(steamId, runtime, (_, __) => runtime);
}
```

### Level 4：槽位数组 + 代际计数（大型 gameplay 插件）

适合：高频 Hook 中需要 O(1) 访问、异步回写需要代际校验。

```csharp
public class PlayerRegistry
{
    private readonly PlayerState?[] _slots = new PlayerState[64];
    private readonly int[] _generations = new int[64];
    private readonly Dictionary<ulong, PlayerState> _steamIndex = new();

    public PlayerState? Attach(int slot, ulong steamId, IPlayer player)
    {
        Detach(slot);
        var generation = Interlocked.Increment(ref _generations[slot]);
        var state = new PlayerState(slot, steamId, generation, player);
        _slots[slot] = state;
        _steamIndex[steamId] = state;
        return state;
    }

    public void Detach(int slot)
    {
        if (_slots[slot] is { } old)
        {
            old.IsAttached = false;
            _steamIndex.Remove(old.SteamId);
            _slots[slot] = null;
        }
    }

    /// <summary>O(1) 用于高频 Hook</summary>
    public PlayerState? GetBySlot(int slot)
    {
        return slot >= 0 && slot < 64 ? _slots[slot] : null;
    }

    /// <summary>异步回写前校验代际</summary>
    public bool ValidateGeneration(int slot, int capturedGeneration)
    {
        return slot >= 0 && slot < 64
            && _slots[slot] is { IsAttached: true } s
            && s.Generation == capturedGeneration;
    }
}
```

## 身份键选择

| 场景 | 推荐键 | 原因 |
|------|--------|------|
| 真人玩家长期存储 | `SteamID` (ulong) | 跨会话稳定 |
| 运行时快速查找 | `SteamID` 或 `Slot` | 取决于热路径需求 |
| bot / fakeclient | `SessionId` | bot 的 SteamID 固定为 0，不可靠 |
| 高频 Hook 内查找 | 槽位数组 `_slots[slot]` | O(1)，无哈希开销 |

## 清理时机

- `OnClientDisconnected`：移除运行时状态
- `OnMapLoad` / `OnMapUnload`：清理 map-scoped 缓存
- 插件 `Unload()`：清空所有状态

## 并发安全规则

- 优先使用 `TryAdd`、`TryRemove`、`TryGetValue`、`GetOrAdd`、`AddOrUpdate`
- 避免 `ContainsKey` + `Remove` / `ContainsKey` + `Add` 双步写法
- 状态变更用 `AddOrUpdate` 的 merge predicate 防止降级
- 异步回写前重新校验玩家/代际
- 高频路径中可缓存 slot 引用，跳过字典查找

## Checklist

- [ ] 是否在 connect 时初始化？
- [ ] 是否在 disconnect 时清理？
- [ ] 是否区分真人与 bot 的身份键策略？
- [ ] 异步延迟后是否重新校验玩家有效性？
- [ ] 并发操作是否使用原子 API？
- [ ] map 切换时 map-scoped 缓存是否清理？
