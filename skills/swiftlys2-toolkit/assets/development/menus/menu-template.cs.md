# SwiftlyS2 Menu 模板

对应官方文档：
- `Menus`
- `Thread Safety`
- `HTML Styling`

> 说明：官方文档示例常写 `Core.Menus`；若当前项目通过 `Core.MenusAPI` 暴露 `IMenuManagerAPI`，以当前项目实际 Core 属性为准。

## 设计要点

- 菜单入口方法只做校验与打开，不堆积业务细节。
- 子菜单优先拆成独立 `BuildXxxMenuAsync` / `GetXxxMenu` 方法。
- `BindingText` 是高优先级能力：动态文本优先用绑定，而不是手工刷新 `Text`。
- `Click` / `ValueChanged` / `Submenu` 委托按异步上下文处理。
- 在异步上下文中，优先使用已有 `Async` API，而不是默认套 `NextTick` / `NextWorldUpdate`。
- 状态读写尽量下沉到 service / module / runtime context。

## 模板骨架

```csharp
using SwiftlyS2.Core.Menus;
using SwiftlyS2.Shared.Menus;

public partial class ExamplePlugin
{
    public async Task OpenSettingsMenuAsync(IPlayer player)
    {
        if (player == null || !player.IsValid)
        {
            return;
        }

        var menu = await BuildSettingsMenuAsync(player);
        if (menu == null)
        {
            return;
        }

        Core.MenusAPI.OpenMenuForPlayer(player, menu);
    }

    private async Task<IMenuAPI?> BuildSettingsMenuAsync(IPlayer player)
    {
        if (player == null || !player.IsValid)
        {
            return null;
        }

        var runtime = await _settingsService.GetPlayerSettingsAsync(player);
        if (runtime == null)
        {
            return null;
        }

        var menu = Core.MenusAPI.CreateBuilder()
            .Design.SetMenuTitle("示例设置")
            .EnableSound()
            .SetPlayerFrozen(false)
            .Build();

        var txtSummary = new TextMenuOption
        {
            BindingText = () => $"当前方案: {runtime.SelectedStyle} | 音量: {runtime.Volume} | 功能: {(runtime.Enabled ? "开启" : "关闭")}"
        };
        menu.AddOption(txtSummary);

        var toggleEnable = new ToggleMenuOption("功能开关", runtime.Enabled, onText: "开启", offText: "关闭");
        toggleEnable.ValueChanged += async (_, args) =>
        {
            if (args.Player == null || !args.Player.IsValid)
            {
                return;
            }

            await _settingsService.SetEnabledAsync(args.Player, args.NewValue);
            runtime.Enabled = args.NewValue;
            await args.Player.SendMessageAsync(MessageType.Chat, $"{{green}}[设置]{{default}} 功能已{(args.NewValue ? "开启" : "关闭")}");
        };
        menu.AddOption(toggleEnable);

        var btnSave = new ButtonMenuOption("保存设置") { CloseAfterClick = true };
        btnSave.Click += async (_, args) =>
        {
            if (args.Player == null || !args.Player.IsValid)
            {
                return;
            }

            await _settingsService.SaveAsync(args.Player, runtime.SelectedStyle, runtime.Volume, runtime.Enabled);
            await args.Player.SendMessageAsync(MessageType.Chat, "{green}[设置]{default} 你的设置已保存");
        };
        menu.AddOption(btnSave);

        return menu;
    }
}
```

## 菜单回调中的主线程派发（NextWorldUpdate）

菜单 `Click` / `ValueChanged` 回调是 `async` 委托，运行在异步上下文中。

**硬规则：** 若回调内需要执行以下操作，必须用 `Core.Scheduler.NextWorldUpdate()` 包装，将其派发回主线程：

- 创建 / 销毁实体（`CreateEntityByDesignerName`、`DispatchSpawn`、`Despawn`）
- 写入 Schema 属性（`pawn.Render`、`pawn.RenderMode`、`pawn.MoveType` 等）
- 调用 `*Updated()` 同步方法（`RenderUpdated()`、`RenderModeUpdated()` 等）
- 设置模型、ViewEntity、修改武器服务、执行命令等主线程同步 API（完整清单参见 thread-sensitivity-checklist）

> ⚠️ 若该方法存在 Async 版本（如 `SetModelAsync`、`AcceptInputAsync`、`TeleportAsync`、`RespawnAsync`），在异步上下文中可直接使用 Async 版本而无需 `NextWorldUpdate`。

**不需要 NextWorldUpdate** 的操作：

- `PrintToChatAsync` / `PrintToConsoleAsync` 等已有 Async API
- 线程安全容器操作（`ConcurrentDictionary.TryAdd` 等）
- 纯异步 IO（HTTP、数据库查询）

### 正确示例

```csharp
btn.Click += async (sender, args) =>
{
    var p = args.Player;
    if (!p.Valid() || !p.IsPlayerAlive()) return;

    // 异步 IO 可直接执行
    var data = await FetchDataAsync(p.SteamID);
    if (data is null)
    {
        await p.PrintToChatAsync("数据获取失败");
        return;
    }

    // 涉及实体/Schema 操作 → 必须回主线程
    Core.Scheduler.NextWorldUpdate(() =>
    {
        if (!p.Valid() || !p.IsPlayerAlive()) return; // 再次校验

        var pawn = p.PlayerPawn;
        if (!pawn.Valid()) return;

        pawn.Render = new Color(255, 0, 0, 255);
        pawn.RenderUpdated();
    });
};
```

