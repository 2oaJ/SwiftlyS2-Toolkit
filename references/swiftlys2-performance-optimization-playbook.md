# SwiftlyS2 Performance Optimization Playbook

本手册用于指导 agent 在 SwiftlyS2 插件中做性能优化、热路径审计和高频运行态重构。

它不绑定任何具体项目。使用时应先识别当前代码属于哪一类热点，再按对应模式落地，而不是笼统地说“减少 GC”或“优化 Hook”。

## 0. 优化前先分类

先把目标代码放入一个或多个类别：

| 类别 | 常见位置 | 主要风险 | 优先优化方向 |
| --- | --- | --- | --- |
| Hook 热路径 | native hook、movement hook、high-frequency event | 每 tick / 每玩家重复执行 | 早退、降频、减少分发、无 IO |
| 玩家运行态 | per-player state、HUD state、timer state | 多字典查找、断线重连脏写 | slot state、generation token、统一清理 |
| 采样缓冲 | movement samples、replay frames、trace samples | 每帧分配、数组扩容 | ring buffer、预分配、不可变快照 |
| 后台工作 | JSON、文件、网络、数据库、压缩 | 主线程卡顿、队列积压 | bounded queue、batch drain、backpressure |
| 地图级初始化 | zone/map/rank/static entity scan | 旧异步任务污染新地图 | map generation、cancel previous、main-thread commit |
| UI / HUD 文本 | periodic HUD、menus、status text | 字符串和 LINQ 分配 | StringBuilder 复用、状态变化刷新、节流 |
| Native / binary interop | signatures、protobuf mirror、native callbacks | layout 错误、调用桥成本 | StructLayout、unmanaged callback、签名审计 |

若代码不在这些类别中，先不要微优化。先证明它会频繁运行、影响主线程帧预算，或引发可观测卡顿 / GC / 队列积压。

## 1. Hook 热路径优化

### 1.1 先决定是否需要这个 Hook

不要默认启用最细粒度 Hook。

优先级：

1. 可由低频 Scheduler / 状态差分解决：不要挂高频 Hook。
2. 可由 movement 阶段 Hook 解决：不要升级到 usercmd 级 Hook。
3. 必须逐输入帧精度：才考虑 usercmd / command-level Hook。

### 1.2 Hot Hook 标准入口

高频 Hook 的入口顺序应接近：

1. 当前功能 / 当前 timer / 当前 mode 是否启用。
2. player / pawn / controller 是否存在且有效。
3. 是否需要排除 fake client / bot。
4. 是否能取得当前玩家运行态。
5. 是否存在订阅者 / forward / module。
6. 只构造最小快照或调用轻量分发。

示例形状：

```csharp
var runtime = runtimeProvider.Current;
if (runtime is null || !runtime.Enabled)
    return ContinueOriginal();

var player = ResolvePlayer();
if (player is null || !player.IsValid || player.IsFakeClient)
    return ContinueOriginal();

var state = playerStateRegistry.TryGet(player.PlayerID);
if (state is null || !state.IsCurrent(player))
    return ContinueOriginal();

var subscribers = runtime.MovementSubscribers;
if (subscribers.Count == 0)
    return ContinueOriginal();

var snapshot = BuildSmallSnapshot(player);
foreach (var subscriber in subscribers)
    subscriber.OnSample(state, snapshot);
```

### 1.3 Hook 内禁止项

高频 Hook 内默认禁止：

- JSON serialize / deserialize
- 文件、网络、数据库 IO
- 高频日志、聊天提示、控制台输出
- 全量排序、目录递归、全玩家全记录扫描
- `Task.Wait()` / `.Result` / 同步 join
- 每帧 `new List<>` / `new[]` / `ToArray()` / `ToList()`

### 1.4 Hook 分发治理

