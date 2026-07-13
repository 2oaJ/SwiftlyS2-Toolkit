# Permissions 入口说明

对应官方文档：
- `Permissions`

优先关注：
- `Core.Permission.PlayerHasPermission(...)`
- `Core.Permission.PlayerHasPermissions(...)`
- wildcard `*`
- `permissions.jsonc`
- permission groups / `__default`
- `AddSubPermission(parent, child)` / `RemoveSubPermission(parent, child)`
- `ClearPermissions(steamId)`

## 当前语义

- `PlayerHasPermissions(steamId, permissions)` 要求传入集合中的**全部**权限满足，不是 any-of 检查。
- 诊断实际生效权限时使用 `GetPlayerPermissions(steamId)`，它包含继承得到的权限。
- 新代码使用 `ClearPermissions` 清除直接权限；不要新增已废弃的 `ClearPermission` 调用。

最小组配置结构：

```jsonc
{
  "Permissions": {
    "Players": {
      "76561198135539332": ["admins"]
    },
    "PermissionGroups": {
      "__default": ["myplugin.help"],
      "admins": ["myplugin.admin.*"]
    }
  }
}
```

`__default` 会应用给所有玩家。所有 mutating permission 操作仍须有插件卸载或管理动作的审计路径，避免把临时授权写成长期状态。

常见联动场景：
- 命令权限：`../commands/`
- 菜单可见性：`../menus/menu-template.cs.md`
- Shared API / 跨插件能力分级：`../shared-api/shared-interface-template.cs.md`
