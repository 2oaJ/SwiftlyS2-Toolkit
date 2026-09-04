# SwiftlyS2 Attribute 注册检查清单

对应官方文档：
- `Using attributes`
- `Commands`
- `Core Events`

用于：确认 `[Command]`、`[CommandAlias]`、事件 attribute、Hook attribute 等是否注册在正确对象上。

## 核心规则

- attribute 默认只在继承 `BasePlugin` 的主类里可直接生效。
- 若在其他 class / service / module 中使用 attribute，必须先调用：
  - `Core.Registrator.Register(this)`
- 若该对象会被卸载或重建，必须确认它的生命周期与注册时机匹配。

## 检查项

- [ ] 当前 attribute 所在类型是否就是插件主类？
- [ ] 若不是主类，是否在实例化后显式 `Core.Registrator.Register(this)`？
- [ ] 该对象是否会重复构造？若会，是否避免重复注册？
- [ ] 若改成 service / module 承载 attribute，是否真的比程序化注册更合适？
- [ ] 若需要动态启停、条件性卸载、精确回收，是否更应该使用程序化注册而不是 attribute？

## 何时优先 attribute

- 小型 partial 插件
- 固定生命周期、无条件注册的命令 / 监听
- 入口简单、结构清晰的场景

## 何时优先程序化注册

- 需要保存 `Guid` 并精确卸载
- 需要按配置动态启停
- 需要由 service 自持生命周期
- 需要把注册责任和业务责任收拢在同一 owning service 中
