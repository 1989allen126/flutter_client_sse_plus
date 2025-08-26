part of flutter_client_sse_plus;

/// SSE订阅配置
class SSESubscriptionConfig {
  /// 订阅URL
  final String url;

  /// 请求方法
  final SSERequestType method;

  /// 请求头
  final Map<String, String> headers;

  /// 请求体
  final Map<String, dynamic>? body;

  /// 事件回调
  final void Function(SSEModel event) onEvent;

  /// 错误回调
  final void Function(dynamic error, StackTrace? stackTrace)? onError;

  /// 最后活动时间
  DateTime? _lastActivity;

  /// 构造函数
  SSESubscriptionConfig({
    required this.url,
    this.method = SSERequestType.GET,
    this.headers = const {},
    this.body,
    required this.onEvent,
    this.onError,
  });

  /// 获取最后活动时间
  DateTime? get lastActivity => _lastActivity;

  /// 更新最后活动时间
  void updateLastActivity() {
    _lastActivity = DateTime.now();
  }

  /// 从JSON创建实例（不包含回调函数）
  factory SSESubscriptionConfig.fromJson(Map<String, dynamic> json) {
    return SSESubscriptionConfig(
      url: json['url'] as String,
      method: SSERequestType.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => SSERequestType.GET,
      ),
      headers: Map<String, String>.from(json['headers'] ?? {}),
      body: json['body'] as Map<String, dynamic>?,
      onEvent: (_) {}, // 占位符，实际使用时需要重新设置
      onError: null,
    );
  }

  /// 转换为JSON（不包含回调函数）
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'method': method.name,
      'headers': headers,
      if (body != null) 'body': body,
    };
  }

  /// 复制并修改
  SSESubscriptionConfig copyWith({
    String? url,
    SSERequestType? method,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    void Function(SSEModel event)? onEvent,
    void Function(dynamic error, StackTrace? stackTrace)? onError,
  }) {
    return SSESubscriptionConfig(
      url: url ?? this.url,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      onEvent: onEvent ?? this.onEvent,
      onError: onError ?? this.onError,
    );
  }

  @override
  String toString() {
    return 'SSESubscriptionConfig(url: $url, method: $method)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SSESubscriptionConfig &&
        other.url == url &&
        other.method == method &&
        mapEquals(other.headers, headers) &&
        mapEquals(other.body, body);
  }

  @override
  int get hashCode {
    return url.hashCode ^
        method.hashCode ^
        headers.hashCode ^
        body.hashCode;
  }
}
