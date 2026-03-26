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

## 生命周期与有效性

- [ ] 写回前是否确认 `IPlayer` / `Controller` / `Pawn` / entity 仍有效？
- [ ] 是否避免在断线、换图、卸载后对旧对象写回？
- [ ] 延迟回调是否重新获取当前对象，而不是复用旧引用？
- [ ] 若实体需跨 tick / 延迟长期跟踪，是否使用 `CHandle<T>`？

## 热路径风险

- [ ] 该 Schema 写回是否位于高频 Hook 中？
- [ ] 若在热路径中，是否避免无意义重复写入？
- [ ] 是否已评估 64 tick / 15ms 帧预算影响？
