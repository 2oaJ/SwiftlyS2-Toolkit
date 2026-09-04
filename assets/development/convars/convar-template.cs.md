# SwiftlyS2 ConVar 模板

对应官方文档：
- `Convars`

适用于：需要运行时可调整的服务器参数（不修改配置文件即可生效）。

## ConVar vs Config 选型

| 维度 | ConVar | Config (JSONC) |
|------|--------|----------------|
| 修改方式 | 控制台命令 / rcon | 编辑文件后自动热加载 |
| 适合场景 | 运行时快速调参、管理员临时调整 | 结构化配置、复杂嵌套、默认值管理 |
| 持久化 | 需额外处理（exec/autoexec） | 文件即持久化 |
| 类型支持 | `bool`、整数、浮点、`Color`、`QAngle`、`Vector` 系列、`string` | 任意 C# 对象 |
| 范围约束 | 内建 min/max | 需业务自行校验 |

**经验法则**：
- 管理员可能在游戏中实时调整的参数 → ConVar
- 结构化配置、数组、嵌套对象 → Config
- 混用时，ConVar 做运行时开关/微调，Config 做结构化默认值

## 声明式 ConVar（推荐 partial 文件组织）

```csharp
// MyPlugin.ConVars.cs
namespace MyNamespace;

public partial class MyPlugin
{
    // 使用 required 强制在 Load 时初始化
    public required IConVar<bool> ConVar_EnableFeature { get; set; }
    public required IConVar<int> ConVar_MaxPlayers { get; set; }
    public required IConVar<float> ConVar_SpeedMultiplier { get; set; }

    private void InitConVars()
    {
        // 基础 bool ConVar
        ConVar_EnableFeature = Core.ConVar.CreateOrFind(
            "sw_myplugin_enable",           // ConVar 名称
            "启用功能",                      // 描述
            true,                            // 默认值
            ConvarFlags.NONE
        );

        // 带范围约束的 int ConVar（-1 = 不限制，0 = 禁用，>0 = 具体值）
        ConVar_MaxPlayers = Core.ConVar.CreateOrFind(
            "sw_myplugin_max_players",
            "最大玩家数量限制 (-1=不限制)",
            -1,                              // 默认值
            -1, 64,                          // min, max
            ConvarFlags.NONE
        );

        // float ConVar
        ConVar_SpeedMultiplier = Core.ConVar.CreateOrFind(
            "sw_myplugin_speed_mult",
            "速度倍率",
            1.0f,
            0.1f, 10.0f,
            ConvarFlags.NONE
        );
    }
}
```

## 初始化时机

```csharp
public override void Load(bool hotReload)
{
    InitConVars();
    // ... 后续使用 ConVar_XXX.Value 读取
}
```

## 在业务逻辑中读取

```csharp
// 直接读取当前值
if (!ConVar_EnableFeature.Value)
    return;

int limit = ConVar_MaxPlayers.Value;
if (limit >= 0 && currentCount >= limit)
{
    player.SendMessage(MessageType.Chat, "已达最大玩家限制");
    return;
}

float speed = baseSpeed * ConVar_SpeedMultiplier.Value;
```

## 约定与范围惯例

-1 = 不限制、0 = 禁用、>0 = 具体值 是插件生态中的常见约定，适合购买限制、数量限制等场景。

## 类型与创建选择

当前泛型 API 支持：`bool`、`short`、`ushort`、`int`、`uint`、`long`、`ulong`、`float`、`double`、`Color`、`QAngle`、`Vector`、`Vector2D`、`Vector4D`、`string`。

- 要让同名 ConVar 重复注册直接暴露错误时，用 `Create<T>`。
- 有意复用同名项或处理 hot reload 时，用 `CreateOrFind<T>`；它按名称创建或取得既有项，避免重复注册错误，不代表并发安全保证。
- 带 min/max 的重载要求 `T : unmanaged`，不要向所有泛型类型宣称有范围约束。
- `ConvarFlags.SERVER_CAN_EXECUTE` 的含义是允许服务器在客户端执行该命令，**不是**管理员修改权限。权限控制放在命令、RCON 或 `Core.Permission` 层；普通插件 ConVar 默认使用 `ConvarFlags.NONE`。

## 查找、写入与元数据

```csharp
IConVar<bool>? cheats = Core.ConVar.Find<bool>("sv_cheats");
IConVar? hostname = Core.ConVar.FindAsString("hostname");

if (hostname is not null)
{
    logger.LogInformation("hostname={Hostname}", hostname.ValueAsString);
}

// Value 走正常 set queue；需要立即内部生效时才使用 SetInternal。
ConVar_EnableFeature.Value = false;
ConVar_EnableFeature.SetInternal(true);

if (ConVar_MaxPlayers.TryGetMinValue(out int min)
    && ConVar_MaxPlayers.TryGetMaxValue(out int max)
    && ConVar_MaxPlayers.TryGetDefaultValue(out int defaultValue))
{
    logger.LogDebug("Range={Min}-{Max}, Default={Default}", min, max, defaultValue);
}
```

`SetInternal` 不会自动复制给客户端。未知类型使用 `FindAsString` / `ValueAsString` / `SetInternalAsString`；不要强行猜测 typed wrapper。

## 客户端交互

```csharp
ConVar_EnableFeature.ReplicateToClient(playerId, true);
ConVar_EnableFeature.QueryClient(playerId, value => logger.LogDebug("client value={Value}", value));

// 可下发服务器上未创建的客户端 ConVar。
Core.ConVar.ReplicateToClient(playerId, "cl_showfps", "1");
Core.ConVar.ReplicateToAll("cl_teamid_overhead_mode", "2");
```

实例 `ReplicateToClient` 适合已有 typed ConVar；service-level replication 是按名称下发，不能被用来推断服务器已存在同名 ConVar。

## 模块级 ConVar 自注册

大型模块化插件中，每个模块在 `OnActivate()` 中创建并管理自己的 ConVar：

```csharp
public class MyModule : IModule
{
    private IConVar<bool>? _enableConVar;

    public void OnActivate()
    {
        // 按名称创建或获取既有项，避免重复注册错误。
        _enableConVar = Core.ConVar.CreateOrFind(
            "sw_mymodule_enable",
            "启用此模块",
            true,
            ConvarFlags.NONE);
    }
}
```

## Checklist

- [ ] ConVar 名称是否遵循 `sw_插件名_功能` 命名？
- [ ] 是否按“重复即错误”或“复用同名项”选择 `Create` / `CreateOrFind`？
- [ ] 是否没有把 `ConvarFlags.SERVER_CAN_EXECUTE` 当作权限控制？
- [ ] 带范围的数值 ConVar 是否设置了合理的 min / max？
- [ ] 展示既有 ConVar 的 min/max/default 时是否使用安全的 `TryGet*` API？
- [ ] 是否正确区分正常 `Value` 写入、`SetInternal` 立即内部写入和客户端 replication？
- [ ] 是否使用 `required` 属性确保初始化？
- [ ] ConVar 是否在 `Load()` 或 `OnActivate()` 中集中注册？
- [ ] 是否避免在热路径中频繁读取 ConVar（可缓存到本地变量）？
