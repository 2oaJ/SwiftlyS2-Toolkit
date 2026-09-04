# SwiftlyS2 Steamworks Server 指南

对应官方文档：`Steamworks`。

SwiftlyS2 的服务器侧 Steam API 位于 `SwiftlyS2.Shared.SteamAPI`。它用于 Steam 身份、授权信号、服务器元数据、Workshop 和异步 Steam callback；不要把它与普通客户端 Steamworks API 混用。

## 生命周期入口

Steam API 准备好后再启动依赖它的逻辑，并在卸载时解除订阅：

```csharp
using SwiftlyS2.Shared.Events;
using SwiftlyS2.Shared.SteamAPI;

private EventDelegates.OnSteamAPIActivated? _onSteamApiActivated;

public override void Load(bool hotReload)
{
    _onSteamApiActivated = OnSteamApiActivated;
    Core.Event.OnSteamAPIActivated += _onSteamApiActivated;
}

public override void Unload()
{
    if (_onSteamApiActivated is not null)
    {
        Core.Event.OnSteamAPIActivated -= _onSteamApiActivated;
    }
}

private void OnSteamApiActivated()
{
    var appId = SteamGameServerUtils.GetAppID();
    Core.Logger.LogInformation("Steam API active. AppId={AppId}", appId.m_AppId);
}
```

不要凭此模板推断 `Load`、共享接口回调和激活事件之间的精确时序；官方仅定义了各自职责，实际依赖应在使用前检查可用状态。

## 身份和授权

- 用 `new CSteamID(player.SteamID)` 进入 Steam API 前，先检查玩家是有效真人而不是 bot。
- 使用 `CSteamID.IsValid()` 和 `BIndividualAccount()` 验证身份类型。
- 授权成功/失败使用 `Core.Event.OnClientSteamAuthorize` 与 `OnClientSteamAuthorizeFail`。
- 不要新增对 `SendUserConnectAndAuthenticate_DEPRECATED` 或 `SendUserDisconnect_DEPRECATED` 的调用；授权会话使用当前 `BeginAuthSession` / `EndAuthSession` API。

## Callback / CallResult 所有权

`Callback<T>` 和 `CallResult<T>` 必须由 plugin/service 字段保活，并在不再需要时 dispose；局部变量会被 GC 回收，导致回调不再投递。

```csharp
private Callback<DownloadItemResult_t>? _downloadResult;

public void StartWorkshopWatch()
{
    _downloadResult = Callback<DownloadItemResult_t>.Create(OnDownloadResult);
}

public void StopWorkshopWatch()
{
    _downloadResult?.Dispose();
    _downloadResult = null;
}
```

异步 `SteamAPICall_t` 使用 `CallResult<T>`，同样需要替换/卸载时 dispose。

## Workshop 与服务器元数据

- Workshop 使用 `SteamGameServerUGC`，不是客户端导向的 `SteamUGC`。
- `SteamGameServer` 可设置服务器名称、地图、人数、密码状态、tags 和 game data。
- Workshop 下载完成后再读取 install info；回调失败需有可观测日志，但不要在高频事件中刷屏。

## Checklist

- [ ] Steam API 是否已激活，且 listener 有对称取消？
- [ ] 是否过滤 bot 和无效 `IPlayer` 后才构造 `CSteamID`？
- [ ] `Callback<T>` / `CallResult<T>` 是否是字段且能 dispose？
- [ ] 是否使用 server-side API 面和当前授权 API？
- [ ] 是否为卸载、换图和回调晚到准备好取消/无效状态处理？
