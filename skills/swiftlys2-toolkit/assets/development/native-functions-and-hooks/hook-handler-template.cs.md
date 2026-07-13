# SwiftlyS2 Hook Handler 模板

对应官方文档：
- `Native Functions and Hooks`
- `GameHooks`
- `Thread Safety`
- `Profiler`

适用于：**当前 `Core.GameHooks` 未覆盖**的原生函数 / vtable / mid-hook。typed controller、entity、movement、pawn、weapon hook 先看 `../game-hooks/game-hooks-pre-post-guide.md`。

性能优化和热路径治理先看：`../../../references/swiftlys2-performance-optimization-playbook.md`。

## 适用原则

- 先按入口选择：框架生命周期用 `Core.Event`；generated event 用 `Core.GameEvent`；typed native hook 用 `Core.GameHooks`；只有余下原生面才使用本模板
- 先判断是否真的需要该 Hook；能用低频 scheduler、状态差分或较粗 movement 阶段解决时，不要升级到更细粒度 Hook
- Hook 内不要直接做重 IO、重序列化、重日志
- Hook 负责采样与委托，不负责堆业务逻辑
- 涉及 `IPlayer` / `Pawn` / `Controller` 时，必须先做有效性检查
- 无当前 runtime、功能未启用、无订阅者时应尽早返回

## Exact delegate + `next()` 示例

```csharp
using System;
using System.Runtime.InteropServices;
using SwiftlyS2.Shared.Memory;

namespace MyNamespace;

public partial class MyPlugin
{
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate nint DispatchSpawnDelegate(nint entity, nint keyValues);

    private IUnmanagedFunction<DispatchSpawnDelegate>? _dispatchSpawn;
    private Guid _dispatchSpawnHook;

    private void InstallDispatchSpawnHook()
    {
        if (!Core.GameData.TryGetSignature("CBaseEntity::DispatchSpawn", out nint address))
        {
            throw new InvalidOperationException("DispatchSpawn signature was not found.");
        }

        _dispatchSpawn = Core.Memory.GetUnmanagedFunctionByAddress<DispatchSpawnDelegate>(address);
        _dispatchSpawnHook = _dispatchSpawn.AddHook(next =>
        {
            var callNext = next();
            return (entity, keyValues) =>
            {
                // pre: 只处理当前同步调用所需的最小数据。
                nint result = callNext(entity, keyValues);
                // post: 仅在原调用已执行后观察结果。
                return result;
            };
        });
    }

    private void UninstallDispatchSpawnHook()
    {
        if (_dispatchSpawn is not null && _dispatchSpawnHook != Guid.Empty)
        {
            _dispatchSpawn.RemoveHook(_dispatchSpawnHook);
            _dispatchSpawnHook = Guid.Empty;
        }
    }
}
```

`next()` 前的代码是 pre，后的代码是 post。要跳过原调用，才省略 `next()`；不要用 `CallOriginal()` 取代这个控制流。`Call()` 会经过当前 hook chain，`CallOriginal()` 会绕过它。

`DynamicHook`、`[HookCallback]` 和 `SwiftlyS2.Shared.Core.Attributes.Hooks` 属于旧的 CSS 风格，不是当前 SwiftlyS2 raw hook 入口。

## Checklist

- 是否先过滤无效 player / pawn / fake client / dead player？
- 是否先判断 Hook 是否必须存在，而不是默认常驻？
- 是否先过滤功能关闭、runtime 不存在、无 subscriber / forward 的情况？
- 是否避免在 Hook 内直接打日志？
- 是否避免在 Hook 内做 IO / HTTP / DB / JSON？
- 是否将复杂逻辑下沉到 module / service / worker？
- 是否考虑 64 tick / 15ms 帧预算？
- `Profiler.StartRecording` / `StopRecording` 是否成对，且名称稳定、不包含玩家或实体动态 id？

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

当一个服务需要安装多个 raw hook 时，每个 Hook 独立管理 `IUnmanagedFunction` + `Guid`：

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

## Raw hook 额外边界

- signature、vtable index、delegate 参数和 calling convention 必须来自当前可验证 gamedata / 官方 source；猜测会导致服务器崩溃。
- `IUnmanagedFunction`、raw address、pointer、`MidHookContext` 不得跨 `await`、线程、closure 或地图生命周期保存。
- plugin unload 虽会进行框架清理，但 service 仍应显式 `RemoveHook`，以获得确定性的 disable/uninstall 结果。
- 对每个 raw hook 做真实服务器验证：signature 命中、一次 pre/post、原调用放行、取消路径、地图切换、插件卸载。
