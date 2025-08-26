part of flutter_client_sse_plus;

/// SSE连接状态枚举
enum SSEConnectionStatus {
  /// 未初始化
  uninitialized('未初始化'),

  /// 已初始化
  initialized('已初始化'),

  /// 连接中
  connecting('连接中'),

  /// 已连接
  connected('已连接'),

  /// 断开连接
  disconnected('断开连接'),

  /// 重连中
  reconnecting('重连中'),

  /// 连接错误
  error('连接错误'),

  /// 连接失败
  failed('连接失败'),

  /// 已销毁
  disposed('已销毁');

  final String description;
  const SSEConnectionStatus(this.description);

  @override
  String toString() => description;

  /// 是否为活跃状态
  bool get isActive => this == SSEConnectionStatus.connected ||
                      this == SSEConnectionStatus.connecting ||
                      this == SSEConnectionStatus.reconnecting;

  /// 是否为错误状态
  bool get isError => this == SSEConnectionStatus.error ||
                     this == SSEConnectionStatus.failed;

  /// 是否为终止状态
  bool get isTerminated => this == SSEConnectionStatus.disposed ||
                          this == SSEConnectionStatus.failed;
}
