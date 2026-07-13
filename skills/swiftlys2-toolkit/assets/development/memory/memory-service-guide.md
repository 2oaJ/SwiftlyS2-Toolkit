# SwiftlyS2 Memory Service 指南

对应官方文档：`Memory` API、`Native Functions and Hooks`。

本页只覆盖地址发现、wrapper 和内存所有权。要安装 raw native hook 或 mid-hook，转到 `../native-functions-and-hooks/hook-handler-template.cs.md`；已由 typed API 覆盖的游戏行为，先看 `../game-hooks/game-hooks-pre-post-guide.md`。

## 地址发现

```csharp
using SwiftlyS2.Shared.Memory;

nint? address = Core.Memory.GetAddressBySignature(
    Library.Server,
    "55 8B EC 83 EC 08 8B 45 08 5D C3");

if (address is null)
{
    logger.LogWarning("Signature was not found in the current server binary.");
    return;
}
```

`Core.Memory` 还提供 interface、vtable 和 cross-reference 解析。所有查找结果都可能失效或不匹配当前服务器二进制，必须先判断返回值，再进入更低层的包装或调用。

## 分配所有权

```csharp
var block = Core.Memory.Alloc(256);
try
{
    // 只在当前同步 native 操作中使用 block。
}
finally
{
    Core.Memory.Free(block);
}
```

`Alloc`、`Resize`、`Free` 必须由同一组件建立明确所有权。不要把 raw pointer、`Address` 或 native wrapper 缓存到无边界的静态状态，也不要跨 `await`、worker 或地图生命周期传递它们。

## 审计边界

- 签名、vtable index、calling convention 和 native layout 必须来自当前可验证来源。
- `SchemaUntypedField.Address` 和类似 raw address 是危险 API，优先 schema typed accessor；确有必要时将使用范围收缩到一个同步方法。
- 任何内存 API 改动都需要真实服务器验证，build 通过不是地址正确的证据。
