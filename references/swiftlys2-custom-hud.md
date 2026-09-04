# SwiftlyS2 Custom HUD 服务端指南

> 官方文档：<https://swiftlys2.net/docs/development/custom-hud/>
> 官方警告：Custom HUD 是**新且不稳定**的功能，Valve 可能在未来做出破坏性 API 变更；实际行为与文档不符时以实测为准并向上游反馈。
> 分工：本文件只覆盖服务端 C# 侧的实体与状态管理；Panorama XML / CSS 布局制作属于客户端资产工作。

## 1. 模型概述

- 使用 `custom_hud_layout` 实体为玩家创建自定义 HUD。
- 界面用 Panorama XML + CSS 构建；服务端通过 `CCSCustomHudLayout` 提供的方法更新状态。
- XML 元素的 `id` 即服务端方法里的 `panelId`；`{s:dynamic}` 动态串中的 `dynamic` 即 `variableName`。

## 2. 创建实体

```csharp
var hud = Core.EntitySystem.CreateEntity<CCSCustomHudLayout>();
hud.StrLayout = "panorama/layout/custom_game/example.xml";
hud.StrLayoutUpdated();
hud.DispatchSpawn();
```

- 先设 layout 路径并 `StrLayoutUpdated()` 通知引擎字段已变，再 `DispatchSpawn()`。
- 实体生命周期遵循通用实体规则：map unload / 插件 unload 时必须清理，不要残留孤儿 HUD 实体。

## 3. 动态字符串（Dialog Variables）

全局值（所有玩家共享）：

```csharp
hud.SetDialogVariableString("text1", "dynamic", "Global text");
string? globalValue = hud.GetDialogVariableString("text1", "dynamic");
```

按玩家覆盖（override）：

```csharp
hud.SetDialogVariableStringForPlayer(playerId, "text1", "dynamic", "Only this player");
string? playerValue = hud.GetDialogVariableStringForPlayer(playerId, "text1", "dynamic");
hud.RemoveDialogVariableStringForPlayer(playerId, "text1", "dynamic");
```

关键语义：

- `GetDialogVariableStringForPlayer` **只读玩家覆盖值，不回退全局值**；未设置时返回 `null`（即使全局值存在）。
- `RemoveDialogVariableStringForPlayer` 之后该玩家显示回落到全局设置。
- 高频更新（每 tick / 每 sample）不要无脑全量 set；先读后比、仅在变化时写入，避免无谓的同步开销。

## 4. 动态 CSS 类

`EHudPanelClassStatus_t` 三态：

| 状态 | 含义 |
| --- | --- |
| `k_eHudPanelClassStatus_HasClass` | 元素有该类 |
| `k_eHudPanelClassStatus_DoesNotHaveClass` | 元素没有该类 |
| `k_eHudPanelClassStatus_Undefined` | 未定义（读取不存在的 panelId / className / 状态时也返回它） |

```csharp
hud.SetHasClass("main_panel", "highlight", EHudPanelClassStatus_t.k_eHudPanelClassStatus_HasClass);
EHudPanelClassStatus_t global = hud.GetHasClass("main_panel", "highlight");

hud.SetHasClassForPlayer(playerId, "main_panel", "highlight", EHudPanelClassStatus_t.k_eHudPanelClassStatus_DoesNotHaveClass);
EHudPanelClassStatus_t perPlayer = hud.GetHasClassForPlayer(playerId, "main_panel", "highlight");
```

`className` 必须是 Panorama CSS 中已定义的类。

## 5. 输入捕获与按钮点击

输入捕获开启后玩家可自由移动鼠标光标点击 HUD 内按钮：

```csharp
hud.SetInputCaptureEnabled(true);                     // 全局
bool g = hud.IsInputCaptureEnabled();
hud.SetInputCaptureEnabledForPlayer(playerId, true);  // 按玩家
bool p = hud.IsInputCaptureEnabledForPlayer(playerId);
```

点击事件（Load 订阅 / Unload 退订）：

```csharp
public override void Load(bool hotReload)
{
    Core.Event.OnCustomHudClicked += OnCustomHudClicked;
}

public override void Unload(bool hotReload)
{
    Core.Event.OnCustomHudClicked -= OnCustomHudClicked;
}

private void OnCustomHudClicked(IOnCustomHudClickedEvent @event)
{
    if (@event.ButtonId != "action_button") return;
    // @event.PlayerId / @event.CustomHudLayout
}
```

`IOnCustomHudClickedEvent` 属性：

| 属性 | 说明 |
| --- | --- |
| `PlayerId` | 点击的玩家 |
| `ButtonId` | 被点按钮在 XML 中的 `id` |
| `CustomHudLayout` | 包含被点按钮的 `CCSCustomHudLayout` 实体 |

- `OnCustomHudClicked` 收到**所有** Custom HUD 布局的点击；插件创建多个 layout 时，先比对持有的 layout 实体再处理 ButtonId。
- 输入捕获会改变玩家输入行为（光标释放），用完（如交互结束）应及时按玩家关闭。

## 6. 线程安全与 Async 变体

- 上述**改状态的同步方法都是线程不安全的**（`[ThreadUnsafe]` 语义）。
- 每个线程不安全方法都有对应 `Async` 变体（`SetDialogVariableStringAsync`、`SetDialogVariableStringForPlayerAsync`、`RemoveDialogVariableStringForPlayerAsync`、`SetHasClassAsync`、`SetHasClassForPlayerAsync`、`SetInputCaptureEnabledAsync`、`SetInputCaptureEnabledForPlayerAsync`）；在游戏线程上立即执行，否则调度到游戏线程执行。
- **后台任务一律 `await` Async 变体**，不要直接调同步方法。
- Getter 保持同步。

## 7. 方法速查

| 方法 | 说明 |
| --- | --- |
| `SetDialogVariableString` / `GetDialogVariableString` | 全局动态字符串读写（未设置返回 `null`） |
| `SetDialogVariableStringForPlayer` / `GetDialogVariableStringForPlayer` / `RemoveDialogVariableStringForPlayer` | 玩家覆盖的设置 / 读取（不回退全局）/ 移除 |
| `SetHasClass` / `GetHasClass` | 全局 CSS 类状态 |
| `SetHasClassForPlayer` / `GetHasClassForPlayer` | 玩家级 CSS 类状态 |
| `SetInputCaptureEnabled` / `IsInputCaptureEnabled` | 全局输入捕获 |
| `SetInputCaptureEnabledForPlayer` / `IsInputCaptureEnabledForPlayer` | 玩家级输入捕获 |

## 8. 生命周期与评审清单

- 实体：创建失败 / 平台不支持时的回退路径；map unload、插件 unload 时的实体清理。
- 事件：`OnCustomHudClicked` 订阅与退订成对（Load / Unload、hot reload 均覆盖）。
- 输入捕获：开启时机与关闭时机成对；玩家断线后其覆盖状态不依赖旧 `IPlayer` 引用。
- 热路径：dialog variable / class 状态更新先做脏检查；后台任务用 Async 变体。
- 兼容性：功能不稳定，接受 Valve 破坏性变更的可能；把 layout XML 与面板 `id` 约定集中管理，便于 API 变更时收敛修改面。

相关 API 页：`CCSCustomHudLayout`（SchemaDefinitions）、`EHudPanelClassStatus_t`、`IOnCustomHudClickedEvent`（Events）、`EventDelegates.OnCustomHudClicked`。
