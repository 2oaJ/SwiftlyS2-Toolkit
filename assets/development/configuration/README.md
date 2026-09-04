# Configuration 入口说明

对应官方文档：
- `Configuration`

优先关注：
- `Core.Configuration`
- `BasePath` / `BasePathExists` / `GetConfigPath`
- `InitializeWithTemplate` / `InitializeJsonWithModel<T>` / `InitializeTomlWithModel<T>`
- `Configure(builder => ...)`
- `IOptionsMonitor<T>`
- `reloadOnChange`

本目录包含：
- `config-hot-reload-template.cs.md`：Config + IOptionsMonitor 热加载完整模板

配置场景通常与以下联动使用：
- `guides/dependency-injection/di-service-plugin-template.cs.md`
- `guides/dependency-injection/service-template.cs.md`

## 初始化规则

- `GetConfigPath("config.jsonc")` 接收含扩展名的文件名，用于诊断或需要给外部库传路径的场景。
- `InitializeWithTemplate` 从插件的 `templates` 目录复制初始文件。
- `InitializeJsonWithModel<T>` 与 `InitializeTomlWithModel<T>` 只在目标文件不存在时按 model 创建，不会覆盖运营人员已修改的配置。
- JSONC 和 TOML 都可通过 `Configure` 注册为 reload-on-change source；DI 中用相同 section 名通过 `AddOptionsWithValidateOnStart<T>().BindConfiguration(...)` 绑定。

```csharp
Core.Configuration
    .InitializeJsonWithModel<MainConfig>("config.jsonc", "Main")
    .InitializeTomlWithModel<DatabaseConfig>("database.toml", "Database")
    .Configure(builder =>
    {
        builder.AddJsonFile("config.jsonc", optional: false, reloadOnChange: true);
        builder.AddTomlFile("database.toml", optional: false, reloadOnChange: true);
    });
```

不要在热加载回调里做阻塞 IO、直接保存 live player/entity wrapper 或无所有权地重装 timer/hook。先比较新旧配置，再由 owning service 完成对称停启。

## Config 与 ConVar 的分工

- **Config (JSONC)**：结构化配置、嵌套对象、数组、默认值管理、文件持久化
- **ConVar**：运行时控制台即时调参、管理员临时调整
- 混用时：ConVar 做开关/微调，Config 做结构化默认值

ConVar 相关文档见 `../convars/convar-template.cs.md`。