### 错误示例

```csharp
// ❌ 异步回调中直接操作实体
btn.Click += async (sender, args) =>
{
    var pawn = args.Player.PlayerPawn;
    pawn.Render = new Color(255, 0, 0, 255); // 可能不在主线程
    pawn.RenderUpdated();
    runtimeService.CreateDanceEntity(args.Player); // 创建实体不在主线程
};
```

## 菜单实现检查点

- 是否优先评估了 `BindingText`？
- 是否把回调按异步上下文处理？
- 是否在每个回调里重新检查 `player.IsValid`？
- 是否避免在菜单回调里做重 IO / 阻塞 / 大量分配？
- 是否把真实状态写回留在 service / runtime context 中？
- **回调中是否涉及实体创建/销毁、Schema 写回、模型操作？若是，是否已用 `NextWorldUpdate` 派发回主线程？**
- **`NextWorldUpdate` 回调内是否再次校验了 `player.Valid()` / `pawn.Valid()`？**

## 进阶菜单模式

### BindingText 动态倒计时

```csharp
var btnTimer = new TextMenuOption
{
    BindingText = () =>
    {
        var remaining = _deadline - DateTime.Now;
        return remaining.TotalSeconds > 0
            ? $"剩余时间: {remaining.TotalSeconds:0.0} 秒"
            : "已超时";
    }
};
menu.AddOption(btnTimer);
```

### Tag 数据关联

使用 `Tag` 属性将菜单项与业务数据对象关联，便于回调和统计：

```csharp
foreach (var item in availableItems)
{
    var btn = new TextMenuOption { Text = item.DisplayName, Tag = item };
    btn.Click += async (sender, args) =>
    {
        if (sender is MenuOptionBase option && option.Tag is MyItem selectedItem)
        {
            await ProcessSelection(args.Player, selectedItem);
        }
    };
    menu.AddOption(btn);
}
```

### 投票计数实时更新

投票场景中，选择后更新所有选项的票数显示：

```csharp
btn.Click += async (sender, args) =>
{
    _votes.AddOrUpdate(steamId, selectedItem, (_, __) => selectedItem);

    // 遍历更新所有选项的显示文本
    foreach (var option in menu.Options)
    {
        if (option.Tag is MyItem tagItem)
        {
            var count = _votes.Count(x => x.Value == tagItem);
            option.Text = $"[{count}] {tagItem.DisplayName}";
        }
    }
};
```

### ConfirmMenu（确认对话框）

官方 API 通过 `CreateBuilder()` + `OpenMenuForPlayer(player, menu, onClosed)` + `TaskCompletionSource` 实现异步等待：

```csharp
private async Task<bool> OpenConfirmMenuAsync(IPlayer player, string message)
{
    var tcs = new TaskCompletionSource<bool>();

    var menu = Core.MenusAPI.CreateBuilder()
        .Design.SetMenuTitle("请确认操作")
        .EnableSound()
        .SetPlayerFrozen(false)
        .Build();


    menu.Tag = false; // 用 Tag 作为结果容器

    menu.AddOption(new TextMenuOption(message));

    var btnOK = new ButtonMenuOption("确定") { CloseAfterClick = true };
    btnOK.Click += async (sender, args) =>
    {
        if (args.Player?.IsValid == true)
            menu.Tag = true;
    };
    menu.AddOption(btnOK);

    var btnCancel = new ButtonMenuOption("取消") { CloseAfterClick = true };
    menu.AddOption(btnCancel);

    Core.MenusAPI.OpenMenuForPlayer(player, menu, (_player, _menu) =>
    {
        // 注意：此处 Tag 须由本方法独占管理，不得在 Build() 后外部覆写
        tcs.TrySetResult((bool)_menu.Tag!);
    });

    return await tcs.Task;
}

// 调用
var confirmed = await OpenConfirmMenuAsync(player, "您确定要执行此操作吗？");
if (confirmed)
{
    await ExecuteDangerousAction(player);
}
```

> 提示：若需要剪断超时，可在开始等待同时启动 `Task.Delay(timeoutMs)` 并用 `Task.WhenAny` 与 `tcs.Task` 竞争。

### 跨插件菜单跳转

通过 ExecuteCommand 松耦合跳转到其他插件菜单：

```csharp
var btnSkin = new ButtonMenuOption("角色模型菜单") { CloseAfterClick = true };
btnSkin.Click += async (sender, args) =>
{
    Core.Scheduler.NextWorldUpdate(() =>
    {
        args.Player.ExecuteCommand("sw_skin");
    });
};
menu.AddOption(btnSkin);
```

### InputMenuOption（输入框）

允许玩家输入文本的菜单项：

```csharp
var inputOption = new InputMenuOption("输入名称");
inputOption.ValueChanged += async (sender, args) =>
{
    if (args.Player is null || !args.Player.Valid()) return;
    var inputText = args.NewValue?.Trim();
    if (string.IsNullOrWhiteSpace(inputText)) return;

    await ProcessInput(args.Player, inputText);
};
menu.AddOption(inputOption);
```
