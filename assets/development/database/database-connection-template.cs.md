# SwiftlyS2 数据库连接模板

对应官方文档：`Database`。

SwiftlyS2 从全局 `configs/database.jsonc` 读取连接。`Core.Database.GetConnection(name)` 返回 `IDbConnection`；指定名称不存在时会回退到默认连接，因此业务代码必须明确记录自己期望的连接名，而不是把回退当成隔离保证。

## 配置职责

- 全局连接配置属于服务器运维层，不要把密码写入插件源码或插件 JSONC。
- 官方示例覆盖 MySQL、PostgreSQL 和 SQLite URI。具体字段与部署模板以当前官方文档为准。
- `DatabaseConnectionInfo.Pass` 和原始连接串包含敏感信息，日志、异常包装和诊断输出都不得打印它们。

## ADO.NET 最小模式

```csharp
using System.Data;
using SwiftlyS2.Shared;

public sealed class PlayerRepository(ISwiftlyCore core)
{
    private readonly ISwiftlyCore _core = core;

    public async Task<PlayerRow?> FindAsync(ulong steamId, CancellationToken cancellationToken)
    {
        using IDbConnection connection = _core.Database.GetConnection("primary");

        // 使用当前项目选择的参数化 ADO.NET 或 ORM API；不要拼接 steamId 到 SQL 字符串。
        return await QueryPlayerAsync(connection, steamId, cancellationToken);
    }
}
```

## 连接诊断

```csharp
var info = Core.Database.GetConnectionInfo("primary");
if (info is null)
{
    throw new InvalidOperationException("Database connection 'primary' is not configured.");
}

logger.LogInformation(
    "Database configured. Driver={Driver}, Host={Host}, Port={Port}, Database={Database}",
    info.Driver,
    info.Host,
    info.Port,
    info.Database);
```

`GetConnectionString` 与 `GetConnectionInfo` 都可用于诊断，但不得将 password 或完整 raw URI 写入日志。

## 线程与生命周期

- 数据库查询、ORM materialization 和批量写入可在后台异步流程中完成。
- 结果回写到 `IPlayer`、entity、菜单或游戏状态前，重新获取并校验当前对象；不要把 live wrapper 带入数据库任务。
- 插件卸载时应取消自建后台工作、停止入队并按业务约束 flush 或放弃未提交工作。SwiftlyS2 没有为业务数据库 worker 提供自动托管保证。

## Checklist

- [ ] 是否使用服务器全局配置，而非源码内连接串？
- [ ] 命名连接缺失时，默认回退是否会错误连接到别的库？
- [ ] SQL 是否参数化？
- [ ] `IDbConnection` 是否被 `using` 管理（仅在具体 provider 支持 `IAsyncDisposable` 时使用 `await using`）？
- [ ] 是否避免记录 password、raw URI 或含机密的异常正文？
- [ ] 结果回写前是否重新校验 player / entity / map generation？
