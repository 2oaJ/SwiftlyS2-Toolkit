# SwiftlyS2 Hook Handler 模板

对应官方文档：
- `Native Functions and Hooks`
- `Thread Safety`
- `Profiler`

适用于：高频 Hook、movement 采样、引擎回调分发、轻量采样 + 模块委托。

## 适用原则

- Hook 内优先做快速分流
- Hook 内不要直接做重 IO、重序列化、重日志
- Hook 负责采样与委托，不负责堆业务逻辑
- 涉及 `IPlayer` / `Pawn` / `Controller` 时，必须先做有效性检查

## 示例骨架

```csharp
using SwiftlyS2.Shared;
using SwiftlyS2.Shared.Core.Attributes.Hooks;
using SwiftlyS2.Shared.Hooks;
using SwiftlyS2.Shared.Player;

namespace MyNamespace;

public partial class MyPlugin
{
    [HookCallback("MyPlugin::OnSomeHighFrequencyHook")]
    public HookResult OnSomeHighFrequencyHook(DynamicHook hook)
    {
        var player = ResolvePlayerFromHook(hook);
        if (player is null || !player.Valid() || player.IsFakeClient)
        {
            return HookResult.Continue;
        }

        var pawn = player.PlayerPawn.Value;
        if (pawn is null || !pawn.IsValid)
        {
            return HookResult.Continue;
        }

        var snapshot = BuildMovementSnapshot(player, pawn);
        _runtimeModule.HandleMovementSnapshot(snapshot);
        return HookResult.Continue;
    }

    private IPlayer? ResolvePlayerFromHook(DynamicHook hook)
    {
        return null;
    }
}
```

## Checklist

- 是否先过滤无效 player / pawn / fake client / dead player？
- 是否避免在 Hook 内直接打日志？
- 是否避免在 Hook 内做 IO / HTTP / DB / JSON？
- 是否将复杂逻辑下沉到 module / service / worker？
- 是否考虑 64 tick / 15ms 帧预算？

## GameData Patch 模式

某些修复不需要 Hook，而是直接 patch 内存中的 gamedata：

```csharp
public class GameDataPatchService(ISwiftlyCore core, ILogger logger, string patchName)
    : IGameFixService
{
    public string ServiceName => patchName;

    public void Install()
    {
        core.GameData.ApplyPatch(patchName);
        logger.LogInformation("{PatchName} applied", patchName);
    }

    public void Uninstall() { }  // Patch 是单向的，无撤销
}
```

## 多 Hook 服务模式

当一个服务需要安装多个 Hook 时，每个 Hook 独立管理 `IUnmanagedFunction` + `Guid`：

```csharp
public class MultiHookService : IGameFixService
{
    private Guid? _touchHookId, _endTouchHookId, _precacheHookId;
    private IUnmanagedFunction<TouchDelegate>? _touchHook;
    private IUnmanagedFunction<EndTouchDelegate>? _endTouchHook;
    private IUnmanagedFunction<PrecacheDelegate>? _precacheHook;

    public void Install()
    {
        InstallTouchHook();
        InstallEndTouchHook();
        InstallPrecacheHook();
    }

    public void Uninstall()
    {
        if (_touchHookId.HasValue && _touchHook is not null)
            _touchHook.RemoveHook(_touchHookId.Value);
        if (_endTouchHookId.HasValue && _endTouchHook is not null)
            _endTouchHook.RemoveHook(_endTouchHookId.Value);
        if (_precacheHookId.HasValue && _precacheHook is not null)
            _precacheHook.RemoveHook(_precacheHookId.Value);
    }
}
```

**关键点**：
- 每个 Hook 有独立的 `Guid? + IUnmanagedFunction` 对
- Install 全部安装，Uninstall 全部移除
- 任何一个 Hook 安装失败不应影响已安装的其他 Hook

## Hook 安装时机

不是所有 Hook 都应在 `Load()` 安装：

- ✅ **Load() 安装**：全生命周期需要的核心 Hook
- ✅ **OnMapLoad / OnActivate 安装**：map-scoped 或条件性 Hook
- ✅ **特定事件后安装**：如热身结束后安装 Sellback Hook
- ❌ 不要在高频回调中重复安装

对应的卸载必须在 `Unload()` / `OnMapUnload` / `OnDeactivate` / 对称事件中完成。
