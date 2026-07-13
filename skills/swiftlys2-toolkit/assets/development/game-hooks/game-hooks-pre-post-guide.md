# SwiftlyS2 GameHooks Pre/Post 指南

对应官方文档：

- `GameHooks` API
- `Core Events`
- `Game Events`
- `Native Functions and Hooks`

`Core.GameHooks` 是当前优先的 typed native-hook 面。它按 `Controller`、`Entities`、`Items`、`Movement`、`Pawn`、`Weapons` 分类，并为每个已建模 hook 暴露 `Pre` 与 `Post`。

## 先选对入口

| 需求 | 首选入口 | 不应替代它的入口 |
| --- | --- | --- |
| 插件、地图、连接、tick 等框架生命周期 | `Core.Event` | 不要为普通生命周期改用 native hook |
| generated Source 2 Game Event | `Core.GameEvent` | 不要把 Game Event 当作稳定生命周期总线 |
| 已有 typed entity / controller / movement / pawn / weapon hook | `Core.GameHooks` | 不要继续订阅已废弃的 `Core.Event.On*Hook` |
| 当前 GameHooks 未覆盖的原生函数或 mid-hook | `Core.GameData` + `Core.Memory` | 不要虚构 `DynamicHook` 或旧 CSS hook API |

官方 API 已将下列旧 Core Event hook 标为废弃，并明确给出 GameHooks 迁移方向：

| 旧入口 | 当前入口 |
| --- | --- |
| `OnClientProcessUsercmds` | `Core.GameHooks.Controller.ProcessUsercmds` |
| `OnEntityEndTouch` / `OnEntityStartTouch` / `OnEntityTouch` | `Core.GameHooks.Entities.EndTouch` / `StartTouch` / `Touch` |
| `OnEntityFireOutputHook` / `OnEntityIdentityAcceptInputHook` | `Core.GameHooks.Entities.FireOutput` / `AcceptInput` |
| `OnEntityTakeDamage` | `Core.GameHooks.Entities.TakeDamage` |
| `OnItemServicesCanAcquireHook` | `Core.GameHooks.Items.CanAcquire` |
| `OnMovementServicesRunCommandHook` | `Core.GameHooks.Movement.RunCommand` |
| `OnPlayerPawnPostThink` | `Core.GameHooks.Pawn.PostThink` |
| `OnWeaponServicesCanUseHook` / `OnWeaponServicesDropWeaponHook` | `Core.GameHooks.Weapons.CanUse` / `Drop` |

## Pre / Post 语义

`HookMode` 只有 `Pre` 和 `Post`。对能够控制原调用的 hook，结果语义为：

| 结果 | Pre | Post |
| --- | --- | --- |
| `HookResult.Continue` | 继续后续 hook 和原调用 | 继续后续 hook |
| `HookResult.CancelOriginal` | 后续 hook 继续，原调用取消 | 不应作为 Post 控制手段 |
| `HookResult.Handled` | 后续 hook 取消，原调用继续 | 不生效 |
| `HookResult.Stop` | 后续 hook 和原调用都取消 | 不生效 |

不要把“Post 可取消”写进实现或审计结论。实际 hook 的 API 页面仍是最终依据，因为不同 native 调用的可写参数不同。

## 最小订阅与卸载模式

```csharp
using System;
using SwiftlyS2.Shared;
using SwiftlyS2.Shared.GameHooks;
using SwiftlyS2.Shared.Misc;

public sealed class UsercmdFeature : IMyFeature
{
    private readonly ISwiftlyCore _core;
    private bool _installed;

    public UsercmdFeature(ISwiftlyCore core)
    {
        _core = core;
    }

    public void Install()
    {
        if (_installed)
        {
            return;
        }

        _core.GameHooks.Controller.ProcessUsercmds.Pre += OnProcessUsercmdsPre;
        _core.GameHooks.Controller.ProcessUsercmds.Post += OnProcessUsercmdsPost;
        _installed = true;
    }

    public void Uninstall()
    {
        if (!_installed)
        {
            return;
        }

        _core.GameHooks.Controller.ProcessUsercmds.Pre -= OnProcessUsercmdsPre;
        _core.GameHooks.Controller.ProcessUsercmds.Post -= OnProcessUsercmdsPost;
        _installed = false;
    }

    private void OnProcessUsercmdsPre(ref ProcessUsercmdsPreContext ctx)
    {
        var player = ctx.Params.Player;
        if (!player.IsValid || player.IsFakeClient)
        {
            return;
        }

        if (ShouldBlockCommands(player, ctx.Params.Usercmds))
        {
            ctx.SetHookResult(HookResult.Stop);
        }
    }

    private void OnProcessUsercmdsPost(ref ProcessUsercmdsPostContext ctx)
    {
        // 只做已经发生后的轻量观察；不要在 Post 中尝试取消原调用。
    }
}
```

## `ref struct` 与临时对象边界

`*PreContext` / `*PostContext` 是 `ref struct`。其中的参数、native wrapper、`IUserCmd` 列表和任何由它们间接取得的临时对象均只在当前回调有效。

- 不得保存 context、`ctx.Params`、`IUserCmd`、entity wrapper 或 `ref` 到字段。
- 不得把它们捕获到 lambda、`Task`、scheduler 回调或 async state machine。
- 需要延迟处理时，只复制普通值、稳定身份键或 `CHandle<T>`；在新回调内重新解析并校验。
- 高频 hook 中只做早退、最小快照或轻量分发；IO、JSON、HTTP、DB 和高频日志移出 hook。

## Attribute 形式

`[GameHookHandler(HookMode.Pre)]` / `Post` 可用于固定的声明式注册。只有在类已被框架注册且能证明目标 hook 的签名时才使用；需要显式启停、独立 service 所有权或精确清理时，优先使用上面的 `+=` / `-=` 模式。

## 验证清单

- [ ] 目标是否已由 `Core.GameHooks` 覆盖，而非继续使用废弃 Core hook？
- [ ] 是否选择了正确的 `Pre` 或 `Post`，且没有在 Post 中依赖取消语义？
- [ ] 每一次 `+=` 是否有同一 owning service 中的对称 `-=`？
- [ ] 是否没有让 context、临时 wrapper 或 native reference 跨回调边界？
- [ ] 是否在真实服务器上覆盖 enable/disable、换图、插件卸载和 bot/真人路径？
