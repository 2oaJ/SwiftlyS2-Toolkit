# Configuration 入口说明

对应官方文档：
- `Configuration`

优先关注：
- `Core.Configuration`
- `InitializeJsonWithModel<T>` / `InitializeTomlWithModel<T>`
- `Configure(builder => ...)`
- `IOptionsMonitor<T>`
- `reloadOnChange`

本目录包含：
- `config-hot-reload-template.cs.md`：Config + IOptionsMonitor 热加载完整模板

配置场景通常与以下联动使用：
- `guides/dependency-injection/di-service-plugin-template.cs.md`
- `guides/dependency-injection/service-template.cs.md`

## Config 与 ConVar 的分工

- **Config (JSONC)**：结构化配置、嵌套对象、数组、默认值管理、文件持久化
- **ConVar**：运行时控制台即时调参、管理员临时调整
- 混用时：ConVar 做开关/微调，Config 做结构化默认值

ConVar 相关文档见 `../convars/convar-template.cs.md`。
