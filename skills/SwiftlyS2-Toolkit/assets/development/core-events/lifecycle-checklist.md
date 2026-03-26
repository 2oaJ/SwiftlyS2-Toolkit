# SwiftlyS2 生命周期检查清单

对应官方文档：
- `Core Events`
- `Thread Safety`
- `Scheduler`

> 说明：本清单以 `Core Events` 为入口，但覆盖玩家、地图、worker、service 的完整生命周期闭环。

## 玩家生命周期

- [ ] `OnClientPutInServer` 是否完成 attach / 初始化？
- [ ] `OnClientDisconnected` 是否完成 detach / cleanup？
- [ ] 断线后是否仍有延迟逻辑持有旧 `IPlayer`？
- [ ] 玩家状态切换后，状态是否仍一致？
- [ ] fake client 与真实玩家流程是否已尽早分流？

## 地图生命周期

- [ ] `OnMapLoad` 是否清理 map-scoped 缓存？
- [ ] `OnMapUnload` 是否停止 worker / 自动控制实体 / runtime loop？
- [ ] 地图切换后是否有旧地图对象残留状态？
- [ ] `OnPrecacheResource` 是否注册了所有自定义模型/声音/粒子？
- [ ] map-scoped 的 `CancellationTokenSource` 是否通过 `StopOnMapChange` 绑定？

## 异步与后台任务

- [ ] worker 是否具备 stop / flush / cancel 语义？
- [ ] 异步回调是否重新获取 player/state，而不是盲用旧引用？
- [ ] 是否避免 `.Wait()` / `.Result` / 主线程阻塞？
- [ ] 从同步入口发起的异步任务是否实现了 fire-and-forget 安全包装（`async void` 次层捕获异常并记录，避免未观察任务异常）？
- [ ] 异步回写是否经过代际校验或状态有效性校验？

## 模块 / service 生命周期

- [ ] 插件 root 是否只负责安装顺序 / 卸载顺序？
- [ ] 每个独立 service 注册的 Event / Hook / Command 是否都能在自身 `Uninstall()` / `Cleanup()` 中闭环清理？
- [ ] 条件性 hook 是否通过内部状态标记动态挂卸？

## 高频 Hook / 热路径

- [ ] 是否尽早过滤无效玩家 / fake client / dead player？
- [ ] 是否避免热路径日志与 IO？
- [ ] 是否避免多余分配？
