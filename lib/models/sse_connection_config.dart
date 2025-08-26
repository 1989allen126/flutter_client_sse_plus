part of flutter_client_sse_plus;

/// SSE连接配置
class SSEConnectionConfig {
  /// 基础URL
  final String baseUrl;

  /// 默认请求头
  final Map<String, String> defaultHeaders;

  /// 心跳检测间隔
  final Duration heartbeatInterval;

  /// 心跳超时时间
  final Duration heartbeatTimeout;

  /// 连接超时时间
  final Duration connectionTimeout;

  /// 最大重连次数
  final int maxRetryAttempts;

  /// 重连间隔
  final Duration retryInterval;

  /// 是否启用自动重连
  final bool enableAutoReconnect;

  /// 是否启用网络状态监听
  final bool enableNetworkMonitoring;

  /// 是否启用控制台日志
  final bool enableConsoleLogger;

  /// 是否启用网络可达性检查
  final bool enableNetworkReachabilityCheck;

  /// 构造函数
  const SSEConnectionConfig({
    required this.baseUrl,
    this.defaultHeaders = const {},
    this.heartbeatInterval = const Duration(seconds: 30),
    this.heartbeatTimeout = const Duration(minutes: 2),
    this.connectionTimeout = const Duration(seconds: 10),
    this.maxRetryAttempts = 5,
    this.retryInterval = const Duration(seconds: 5),
    this.enableAutoReconnect = true,
    this.enableNetworkMonitoring = true,
    this.enableConsoleLogger = true,
    this.enableNetworkReachabilityCheck = true,
  });

  /// 从JSON创建实例
  factory SSEConnectionConfig.fromJson(Map<String, dynamic> json) {
    return SSEConnectionConfig(
      baseUrl: json['baseUrl'] as String,
      defaultHeaders: Map<String, String>.from(json['defaultHeaders'] ?? {}),
      heartbeatInterval:
          Duration(seconds: json['heartbeatIntervalSeconds'] ?? 30),
      heartbeatTimeout: Duration(minutes: json['heartbeatTimeoutMinutes'] ?? 2),
      connectionTimeout:
          Duration(seconds: json['connectionTimeoutSeconds'] ?? 10),
      maxRetryAttempts: json['maxRetryAttempts'] ?? 5,
      retryInterval: Duration(seconds: json['retryIntervalSeconds'] ?? 5),
      enableAutoReconnect: json['enableAutoReconnect'] ?? true,
      enableNetworkMonitoring: json['enableNetworkMonitoring'] ?? true,
      enableConsoleLogger: json['enableConsoleLogger'] ?? false,
      enableNetworkReachabilityCheck: json['enableNetworkReachabilityCheck'] ?? true,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'defaultHeaders': defaultHeaders,
      'heartbeatIntervalSeconds': heartbeatInterval.inSeconds,
      'heartbeatTimeoutMinutes': heartbeatTimeout.inMinutes,
      'connectionTimeoutSeconds': connectionTimeout.inSeconds,
      'maxRetryAttempts': maxRetryAttempts,
      'retryIntervalSeconds': retryInterval.inSeconds,
      'enableAutoReconnect': enableAutoReconnect,
      'enableNetworkMonitoring': enableNetworkMonitoring,
      'enableConsoleLogger': enableConsoleLogger,
      'enableNetworkReachabilityCheck': enableNetworkReachabilityCheck,
    };
  }

  /// 复制并修改
  SSEConnectionConfig copyWith({
    String? baseUrl,
    Map<String, String>? defaultHeaders,
    Duration? heartbeatInterval,
    Duration? heartbeatTimeout,
    Duration? connectionTimeout,
    int? maxRetryAttempts,
    Duration? retryInterval,
    bool? enableAutoReconnect,
    bool? enableNetworkMonitoring,
    bool? enableConsoleLogger,
    bool? enableNetworkReachabilityCheck,
  }) {
    return SSEConnectionConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      heartbeatInterval: heartbeatInterval ?? this.heartbeatInterval,
      heartbeatTimeout: heartbeatTimeout ?? this.heartbeatTimeout,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      maxRetryAttempts: maxRetryAttempts ?? this.maxRetryAttempts,
      retryInterval: retryInterval ?? this.retryInterval,
      enableAutoReconnect: enableAutoReconnect ?? this.enableAutoReconnect,
      enableNetworkMonitoring:
          enableNetworkMonitoring ?? this.enableNetworkMonitoring,
      enableConsoleLogger: enableConsoleLogger ?? this.enableConsoleLogger,
      enableNetworkReachabilityCheck: enableNetworkReachabilityCheck ?? this.enableNetworkReachabilityCheck,
    );
  }

  @override
  String toString() {
    return 'SSEConnectionConfig(baseUrl: $baseUrl, heartbeatInterval: $heartbeatInterval, maxRetryAttempts: $maxRetryAttempts)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SSEConnectionConfig &&
        other.baseUrl == baseUrl &&
        mapEquals(other.defaultHeaders, defaultHeaders) &&
        other.heartbeatInterval == heartbeatInterval &&
        other.heartbeatTimeout == heartbeatTimeout &&
        other.connectionTimeout == connectionTimeout &&
        other.maxRetryAttempts == maxRetryAttempts &&
        other.retryInterval == retryInterval &&
        other.enableAutoReconnect == enableAutoReconnect &&
        other.enableNetworkMonitoring == enableNetworkMonitoring &&
        other.enableConsoleLogger == enableConsoleLogger;
  }

  @override
  int get hashCode {
    return baseUrl.hashCode ^
        defaultHeaders.hashCode ^
        heartbeatInterval.hashCode ^
        heartbeatTimeout.hashCode ^
        connectionTimeout.hashCode ^
        maxRetryAttempts.hashCode ^
        retryInterval.hashCode ^
        enableAutoReconnect.hashCode ^
        enableNetworkMonitoring.hashCode ^
        enableConsoleLogger.hashCode;
  }
}
