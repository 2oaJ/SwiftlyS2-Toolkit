# SwiftlyS2 Schema Write Checklist

对应官方文档：
- `Entity`
- `Thread Safety`
- `Porting from CounterStrikeSharp`

> 说明：本清单是基于官方 `Entity` / 线程安全 / CSS 迁移差异整理出的本地派生审查表，不是单页官网正文复制。

## 主线程要求

- [ ] Schema 写回是否明确发生在主线程？
- [ ] 是否避免在后台线程直接写实体字段？
- [ ] 若需异步处理，是否先采不可变快照？
- [ ] 若链路涉及 JSON DTO / 序列化，是否与主线程实体读写拆开？

## 写回通知要求

- [ ] 写回后是否需要调用 `Updated()`？
- [ ] 若任务涉及 CSS 迁移语义，是否确认是否还需 `SetStateChanged()`？
- [ ] 是否已确认当前字段的引擎 / 客户端同步语义？

### `*Updated()` 调用强制规则

**硬规则：** 修改实体 Schema 属性后，若该属性的变更需要同步到客户端（视觉效果、UI 状态、网络传播），必须调用对应的 `*Updated()` 方法。遗漏 `Updated()` 调用会导致服务端值已改但客户端无感知的静默故障。

**关键原则：每个 Schema 属性字段都有独立的 `Updated()` 方法。修改了哪个字段，就必须调用对应的 `Updated()`。** 例如同时修改了 `Render`（颜色）和 `RenderMode`（渲染模式），需要分别调用 `RenderUpdated()` 和 `RenderModeUpdated()`，不能只调其中一个。

### 常见属性与 Updated() 对照表

| 属性 | Updated() 方法 | 场景 |
| --- | --- | --- |
| `pawn.Render` (Color) | `pawn.RenderUpdated()` | 隐藏/显示/变色 |
| `pawn.RenderMode` | `pawn.RenderModeUpdated()` | kRenderNone 隐藏等 |
| `cameraServices.ViewEntity` | `cameraServices.ViewEntityUpdated()` | 第三人称/观察视角切换 |
| `weaponServices.ActiveWeapon` | `weaponServices.ActiveWeaponUpdated()` | 切换/清空手持武器 |
| `pawn.MoveType` | `pawn.MoveTypeUpdated()` | 穿墙/冰冻等 |
| `pawn.Health` | `pawn.HealthUpdated()` | 直接改血量 |
| `pawn.ArmorValue` | `pawn.ArmorValueUpdated()` | 直接改护甲 |
| `pawn.GravityScale` | `pawn.GravityScaleUpdated()` | 重力修改 |

### 正确示例

```csharp
// ✅ 同时修改 Render 和 RenderMode → 分别调用 Updated()
pawn.Render = new Color(255, 255, 255, 0);
pawn.RenderMode = RenderMode_t.kRenderNone;
pawn.RenderUpdated();
pawn.RenderModeUpdated();

// ✅ 恢复时同样需要
pawn.Render = new Color(r, g, b, a);
pawn.RenderMode = (RenderMode_t)prevMode;
pawn.RenderUpdated();
pawn.RenderModeUpdated();

// ✅ 视角切换
cameraServices.ViewEntity = cameraHandle;
cameraServices.ViewEntityUpdated();
```

### 错误示例

```csharp
// ❌ 修改了属性但没调用 Updated() → 客户端不会看到变化
pawn.Render = new Color(255, 255, 255, 0);
pawn.RenderMode = RenderMode_t.kRenderNone;
// 缺少 RenderUpdated() 和 RenderModeUpdated()

// ❌ 只调用了部分 Updated() → RenderMode 变更未同步
pawn.Render = new Color(255, 255, 255, 0);
pawn.RenderMode = RenderMode_t.kRenderNone;
pawn.RenderUpdated();
// 缺少 RenderModeUpdated()！Render 和 RenderMode 是两个独立的网络同步字段
```

## 生命周期与有效性

- [ ] 写回前是否确认 `IPlayer` / `Controller` / `Pawn` / entity 仍有效？
- [ ] 是否避免在断线、换图、卸载后对旧对象写回？
- [ ] 延迟回调是否重新获取当前对象，而不是复用旧引用？
- [ ] 若实体需跨 tick / 延迟长期跟踪，是否使用 `CHandle<T>`？

## 热路径风险

- [ ] 该 Schema 写回是否位于高频 Hook 中？
- [ ] 若在热路径中，是否避免无意义重复写入？
- [ ] 是否已评估 64 tick / 15ms 帧预算影响？
