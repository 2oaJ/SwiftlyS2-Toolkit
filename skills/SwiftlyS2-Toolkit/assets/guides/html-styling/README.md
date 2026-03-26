# SwiftlyS2 HTML Styling 指南

对应官方文档：
- `HTML Styling`
- `Menus`

本页的目标不是简单提醒“能写 HTML”，而是把 **SwiftlyS2 / Panorama 富文本真正可直接落地的规则** 提炼出来，方便 agent 在写 `SendCenterHTML`、菜单格式化、动态文本、提示类 UI 时直接套用。

## 先记住三个结论

1. **Panorama 不是浏览器。** 不要把普通网页 HTML/CSS 的经验原样搬过来。
2. **样式不是 `style="..."`。** Panorama UI 里常用的是“直接属性 + 内建 class”。
3. **复杂效果必须进游戏实测。** 能被解析，不代表显示就符合预期。

## 支持范围

### 官方列出的常用标签

官方 `HTML Styling` 页明确列出 Panorama UI 常见可用标签：

- `div`
- `span`
- `p`
- `a`
- `img`
- `br`
- `hr`
- `h1-h6`
- `strong`
- `em`
- `b`
- `i`
- `u`
- `pre`

### 推荐默认标签

如果没有特殊需求，优先只用：

- `span`：行内着色、字号、强调
- `br`：换行
- `div` / `p`：块级分段

原因：

- `span + br` 足以覆盖大部分中心提示、菜单附加文本、状态信息
- 标签越少，渲染偏差越小
- agent 更容易稳定生成可用片段

### 不要默认使用的写法

- 不要默认使用网页常见的 `style="..."`
- 不要默认使用未在官方列出的标签
- 不要假设 `<font>` 一定可靠

> 工具包约定：若只是文字着色/字号/强调，优先使用 `<span ...>`，不要生成 `<font ...>`。

## Panorama 样式语法

### 1）直接属性，而不是 `style="..."`

正确示例：

```csharp
var html = "<span color=\"red\">危险提示</span>";
```

错误示例：

```csharp
var html = "<span style=\"color:red\">危险提示</span>";
```

官方强调：Panorama UI 的样式属性通常直接写成标签属性，而不是塞进 `style`。

### 2）优先使用内建 class

正确示例：

```csharp
var html = "<span class=\"fontSize-l fontWeight-bold\">大号粗体</span>";
```

常见好处：

- 比手写零散属性更稳定
- 与游戏内置样式体系更一致
- 升级时更容易统一调整

### 3）属性与 class 可以组合

```csharp
var html = "<span color=\"green\" class=\"fontSize-l\">就绪</span>";
```

适合场景：

- 用 `class` 管字号/风格
- 用 `color` 管动态颜色

## 常用样式元素

### 颜色

官方示例与页面中出现的常见颜色包括：

- `red`
- `green`
- `yellow`
- `gold`
- `lightyellow`
- `lightblue`
- `darkblue`
- `purple`
- `magenta`
- `grey`
- `silver`
- `olive`
- `lime`
- `lightred`

也可以使用十六进制颜色，例如：

```csharp
var html = "<span color=\"#5E98D9\">CT</span>";
```

建议：

- 需要和阵营、状态绑定时，优先用显式 hex
- 普通成功/失败/警告文案，优先用语义色名

### 常见字号 class

官方页面列出的字号 class：

- `fontSize-xs`
- `fontSize-sm`
- `fontSize-m`
- `fontSize-l`
- `fontSize-xl`
- `fontSize-xxl`

推荐约定：

- 正文：`fontSize-m`
- 次级说明：`fontSize-sm`
- 重要提示：`fontSize-l`
- 倒计时/大数字：`fontSize-xl` / `fontSize-xxl`

### 常见风格 class

官方页面列出的常见 class 包括：

- `fontStyle-m`
- `fontWeight-bold`
- `CriticalText`

推荐用法：

- `fontWeight-bold`：强调
- `CriticalText`：风险/警告/失败态
- `fontStyle-m`：普通统一字体风格

## 典型落地场景

### 1）中心提示 / 倒计时 / 状态播报

适合：

- `Core.PlayerManager.SendCenterHTML(...)`
- 轮次提示
- ready 状态统计
- 倒计时

示例：

```csharp
var timeLeft = 8;
var color = timeLeft <= 3 ? "red" : timeLeft <= 5 ? "yellow" : "green";
var html = $"<span class=\"fontSize-l\">回合即将开始</span><br><span color=\"{color}\" class=\"fontSize-xxl\">{timeLeft}</span>";

Core.PlayerManager.SendCenterHTML(html, 1);
```

生成规则：

- 标题和数值分两行
- 变化部分只放到颜色/数字里
- 持续时间和刷新频率一起设计，不要只顾视觉不顾刷屏

### 2）菜单附加说明 / 动态摘要

适合：

- `TextMenuOption`
- `BindingText`
- 菜单顶部摘要

示例：

