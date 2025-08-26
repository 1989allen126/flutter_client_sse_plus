# Flutter Client SSE Plus

增强版 SSE 客户端库，提供完善的连接管理、错误处理、重连机制和状态监控。

## 功能特性

### 🚀 核心功能

- **完善的连接管理**: 支持多订阅管理，自动连接池
- **智能重连机制**: 指数退避算法，支持抖动，可配置重连策略
- **网络状态监听**: 自动检测网络变化，网络恢复时自动重连
- **心跳检测**: 可配置的心跳间隔和超时时间
- **状态监控**: 实时连接状态监控和事件流

### 🛡️ 错误处理

- **异常捕获**: 完善的异常处理机制
- **错误分类**: 区分网络错误、服务器错误等不同类型
- **错误回调**: 支持自定义错误处理逻辑
- **日志系统**: 分级日志记录，便于调试

### ⚡ 性能优化

- **连接复用**: HTTP 客户端连接复用
- **内存管理**: 自动清理资源，防止内存泄漏
- **流控制**: 支持背压处理
- **异步处理**: 全异步操作，不阻塞 UI 线程

## 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  flutter_client_sse_plus: ^1.0.0
```

## 快速开始

### 1. 初始化 SSE 客户端

```dart
import 'package:flutter_client_sse_plus/flutter_client_sse_plus.dart';

// 配置SSE客户端
final config = SSEConnectionConfig(
  baseUrl: 'https://your-api-server.com',
  defaultHeaders: {
    'Authorization': 'Bearer your-token',
    'Content-Type': 'application/json',
  },
  heartbeatInterval: const Duration(seconds: 30),
  heartbeatTimeout: const Duration(minutes: 2),
  maxRetryAttempts: 5,
  enableAutoReconnect: true,
  enableNetworkMonitoring: true,
);

// 初始化
await SSEClientPlus.instance.initialize(
  config: config,
  onStatusChanged: (status, {message}) {
    print('连接状态: ${status.description}');
  },
);
```

### 2. 订阅 SSE 事件

```dart
// 订阅特定主题
await SSEClientPlus.instance.subscribe(
  subscriptionId: 'user-notifications',
  url: 'https://your-api-server.com/api/sse/notifications',
  config: SSESubscriptionConfig(
    url: 'https://your-api-server.com/api/sse/notifications',
    method: SSERequestType.GET,
    headers: {
      'X-User-ID': '12345',
    },
    onEvent: (event) {
      print('收到事件: ${event.event} - ${event.data}');
    },
    onError: (error, stackTrace) {
      print('订阅错误: $error');
    },
  ),
);
```

### 3. 监听全局事件

```dart
// 监听所有SSE事件
SSEClientPlus.instance.eventStream.listen((event) {
  print('全局事件: ${event.event} - ${event.data}');
});

// 监听连接状态变化
SSEClientPlus.instance.statusStream.listen((status) {
  print('状态变化: ${status.description}');
});
```

### 4. 管理订阅

```dart
// 取消特定订阅
await SSEClientPlus.instance.unsubscribe('user-notifications');

// 取消所有订阅
await SSEClientPlus.instance.unsubscribeAll();

// 重新连接所有订阅
await SSEClientPlus.instance.reconnectAll();

