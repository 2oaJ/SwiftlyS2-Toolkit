# SwiftlyS2 热路径 / 性能 / GC Checklist

对应官方文档：
- `Profiler`
- `Thread Safety`
- `Native Functions and Hooks`

用于：Hook、高频循环、状态同步、菜单回调、Scheduler 周期任务、主线程关键路径的性能自审与代码审计。

系统性优化时先看：`../../../references/swiftlys2-performance-optimization-playbook.md`。

## 一、先判断这段代码是不是热路径

- [ ] 是否位于高频 Hook / RuntimeLoop / Bot 控制 / 其他高频刷新链路？
- [ ] 是否会被每 tick、每帧、每玩家反复执行？
- [ ] 是否运行在主线程，直接影响 64 tick 帧预算？

## 二、分配与 GC 风险

- [ ] 是否在热路径里频繁 `new List<>` / `new Dictionary<>` / `new[]`？
- [ ] 是否在循环内反复 `ToList()` / `ToArray()` / `OrderBy()` / `Where()` / `Select()`？
- [ ] 是否在循环内频繁构造 `string`、插值字符串、`string.Format`？
- [ ] 是否在热路径里创建临时 DTO、匿名对象、lambda 闭包？
- [ ] 是否存在隐式装箱？
- [ ] 固定长度小型临时数据是否可改为 `stackalloc` + `Span<T>`？
- [ ] 周期性文本拼接是否复用 `StringBuilder`？
- [ ] per-player 集合是否可挂在运行态对象上并用 `Clear()` 复用？

## 三、JSON / IO / 重 CPU 工作

- [ ] 是否避免在 Hook / 高频循环 / 菜单回调 / Scheduler 周期回调中做 JSON？
- [ ] 是否避免在热路径里做磁盘 IO、网络 IO、数据库查询、压缩、正则、大量排序？
- [ ] 是否已把主线程采样与后台序列化/聚合拆开？

## 四、算法与复杂度

- [ ] 是否在热路径里反复全量扫描所有玩家 / 所有记录？
- [ ] 是否把 `O(n)` / `O(n log n)` 工作错误放在每玩家每 tick 路径？
- [ ] 是否可改成 producer / consumer：热路径只采样，后台再聚合？
- [ ] 读多写少的聚合值是否应做 map-scope / player-scope cache？
- [ ] 高频采样是否应改为 ring buffer / 预分配数组？
- [ ] 异步写回是否携带 map generation 或 player generation token？

## 五、JIT / 编译 / native interop

- [ ] 极短热路径 helper 是否适合 `MethodImplOptions.AggressiveInlining`？
- [ ] 是否避免给大方法、IO 方法、复杂业务方法乱加 inlining hint？
- [ ] binary frame / native mirror 是否需要 `StructLayout` 固定布局？
- [ ] unmanaged callback / function pointer 的签名、大小、调用约定是否已复核？
- [ ] 项目级 `AllowUnsafeBlocks` / server GC / concurrent GC 是否确实符合插件场景？

## 六、落地原则

- 先保证正确性，再优化
- 先找真正热点，再优化；不要对低频路径过度微优化
- 先减少不必要分配，再考虑 `Span` / `stackalloc` / 更激进技巧
- 先做“不要进入热路径 / 进入后早退 / 重工作后台化”，再做微观 JIT 提示
