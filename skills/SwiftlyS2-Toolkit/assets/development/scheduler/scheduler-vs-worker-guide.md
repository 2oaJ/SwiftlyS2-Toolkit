# SwiftlyS2 Scheduler vs Background Worker

对应官方文档：
- `Scheduler`
- `Thread Safety`

用于：避免把官方 `Scheduler` 的 tick/timer 语义，与后台 `Task.Run` / queue / flush / cancel worker 混为一谈。

## 优先用 Scheduler 的场景

- `NextTick` / 下一 Tick 执行
- 轻量延迟任务
- 低频周期任务
- 与地图生命周期强相关、适合 `StopOnMapChange` 的逻辑

## 优先用后台 Worker 的场景

- JSON 序列化 / 反序列化
- 磁盘 IO / 网络 IO / 数据库批处理
- producer / consumer 解耦
- 可取消的后台轮询
- 不应阻塞主线程的持续性工作

## 决策问题

- 这里是“下一 Tick 语义”，还是“真正的后台异步工作”？
- 这里是否需要访问主线程敏感 API？
- 这里是否需要 stop / flush / cancel / drain 队列语义？
- 这里是否会处理 JSON / IO / 大量批处理？

## 路线建议

- 若是主线程轻量延迟：继续看官方 `Scheduler`
- 若是后台队列/批处理：转 `../../patterns/background-workers/worker-template.cs.md`
