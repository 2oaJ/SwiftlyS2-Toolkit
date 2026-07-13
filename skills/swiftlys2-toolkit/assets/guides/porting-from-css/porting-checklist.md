# CounterStrikeSharp 到 SwiftlyS2 迁移检查清单

对应官方文档：`Porting from CounterStrikeSharp`。

迁移的目标是当前 SwiftlyS2 单一路径，不是为旧 CSS API 增加 adapter 或 fallback。发现未迁移调用方时，先列出证据和影响，再由用户决定是否需要兼容层。

## 关键替换边界

| CSS 习惯 | SwiftlyS2 当前方向 |
| --- | --- |
| `SetStateChanged` | 使用当前字段所需的 `Updated()`，不要保留 CSS 式通知调用 |
| `DynamicHook` / CSS HookMode 迁移写法 | 优先 `Core.GameHooks`；仅未覆盖时用 exact delegate + `Core.Memory` |
| 旧 Core `On*Hook` | 查对应 `Core.GameHooks` 分类和 Pre/Post context |
| 旧 command / service wrapper | `Core.Command`、`ICommandContext.Args` 和当前 `[Command]` API |
| live player/entity 跨异步保留 | 保存 stable id / `SessionId` / `CHandle<T>`，延迟后重新解析校验 |

## 迁移顺序

1. 先对齐 `.csproj`、目标 .NET、包和 plugin metadata。
2. 迁移 Core、配置、翻译、命令和菜单等基础入口。
3. 将 lifecycle listeners 与 GameEvents 按实际语义分开。
4. 将 typed entity/movement/controller hook 迁到 `Core.GameHooks`，逐个确认 Pre/Post 结果和上下文生命周期。
5. 最后处理 GameData、Memory 和 native interop，并在目标服务器上验证签名。

## 验证

- [ ] build 通过之外，是否覆盖 map load/unload、connect/disconnect、热重载？
- [ ] 是否删除了旧 API，而非在新旧路径之间并行执行？
- [ ] 是否验证了 GameHooks 的 Pre/Post、取消行为和 hook 卸载？
- [ ] 是否验证了 async 后 player/entity 重取和 bot 路径？