- Hook 是采样和治理层，不是业务堆叠层。
- 业务逻辑应下沉到 module / service。
- 每个 Hook 要有清晰的 Install / Uninstall。
- 条件性 Hook 应在条件满足时安装，在条件失效时卸载，不要长期空转。
- Profiler 名称要成对、稳定、可按阶段区分，例如 `MyHook.PreDispatch` / `MyHook.PostDispatch`。
- typed controller/entity/item/movement/pawn/weapon hook 优先从 `Core.GameHooks` 选择；raw native hook 只用于未被 typed API 覆盖的面。
- `ref struct` hook context、usercmd、temporary wrapper 只在当前回调栈帧使用，采样后复制普通值再投递后台。

## 2. 玩家运行态优化

### 2.1 状态归属

玩家运行态应集中到一个 per-player runtime object，而不是散落在多个 `Dictionary<ulong, TValue>` 中。

建议分层：

1. 小插件：`Dictionary<ulong, T>` 或 `ConcurrentDictionary<ulong, T>`。
2. 中型插件：`PlayerRuntime` 聚合多个字段和集合。
3. 高频插件：`PlayerRuntime?[]` 按 slot O(1) 访问，另保留 SteamID 辅助索引。
4. 跨异步写回：slot + generation / session token 校验。

### 2.2 Slot state 模式

适用条件：

- 每 tick / 每玩家访问运行态。
- 玩家槽位数量上限明确。
- 断线重连、bot、fake client、延迟回调较多。

模式：

```csharp
public readonly record struct PlayerToken(int Slot, int Generation);

public sealed class PlayerRuntime
{
    public int Slot { get; }
    public int Generation { get; private set; }
    public ulong SessionId { get; private set; }
    public bool Attached { get; private set; }

    public PlayerToken SnapshotToken() => new(Slot, Generation);
}
```

回写规则：

- 异步任务启动时保存 token。
- 回主线程写状态前校验 token。
- token 不匹配时丢弃结果，不做“兜底写回”。

### 2.3 生命周期清理

每个运行态字段必须知道清理点：

- disconnect：清玩家会话状态、取消玩家级 CTS。
- map unload / map reset：清地图绑定状态、预览实体、触发缓存。
- plugin unload：清所有状态、停止 worker、卸载 Hook。
- session reattach：重置旧会话字段，但保留可复用对象。

集合优先复用：

```csharp
runtime.TouchingZones.Clear();
runtime.PendingOutputs.Clear();
runtime.RecentSamples.Clear();
```

不要在高频 reset 中反复创建新集合，除非旧集合容量已经失控且有明确 shrink 策略。

## 3. 分配与 GC 优化

### 3.1 固定小数据用 stackalloc / Span

适用条件：

- 同步热路径。
- 小型固定长度数据。
- 不跨 `await`、不跨线程、不被闭包捕获。

示例：

```csharp
Span<Vector> points = stackalloc Vector[7];
FillBoundsSamples(origin, points);
if (zoneService.Overlaps(points, zone))
{
    // ...
}
```

不适用：

- 数据长度不可控。
- 需要保存到字段。
- 需要传入异步任务。

### 3.2 避免热路径 LINQ

热路径中优先手写循环替代：

- `Where(...).ToList()`
- `OrderBy(...).FirstOrDefault()`
- `Select(...).ToArray()`
- `Any(...)` 嵌套复杂闭包

示例：

```csharp
Item? firstEnabled = null;
foreach (var item in items)
{
    if (!item.Enabled)
        continue;

    firstEnabled = item;
    break;
}
```

### 3.3 文本构建

周期性 HUD / status text：

- 复用 `StringBuilder`。
- 按状态变化刷新，不要每 tick 全量拼接所有分支。
- 聊天提示和日志要节流。

示例：

```csharp
_builder ??= new StringBuilder(512);
_builder.Clear();
_builder.Append("Speed: ");
_builder.Append(speed);
```

### 3.4 对象池的边界

优先级：

1. 不分配。
2. 复用生命周期对象。
3. 预分配数组 / ring buffer。
4. 只有在大缓冲、大 byte array、高峰临时对象明确存在时，才考虑 `ArrayPool<T>` / object pool。

对象池不是默认优化手段。池化对象必须有清晰归还点，且不能携带旧玩家、旧地图、旧实体状态。

## 4. 采样缓冲与回放类数据

### 4.1 热路径采样只写轻量结构

