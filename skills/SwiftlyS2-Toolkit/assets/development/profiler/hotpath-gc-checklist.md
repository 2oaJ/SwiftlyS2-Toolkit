# SwiftlyS2 热路径 / 性能 / GC Checklist

对应官方文档：
- `Profiler`
- `Thread Safety`
- `Native Functions and Hooks`

用于：Hook、高频循环、状态同步、菜单回调、Scheduler 周期任务、主线程关键路径的性能自审与代码审计。

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

## 三、JSON / IO / 重 CPU 工作

- [ ] 是否避免在 Hook / 高频循环 / 菜单回调 / Scheduler 周期回调中做 JSON？
- [ ] 是否避免在热路径里做磁盘 IO、网络 IO、数据库查询、压缩、正则、大量排序？
- [ ] 是否已把主线程采样与后台序列化/聚合拆开？

## 四、算法与复杂度

- [ ] 是否在热路径里反复全量扫描所有玩家 / 所有记录？
- [ ] 是否把 `O(n)` / `O(n log n)` 工作错误放在每玩家每 tick 路径？
- [ ] 是否可改成 producer / consumer：热路径只采样，后台再聚合？

## 五、落地原则

- 先保证正确性，再优化
- 先找真正热点，再优化；不要对低频路径过度微优化
- 先减少不必要分配，再考虑 `Span` / `stackalloc` / 更激进技巧
