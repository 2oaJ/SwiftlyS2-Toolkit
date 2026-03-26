# SwiftlyS2 Background Worker 模板

对应官方文档关联：
- `Thread Safety`
- `Scheduler`（仅用于与 Worker 做职责分流，不表示 Worker 等于 Scheduler）

适用于：后台持久化、批处理、异步计算、producer / consumer 解耦。

## 适用原则

- Worker 只处理可异步的计算 / 序列化 / 持久化
- 主线程敏感 API 不直接在 Worker 线程访问
- Worker 必须有明确的 Start / Stop / Flush / Cancel 语义
- 回主线程写回前要重新校验 player / entity / generation
- 轻量周期任务优先考虑 SwiftlyS2 自带 Scheduler

## 示例骨架

```csharp
using System.Collections.Concurrent;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;

namespace MyNamespace;

public sealed class MyBackgroundWorker(ILogger<MyBackgroundWorker> logger)
{
    private readonly ILogger<MyBackgroundWorker> _logger = logger;
    private readonly ConcurrentQueue<MyWorkItem> _queue = new();
    private readonly AutoResetEvent _signal = new(false);
    private CancellationTokenSource? _cts;
    private Task? _workerTask;

    public void Start()
    {
        if (_workerTask is not null)
        {
            return;
        }

        _cts = new CancellationTokenSource();
        _workerTask = Task.Run(() => RunLoop(_cts.Token));
    }

    public void Enqueue(MyWorkItem item)
    {
        _queue.Enqueue(item);
        _signal.Set();
    }

    public async Task StopAsync(bool flushRemaining)
    {
        if (_cts is null || _workerTask is null)
        {
            return;
        }

        _cts.Cancel();
        _signal.Set();

        try
        {
            await _workerTask.ConfigureAwait(false);
        }
        finally
        {
            _workerTask = null;
            _cts.Dispose();
            _cts = null;
        }

        if (flushRemaining)
        {
            FlushRemainingQueue();
        }
    }

    private void RunLoop(CancellationToken cancellationToken)
    {
        while (!cancellationToken.IsCancellationRequested)
        {
            if (!_queue.TryDequeue(out var item))
            {
                _signal.WaitOne(4);
                continue;
            }

            try
            {
                Process(item, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "处理后台任务失败");
            }
        }
    }

    private void Process(MyWorkItem item, CancellationToken cancellationToken)
    {
        // 这里只做异步安全工作，例如 JSON、批处理、磁盘 / 网络 IO。
    }

    private void FlushRemainingQueue()
    {
        while (_queue.TryDequeue(out var item))
        {
            try
            {
                Process(item, CancellationToken.None);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Flush 剩余任务失败");
            }
        }
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