每 tick 采样时只做：

- 读取必要字段。
- 写入 struct / small snapshot。
- 追加到预分配缓冲。

不要做：

- JSON
- 压缩
- 文件写入
- 大对象图复制
- 网络请求

### 4.2 Ring buffer

适用：

- 只需要最近 N 帧 / 最近 N 秒。
- pre-run、pre-event、debug sample。

```csharp
public void Write(in Sample sample)
{
    _buffer[_head] = sample;
    _head = (_head + 1) % _buffer.Length;
    if (_count < _buffer.Length)
        _count++;
}
```

### 4.3 线性预分配数组

适用：

- 正式运行期间需要保留完整序列。
- 可估算常见容量。

```csharp
if (_count >= _frames.Length)
{
    Array.Resize(ref _frames, Math.Max(_frames.Length * 2, _count + 1));
}
_frames[_count++] = frame;
```

长时间运行场景必须加上限、分段落盘或降级策略，不能无限扩容。

### 4.4 二进制批量编码

大量同构数值帧不应默认 JSON 化。可考虑：

- `struct` 表示帧。
- 固定布局。
- 批量转 bytes。
- JSON 仅保留 header / metadata。

边界：

- 固定布局必须有版本号。
- 字段顺序、大小、对齐变化要兼容或显式拒绝旧格式。
- 不要把普通业务 DTO 强行改成 binary layout。

## 5. 后台队列与 Worker

### 5.1 适用工作

放后台：

- JSON serialize / deserialize
- 文件读写、压缩、清理
- HTTP / DB / API 查询
- 目录扫描
- 聚合统计
- 可延后持久化

不放后台：

- 直接操作 player / pawn / entity
- Schema 写回
- 发游戏事件
- 需要当前 tick 立即影响游戏结果的判断

### 5.2 Bounded queue

后台队列必须有容量和背压策略：

| 业务类型 | 背压策略 |
| --- | --- |
| 可丢弃 telemetry / debug sample | drop newest 或 drop oldest |
| 可重建缓存刷新 | coalesce by key |
| 回放 / 文件导出 | bounded queue + 告警 + 可选 drop old |
| 交易 / 强一致事件 | 不可静默丢弃；需要持久队列或失败反馈 |

### 5.3 Worker 生命周期

Worker 至少要有：

- Start
- Stop / Cancel
- Flush / Drain
- fault logging
- bounded batch size
- shutdown timeout

回写主线程前：

- 校验 map generation。
- 校验 player token。
- 重新获取 entity handle。
- 确认 plugin / module 仍处于 active 状态。

## 6. 地图级异步初始化

### 6.1 标准流程

地图加载、区域加载、排行榜加载、静态实体扫描应使用：

1. `Interlocked.Increment` 生成 map generation。
2. cancel / dispose 上一轮 CTS。
3. 主线程先写入临时状态，避免旧地图残留。
4. 后台准备纯数据 DTO。
5. 回主线程一次性 commit。
6. commit 前后都校验 generation。
7. 通知下游模块 map context ready。

### 6.2 DTO 边界

后台 DTO 可以包含：

- map id / map name
- API 返回模型
- 解析后的普通数据
- 文件索引结果

后台 DTO 不应包含：

- live `IPlayer`
- live entity wrapper
- pawn / controller wrapper
- 未校验的 `CHandle<T>` 解引用结果

### 6.3 下游任务

下游加载任务也要继承 map generation。即使无法取消底层 API，也必须在回写前校验当前 map 是否仍匹配。

## 7. 缓存策略

### 7.1 生命周期分层

| 缓存类型 | 清理点 |
| --- | --- |
| tick cache | 当前 tick 结束 |
| player cache | disconnect / session reattach |
| run cache | run end / abort / player reset |
| map cache | map unload / map context shutdown |
| plugin cache | unload / dispose |

### 7.2 读多写少缓存

适合缓存：

- 当前 map 的 top record / summary。
- 当前 map 的 zone / static entity scan。
- 目录索引。
- 已解析配置。

不适合缓存：

