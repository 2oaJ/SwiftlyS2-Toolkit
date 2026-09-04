# SwiftlyS2 运行维护配置指南

对应官方 Resources：`CLI Options`、`Core Configuration`、`Command Overrides`、`Console Filter`。

本页只做操作入口和边界说明。配置键、默认值和路径以当前官方 Resources 页面为准，避免把本地旧部署布局当成框架契约。

## 启动与日志

官方 CLI 选项包括：

- `-sw_path`：SwiftlyS2 相对 `game/csgo` 的安装路径。
- `-sw_logpath`：日志相对路径。
- `-sw_hide_logs_in_console`：保留文件日志但隐藏控制台 plugin 日志。
- `-sw_loglevel`：控制台最低显示级别。

变更启动参数后应重启目标服务器，并通过实际日志目录和启动输出确认生效。

## `core.jsonc`

`addons/swiftlys2/configs/core.jsonc` 负责全局命令前缀、静默前缀、热重载、插件装载顺序、菜单输入、默认语言、console filter 和 Steam auth 等框架级行为。

- 把它当作运维配置，不要让插件直接改写它。
- 对影响所有插件的字段，先记录变更动机、回退方式和服务器验证步骤。
- 手工插件装载、load order 或 Steam auth mode 的改动要以冷启动/热重载的实际结果验证。

## 命令权限覆盖

`addons/swiftlys2/configs/command_overrides.jsonc` 可以为已有命令重映射所需 permission，而不改插件代码。它只改变权限要求，不改变命令行为。

```jsonc
{
  "CommandOverrides": {
    "Permissions": {
      "sw_feature": "myplugin.feature.use"
    }
  }
}
```

使用精确命令名，并将该文件纳入服务器配置审计。

## Console Filter

Console filter 用于抑制已知噪声。官方页面的具体配置路径历史上出现过不一致表述，因此部署前先从当前安装目录确认 `confilter.jsonc` 的实际位置，再用 `sw confilter reload` / `status` 验证。

不要用 filter 隐藏未知异常或安全事件；规则应只针对已确认的可忽略输出。
