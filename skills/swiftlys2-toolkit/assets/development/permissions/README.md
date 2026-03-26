# Permissions 入口说明

对应官方文档：
- `Permissions`

优先关注：
- `Core.Permission.PlayerHasPermission(...)`
- wildcard `*`
- `permissions.jsonc`
- permission groups / `__default`
- `AddSubPermission(parent, child)`

常见联动场景：
- 命令权限：`../commands/`
- 菜单可见性：`../menus/menu-template.cs.md`
- Shared API / 跨插件能力分级：`../shared-api/shared-interface-template.cs.md`