- 每 tick 都变化且无复用价值的数据。
- 无清理点的 player/entity wrapper。
- 需要强一致的外部状态，除非有失效协议。

### 7.3 锁内规则

锁内只做内存操作：

- add / remove / update dictionary
- copy small snapshot
- compute small aggregate

锁外做：

- IO
- network
- DB
- file delete
- compression
- large sort

## 8. 日志、提示和 Profiler

### 8.1 高频输出节流

高频路径不要直接输出。可用：

- 每 N 秒最多一次。
- 状态变化时输出。
- 首次异常输出，重复异常计数。
- debug convar 开启后才输出详细日志。
- 避免在高频日志里拼接玩家名、SteamID、实体 id 等动态标识；需要定位时优先使用稳定分段名、计数器或已脱敏摘要。

### 8.2 Profiler 使用

- 每个 `StartRecording` 必须有对应 `StopRecording`。
- 名称应稳定，不要拼接玩家名、SteamID、实体 id。
- 分段要能定位问题，例如 `Hook.ResolvePlayer`、`Hook.DispatchPre`、`Worker.Flush`。
- 不要让 profiler 自身成为高频分配来源。

## 9. JIT / 编译 / Native interop 优化

### 9.1 AggressiveInlining

适用：

- 极短方法。
- 热路径反复调用。
- 纯包装、flag 判断、slot 查找、小数学判断。

不适用：

- 大方法。
- 有 IO / logging / exception-heavy 逻辑。
- 为了“看起来优化”而添加。

示例：

```csharp
[MethodImpl(MethodImplOptions.AggressiveInlining)]
public static bool HasFlagFast(uint flags, uint mask) => (flags & mask) != 0;
```

### 9.2 StructLayout / fixed binary layout

适用：

- native struct mirror。
- binary replay / sample frame。
- protobuf memory mirror。
- unmanaged interop buffer。

要求：

- 明确 `Pack` / `Size` / field order。
- 有版本策略。
- 有测试或断言验证大小。

### 9.3 UnmanagedCallersOnly / unmanaged function pointer

仅用于 native callback / vtable / trampoline 场景。

要求：

- delegate / function pointer 签名与 native 完全匹配。
- 所有 pointer 生命周期明确。
- 不捕获托管对象。
- 出错时宁可禁用该优化，不要容忍未定义行为。

### 9.4 项目级配置

服务器插件可评估：

- `AllowUnsafeBlocks`：仅当 native interop / pointer API 必需。
- `ServerGarbageCollection`：长期运行服务器负载。
- `ConcurrentGarbageCollection`：降低停顿风险。
- Release 构建优化：不要用 Debug 构建判断真实性能。

这些配置应作为场景化建议，不应无条件写入所有模板。

## 10. 优化输出格式

当 agent 被要求“优化性能”时，输出至少包含：

- 热点类型：Hook / player state / buffer / worker / map init / UI text / native interop。
- 证据：为什么这段代码是热点。
- 当前风险：分配、IO、锁、生命周期、过期写回、Hook 过细等。
- 修改方向：具体采用哪种模式。
- 不做什么：明确拒绝的过度优化或兼容分支。
- 验证方式：build、profiler、日志节流、生命周期回归、断线/换图/卸载测试。

## 11. 快速决策表

| 发现 | 优先处理 |
| --- | --- |
| Hook 内有 JSON / IO | 改成主线程采样 + 后台 worker |
| Hook 内每 tick `new[]` | `stackalloc` / 复用缓冲 |
| 多个字典保存玩家态 | 合并到 PlayerRuntime |
| 异步回调写 player 状态 | 加 session / generation token |
| 地图加载慢且切图后错乱 | map generation + cancel previous + main-thread commit |
| 周期 HUD 分配高 | StringBuilder 复用 + 状态变化刷新 |
| 目录扫描卡顿 | map-bound index + top-directory scan + 后台刷新 |
| 记录 / 回放帧过大 | struct frame + prealloc / ring buffer + binary encoding |
| 日志刷屏 | 节流 + debug convar |
| native callback 开销高 | 审核是否适合 unmanaged callback，但先验证签名安全 |