// 断开连接并清理资源
await SSEClientPlus.instance.dispose();
```

## 配置选项

### SSEConnectionConfig

| 参数                    | 类型                | 默认值 | 说明             |
| ----------------------- | ------------------- | ------ | ---------------- |
| baseUrl                 | String              | 必需   | 基础 URL         |
| defaultHeaders          | Map<String, String> | {}     | 默认请求头       |
| heartbeatInterval       | Duration            | 30 秒  | 心跳检测间隔     |
| heartbeatTimeout        | Duration            | 2 分钟 | 心跳超时时间     |
| connectionTimeout       | Duration            | 10 秒  | 连接超时时间     |
| maxRetryAttempts        | int                 | 5      | 最大重连次数     |
| retryInterval           | Duration            | 5 秒   | 重连间隔         |
| enableAutoReconnect     | bool                | true   | 是否启用自动重连 |
| enableNetworkMonitoring | bool                | true   | 是否启用网络监听 |

### SSESubscriptionConfig

| 参数    | 类型                  | 默认值 | 说明     |
| ------- | --------------------- | ------ | -------- |
| url     | String                | 必需   | 订阅 URL |
| method  | SSERequestType        | GET    | 请求方法 |
| headers | Map<String, String>   | {}     | 请求头   |
| body    | Map<String, dynamic>? | null   | 请求体   |
| onEvent | Function              | 必需   | 事件回调 |
| onError | Function?             | null   | 错误回调 |

## 连接状态

### SSEConnectionStatus

- `uninitialized`: 未初始化
- `initialized`: 已初始化
- `connecting`: 连接中
- `connected`: 已连接
- `disconnected`: 断开连接
- `reconnecting`: 重连中
- `error`: 连接错误
- `failed`: 连接失败
- `disposed`: 已销毁

## 重连策略

### SSERetryStrategy

支持以下重连策略：

- **指数退避**: 重连间隔按指数增长
- **抖动**: 添加随机延迟，避免同时重连
- **最大重试次数**: 限制重连次数
- **服务器重试指令**: 支持服务器发送的 retry 指令

```dart
final retryStrategy = SSERetryStrategy(
  maxRetryAttempts: 5,
  baseRetryInterval: const Duration(seconds: 5),
  maxRetryInterval: const Duration(minutes: 5),
  enableExponentialBackoff: true,
  enableJitter: true,
);
```

## 日志系统

### LogLevel

- `debug`: 调试信息
- `info`: 一般信息
- `warning`: 警告信息
- `error`: 错误信息

```dart
// 设置日志级别
SSELogger.setLogLevel(LogLevel.info);

// 启用/禁用日志
SSELogger.setLoggingEnabled(true);
```

## 最佳实践

### 1. 生命周期管理

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    _initializeSSE();
  }

  @override
  void dispose() {
    SSEClientPlus.instance.dispose();
    super.dispose();
  }
}
```

### 2. 错误处理

```dart
await SSEClientPlus.instance.subscribe(
  subscriptionId: 'my-topic',
  url: 'https://api.example.com/sse',
  config: SSESubscriptionConfig(
    url: 'https://api.example.com/sse',
    onEvent: (event) {
      // 处理事件
    },
    onError: (error, stackTrace) {
      // 处理错误
      if (error is HttpException) {
        // 网络错误
      } else if (error is FormatException) {
        // 数据格式错误
      } else {
        // 其他错误
      }
    },
  ),
);
```

### 3. 状态管理

```dart
SSEClientPlus.instance.statusStream.listen((status) {
  switch (status) {
    case SSEConnectionStatus.connected:
      // 连接成功
      break;
    case SSEConnectionStatus.reconnecting:
      // 重连中
      break;
    case SSEConnectionStatus.error:
      // 连接错误
      break;
    case SSEConnectionStatus.failed:
      // 连接失败
      break;
    default:
      break;
  }
});
```

## 与原始 SSEClient 的对比

| 功能     | 原始 SSEClient | SSE Client Plus |
| -------- | -------------- | --------------- |
| 连接管理 | ❌ 基础        | ✅ 完善         |
| 重连机制 | ❌ 简单        | ✅ 智能         |
| 网络监听 | ❌ 无          | ✅ 自动         |
| 心跳检测 | ❌ 无          | ✅ 可配置       |
| 状态监控 | ❌ 无          | ✅ 实时         |
| 错误处理 | ❌ 基础        | ✅ 完善         |
| 多订阅   | ❌ 不支持      | ✅ 支持         |
| 日志系统 | ❌ 无          | ✅ 分级         |
| 资源管理 | ❌ 手动        | ✅ 自动         |

## 许可证

MIT License
