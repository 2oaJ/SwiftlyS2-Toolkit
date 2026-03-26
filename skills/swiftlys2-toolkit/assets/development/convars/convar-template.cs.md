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
| 类型支持 | bool/int/float/string | 任意 C# 对象 |
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
            ConvarFlags.SERVER_CAN_EXECUTE   // 权限标志
        );

        // 带范围约束的 int ConVar（-1 = 不限制，0 = 禁用，>0 = 具体值）
        ConVar_MaxPlayers = Core.ConVar.CreateOrFind(
            "sw_myplugin_max_players",
            "最大玩家数量限制 (-1=不限制)",
            -1,                              // 默认值
            -1, 64,                          // min, max
            ConvarFlags.SERVER_CAN_EXECUTE
        );

        // float ConVar
        ConVar_SpeedMultiplier = Core.ConVar.CreateOrFind(
            "sw_myplugin_speed_mult",
            "速度倍率",
            1.0f,
            0.1f, 10.0f,
            ConvarFlags.SERVER_CAN_EXECUTE
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

## 模块级 ConVar 自注册

大型模块化插件中，每个模块在 `OnActivate()` 中创建并管理自己的 ConVar：

```csharp
public class MyModule : IModule
{
    private IConVar<bool>? _enableConVar;

    public void OnActivate()
    {
        // CreateOrFind 是幂等的，模块重载安全
        _enableConVar = Core.ConVar.CreateOrFind(
            "sw_mymodule_enable",
            "启用此模块",
            true,
            ConvarFlags.SERVER_CAN_EXECUTE);
    }
}
```

## Checklist

- [ ] ConVar 名称是否遵循 `sw_插件名_功能` 命名？
- [ ] 是否通过 `ConvarFlags.SERVER_CAN_EXECUTE` 限制修改权限？
- [ ] 带范围的数值 ConVar 是否设置了合理的 min / max？
- [ ] 是否使用 `required` 属性确保初始化？
- [ ] ConVar 是否在 `Load()` 或 `OnActivate()` 中集中注册？
- [ ] 是否避免在热路径中频繁读取 ConVar（可缓存到本地变量）？