```csharp
var option = new TextMenuOption
{
	BindingText = () => $"<span class=\"fontSize-sm\">模式：<span color=\"green\">{runtime.ModeName}</span><br>音量：<span color=\"yellow\">{runtime.Volume}</span></span>"
};
```

建议：

- 动态值放内层 `span`
- 容易变的字段单独包颜色
- `BindingText` 内只做轻量字符串拼装，不做 IO / 数据库 / JSON

### 3）菜单 `BeforeFormat` / `AfterFormat`

官方菜单文档说明菜单选项支持 `BeforeFormat` / `AfterFormat`。这两个事件经常会和 HTML Styling 联动。

推荐：

- `BeforeFormat`：改“语义文本”
- `AfterFormat`：补“HTML 表现”

示例：

```csharp
option.BeforeFormat += (_, args) =>
{
	args.CustomText = $"[VIP] {args.Option.Text}";
};

option.AfterFormat += (_, args) =>
{
	args.CustomText = $"<span color=\"#FFD700\">{args.CustomText}</span>";
};
```

注意：

- `AfterFormat` 里也优先用 `<span>`，不要默认生成 `<font>`
- 不要在格式化事件里查询远端数据

## 常见字符串拼装建议

### 优先使用 `$"..."`

```csharp
var html = $"<span color=\"green\">{playerName}</span> 已就绪";
```

比字符串相加更清晰，也更适合 agent 扩展。

### 拆标题 / 明细 / 数值，再组合

```csharp
var title = "<span color=\"yellow\" class=\"fontSize-l\">服务器规则</span>";
var line1 = "<span>• 禁止作弊</span>";
var line2 = "<span>• 禁止恶意卡点</span>";
var html = $"{title}<br><br>{line1}<br>{line2}";
```

这样更适合：

- 翻译替换
- 条件拼装
- 根据玩家状态插入/删除某一行

### 动态颜色先算变量，再插值

```csharp
var statusColor = isReady ? "green" : "red";
var html = $"<span>{playerName}</span>：<span color=\"{statusColor}\">{statusText}</span>";
```

不要把复杂三元表达式直接塞进 HTML 片段里，易读性会掉到地下室。

## 与其他资产的联动

### 菜单

- 菜单模板：`../../development/menus/menu-template.cs.md`
- 关注点：`BindingText`、`BeforeFormat`、`AfterFormat`、异步回调有效性校验

### 翻译

- 翻译入口：`../../development/translations/README.md`

建议：

- 翻译 key 尽量保留“语义片段”，颜色和 class 在最终拼装层处理
- 若翻译文本中必须包含 HTML，需明确约定哪些占位符可安全注入

### 线程安全

- HTML 字符串拼装本身通常不是线程敏感点
- 但**用于生成 HTML 的玩家/实体数据**可能涉及线程敏感 API
- 若在异步回调中拼装 UI 文本，先确认所读取状态是否已快照化

## class 发现路径

官方 HTML Styling 页给出的扩展入口是：

- `https://github.com/SteamDatabase/GameTracking-CS2/tree/master/game/core/pak01_dir/panorama/styles`

该目录可用于：

- 查内建 Panorama class
- 观察 `panorama_base.css`、`gamestyles.css` 等文件中的命名风格
- 跟随 CS2 更新确认新 class 是否出现

推荐查找顺序：

1. 先用本页列出的常用 class
2. 不够用时去 SteamDatabase styles 目录查 `panorama_base.css` / `gamestyles.css`
3. 真正采用新 class 前，先进游戏验证

## agent 生成规则

当 agent 需要输出 HTML 片段时，优先遵守以下规则：

1. 默认使用 `span + br`
2. 默认使用 `<span color="..."></span>`，不要生成 `style="..."`
3. 字号优先使用 `fontSize-*` class，不手写复杂字体属性
4. 强调优先使用 `fontWeight-bold` 或 `CriticalText`
5. 菜单动态文本优先 `BindingText`
6. 格式化事件里只做轻量字符串变换
7. 复杂布局要提示“需进游戏验证”

## 常见反模式

### 反模式 1：把网页 CSS 写法搬进来

```csharp
"<span style=\"color:red;font-size:24px\">警告</span>"
```

应改为：

```csharp
"<span color=\"red\" class=\"fontSize-xl\">警告</span>"
```

### 反模式 2：在 `BindingText` / `AfterFormat` 里做重逻辑

不要：

- 访问数据库
- 发 HTTP
- 做大对象序列化/反序列化
- 在热刷新 UI 中反复拼大段复杂结构

### 反模式 3：为了炫技生成深层嵌套 HTML

Panorama 能解析，不代表玩家端一定稳定显示。

对于提示类 UI，优先：

- 一层标题
- 一层数值/状态
- `br` 分行

## 最后检查清单

- [ ] 是否避免了 `style="..."`？
- [ ] 是否优先用了 `span`、`br`、内建 class？
- [ ] 是否把动态值和固定文案分开拼装？
- [ ] 是否避免在动态文本回调里做重逻辑？
- [ ] 是否明确需要进游戏实测？
