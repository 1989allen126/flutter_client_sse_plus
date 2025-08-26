part of flutter_client_sse_plus;

/// SSE重连策略
class SSERetryStrategy {
  /// 最大重试次数
  int _maxRetryAttempts = 5;

  /// 基础重试间隔
  Duration _baseRetryInterval = const Duration(seconds: 5);

  /// 最大重试间隔
  Duration _maxRetryInterval = const Duration(minutes: 5);

  /// 当前重试次数
  int _currentRetryCount = 0;

  /// 是否启用指数退避
  bool _enableExponentialBackoff = true;

  /// 是否启用抖动
  bool _enableJitter = true;

  /// 构造函数
  SSERetryStrategy({
    int maxRetryAttempts = 5,
    Duration baseRetryInterval = const Duration(seconds: 5),
    Duration maxRetryInterval = const Duration(minutes: 5),
    bool enableExponentialBackoff = true,
    bool enableJitter = true,
  }) {
    _maxRetryAttempts = maxRetryAttempts;
    _baseRetryInterval = baseRetryInterval;
    _maxRetryInterval = maxRetryInterval;
    _enableExponentialBackoff = enableExponentialBackoff;
    _enableJitter = enableJitter;
  }

  /// 获取最大重试次数
  int get maxRetryAttempts => _maxRetryAttempts;

  /// 获取当前重试次数
  int get currentRetryCount => _currentRetryCount;

  /// 获取基础重试间隔
  Duration get baseRetryInterval => _baseRetryInterval;

  /// 获取最大重试间隔
  Duration get maxRetryInterval => _maxRetryInterval;

  /// 设置最大重试次数
  void setMaxRetryAttempts(int attempts) {
    _maxRetryAttempts = attempts;
  }

  /// 设置基础重试间隔
  void setBaseRetryInterval(Duration interval) {
    _baseRetryInterval = interval;
  }

  /// 设置最大重试间隔
  void setMaxRetryInterval(Duration interval) {
    _maxRetryInterval = interval;
  }

  /// 设置重试间隔（从服务器接收到的retry指令）
  void setRetryInterval(Duration interval) {
    _baseRetryInterval = interval;
  }

  /// 获取下一次重试延迟
  Duration? getNextRetryDelay() {
    if (_currentRetryCount >= _maxRetryAttempts) {
      return null; // 已达到最大重试次数
    }

    Duration delay = _baseRetryInterval;

    // 应用指数退避
    if (_enableExponentialBackoff) {
      final exponentialDelay = Duration(
        milliseconds: _baseRetryInterval.inMilliseconds * (1 << _currentRetryCount),
      );
      delay = exponentialDelay;
    }

    // 限制最大延迟
    if (delay > _maxRetryInterval) {
      delay = _maxRetryInterval;
    }

    // 应用抖动（随机化延迟）
    if (_enableJitter) {
      final jitterFactor = 0.1; // 10%的抖动
      final jitterRange = (delay.inMilliseconds * jitterFactor).round();
      final jitter = (Random().nextDouble() * 2 - 1) * jitterRange;
      delay = Duration(milliseconds: delay.inMilliseconds + jitter.round());
    }

    _currentRetryCount++;
    return delay;
  }

  /// 重置重试计数
  void resetRetryCount() {
    _currentRetryCount = 0;
  }

  /// 增加重试计数
  void incrementRetryCount() {
    _currentRetryCount++;
  }

  /// 检查是否还可以重试
  bool get canRetry => _currentRetryCount < _maxRetryAttempts;

  /// 获取剩余重试次数
  int get remainingRetries => _maxRetryAttempts - _currentRetryCount;

  /// 从JSON创建实例
  factory SSERetryStrategy.fromJson(Map<String, dynamic> json) {
    return SSERetryStrategy(
      maxRetryAttempts: json['maxRetryAttempts'] ?? 5,
      baseRetryInterval: Duration(seconds: json['baseRetryIntervalSeconds'] ?? 5),
      maxRetryInterval: Duration(minutes: json['maxRetryIntervalMinutes'] ?? 5),
      enableExponentialBackoff: json['enableExponentialBackoff'] ?? true,
      enableJitter: json['enableJitter'] ?? true,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'maxRetryAttempts': _maxRetryAttempts,
      'baseRetryIntervalSeconds': _baseRetryInterval.inSeconds,
      'maxRetryIntervalMinutes': _maxRetryInterval.inMinutes,
      'enableExponentialBackoff': _enableExponentialBackoff,
      'enableJitter': _enableJitter,
      'currentRetryCount': _currentRetryCount,
    };
  }

  @override
  String toString() {
    return 'SSERetryStrategy(maxRetryAttempts: $_maxRetryAttempts, currentRetryCount: $_currentRetryCount, baseRetryInterval: $_baseRetryInterval)';
  }
}
