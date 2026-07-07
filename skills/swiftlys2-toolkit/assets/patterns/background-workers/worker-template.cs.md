# SwiftlyS2 Background Worker 模板

对应官方文档关联：
- `Thread Safety`
- `Scheduler`（仅用于与 Worker 做职责分流，不表示 Worker 等于 Scheduler）

适用于：后台持久化、批处理、异步计算、producer / consumer 解耦。

后台队列、背压和热路径投递策略先看：`../../../references/swiftlys2-performance-optimization-playbook.md`。

## 适用原则

- Worker 只处理可异步的计算 / 序列化 / 持久化
- 主线程敏感 API 不直接在 Worker 线程访问
- Worker 必须有明确的 Start / Stop / Flush / Cancel 语义
- 回主线程写回前要重新校验 player / entity / generation
- 轻量周期任务优先考虑 SwiftlyS2 自带 Scheduler
- Worker 队列必须有容量策略；不能让生产速度无限大于消费速度
- 背压策略必须按业务重要性选择，不能把可丢弃 telemetry 的策略套到强一致事件上

## 示例骨架

```csharp
using System;
using System.Collections.Generic;
using System.Threading.Channels;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;

namespace MyNamespace;

public sealed class MyBackgroundWorker(ILogger<MyBackgroundWorker> logger)
{
    private const int QueueCapacity = 1024;
    private const int MaxBatchSize = 64;
    private static readonly TimeSpan ShutdownTimeout = TimeSpan.FromSeconds(5);

    private readonly ILogger<MyBackgroundWorker> _logger = logger;
    private Channel<MyWorkItem> _queue = CreateQueue();
    private CancellationTokenSource? _cts;
    private Task? _workerTask;

    private static Channel<MyWorkItem> CreateQueue()
    {
        return Channel.CreateBounded<MyWorkItem>(new BoundedChannelOptions(QueueCapacity)
        {
            SingleReader = true,
            SingleWriter = false,
            FullMode = BoundedChannelFullMode.Wait
        });
    }

    public void Start()
    {
        if (_workerTask is not null)
        {
            return;
        }

        _cts = new CancellationTokenSource();
        _workerTask = Task.Run(() => RunLoop(_cts.Token));
    }

    public bool TryEnqueue(MyWorkItem item)
    {
        if (_queue.Writer.TryWrite(item))
        {
            return true;
        }

        _logger.LogWarning("后台任务队列已满，拒绝本次任务");
        return false;
    }

    public async Task StopAsync(bool flushRemaining)
    {
        if (_cts is null || _workerTask is null)
        {
            return;
        }

        _queue.Writer.TryComplete();
        if (!flushRemaining)
        {
            _cts.Cancel();
        }

        try
        {
            await _workerTask.WaitAsync(ShutdownTimeout).ConfigureAwait(false);
        }
        catch (TimeoutException ex)
        {
            _logger.LogError(ex, "后台任务停止超时");
            _cts.Cancel();
        }
        catch (OperationCanceledException) when (!flushRemaining)
        {
            // 非 flush 停止时，取消 worker 是预期路径。
        }
        finally
        {
            _workerTask = null;
            _cts.Dispose();
            _cts = null;
            _queue = CreateQueue();
        }
    }

    private async Task RunLoop(CancellationToken cancellationToken)
    {
        var batch = new List<MyWorkItem>(MaxBatchSize);

        while (await _queue.Reader.WaitToReadAsync(cancellationToken).ConfigureAwait(false))
        {
            batch.Clear();
            while (batch.Count < MaxBatchSize && _queue.Reader.TryRead(out var item))
            {
                batch.Add(item);
            }

            try
            {
                ProcessBatch(batch, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "处理后台任务失败");
            }
        }
    }

    private void ProcessBatch(IReadOnlyList<MyWorkItem> items, CancellationToken cancellationToken)
    {
        // 这里只做异步安全工作，例如 JSON、批处理、磁盘 / 网络 IO。
    }
}

public sealed record MyWorkItem(ulong SteamId, string Payload);
```

## Checklist

- 是否具备 Start / Stop / Flush / Cancel 闭环？
- 是否避免后台线程访问主线程敏感 API？
- 是否避免无限 fire-and-forget？
- 是否在回写前重新校验当前会话 / generation？
- 若只是轻量主线程周期任务，是否其实更适合 Scheduler？
- 是否有 batch size、shutdown timeout 和 worker fault 日志？
- 队列满时是 drop newest、drop oldest、coalesce，还是拒绝并反馈？
