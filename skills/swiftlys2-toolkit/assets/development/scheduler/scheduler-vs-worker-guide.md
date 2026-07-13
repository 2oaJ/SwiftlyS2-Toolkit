# SwiftlyS2 Scheduler vs Background Worker

对应官方文档：
- `Scheduler`
- `Thread Safety`

用于：避免把官方 `Scheduler` 的 tick/timer 语义，与后台 `Task.Run` / queue / flush / cancel worker 混为一谈。

性能优化、后台队列和 map 初始化策略先看：`../../../references/swiftlys2-performance-optimization-playbook.md`。

## 优先用 Scheduler 的场景

- `NextTick` / 下一 Tick 执行
- 轻量延迟任务
- 低频周期任务
- 与地图生命周期强相关、适合 `StopOnMapChange` 的逻辑

## 当前 Scheduler 契约

| 需求 | API | 约束 |
| --- | --- | --- |
| 下一 server tick | `NextTick(Action)` | callback 必须是同步 `Action` |
| 下一 world update 阶段 | `NextWorldUpdate(Action)` | callback 必须是同步 `Action` |
| 等待一次主线程执行 | `NextTickAsync(Action)` / `NextWorldUpdateAsync(Action)` | await 同步 callback 的完成 |
| 一次延迟 / 周期任务 | `Delay*` / `Repeat*` / `DelayAndRepeat*` | 返回该 timer 自己的 `CancellationTokenSource` |
| 动态间隔 | `AddTimer(ctx => TimerStep...)` | `ExecutionCount` 首次为 0，可返回 `Spin` / `Wait` / `Stop` |

- 所有接收 `Func<Task...>` 的 `NextTick` / `NextWorldUpdate` overload 已过时且 unsafe，会抛 `InvalidOperationException`。不要向 scheduler 传 async lambda。
- `Repeat*` 第一次会立即执行；秒级 timer 仍由 game tick 驱动，过小间隔接近一个 tick 的精度。
- `StopOnMapChange(cts)` 只绑定**传入的那个 CTS**。保存 `Delay` / `Repeat` / `AddTimer` 的返回值并显式绑定；不要把另一个业务 CTS 当作 timer 已自动取消的证据。

## 优先用后台 Worker 的场景

- JSON 序列化 / 反序列化
- 磁盘 IO / 网络 IO / 数据库批处理
- producer / consumer 解耦
- 可取消的后台轮询
- 不应阻塞主线程的持续性工作
- 文件扫描、压缩、回放 / 采样持久化

## 决策问题

- 这里是“下一 Tick 语义”，还是“真正的后台异步工作”？
- 这里是否需要访问主线程敏感 API？
- 这里是否需要 stop / flush / cancel / drain 队列语义？
- 这里是否会处理 JSON / IO / 大量批处理？
- 队列是否需要容量上限、批处理上限和背压策略？
- 回主线程写回前是否需要 map generation / player generation 校验？

## 路线建议

- 若是主线程轻量延迟：继续看官方 `Scheduler`
- 若是后台队列/批处理：转 `../../patterns/background-workers/worker-template.cs.md`
- 若是地图加载、区域加载、排行榜加载、目录扫描：采用 generation + cancel previous + immutable DTO + main-thread commit

## 最小 map-scoped timer 模式

```csharp
private CancellationTokenSource? _mapWorkCts;
private CancellationTokenSource? _periodicTimerCts;

private void StartMapRuntime()
{
    _mapWorkCts?.Cancel();
    _mapWorkCts?.Dispose();
    var mapWorkCts = new CancellationTokenSource();
    _mapWorkCts = mapWorkCts;
    Core.Scheduler.StopOnMapChange(mapWorkCts);

    _periodicTimerCts?.Cancel();
    _periodicTimerCts?.Dispose();
    var periodicTimerCts = Core.Scheduler.RepeatBySeconds(1.0f, TickRuntime);
    _periodicTimerCts = periodicTimerCts;
    Core.Scheduler.StopOnMapChange(periodicTimerCts);
}
```

`_mapWorkCts` 负责业务 async 工作，`_periodicTimerCts` 负责 scheduler timer。两者不是同一个所有权对象。
