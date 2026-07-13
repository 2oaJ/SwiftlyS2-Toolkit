# Translations 入口说明

对应官方文档：
- `Translations`

优先关注：
- `resources/translations/*.jsonc`
- `Core.Localizer`
- `Core.Translation.GetPlayerLocalizer(player)`
- `en.jsonc` 兜底语言
- `category.subcategory.key` 命名方式

若场景涉及菜单或 HTML 文本，请联动：
- `../menus/menu-template.cs.md`
- `../../guides/html-styling/README.md`

## Server 与 Player localizer 的边界

- `Core.Localizer` 用于 server/default lookup，也可直接查自定义语言码。
- `Core.Translation.GetPlayerLocalizer(player)` 用于玩家游戏语言；它不会自动解析自定义语言码。
- `en.jsonc` 必须保留完整 key 基线，避免玩家语言不完整时失去文案。

```csharp
var serverText = Core.Localizer["plugin.ready"];
var playerText = Core.Translation.GetPlayerLocalizer(player)["round.win", "CT", 42];
```

所有语言文件保持相同 key 集合和 placeholder 顺序；使用索引器传参，不要在 C# 里拼接可翻译句子。
