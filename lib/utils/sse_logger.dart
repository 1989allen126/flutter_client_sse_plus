part of flutter_client_sse_plus;

/// SSE日志工具类
class SSELogger {
  static const String _tag = '[SSEClientPlus]';
  static bool _enableLogging = true;
  static LogLevel _logLevel = LogLevel.info;

  /// 设置是否启用日志
  static void setLoggingEnabled(bool enabled) {
    _enableLogging = enabled;
  }

  /// 设置日志级别
  static void setLogLevel(LogLevel level) {
    _logLevel = level;
  }

  /// 调试日志
  static void debug(String message, [StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, stackTrace);
  }

  /// 信息日志
  static void info(String message, [StackTrace? stackTrace]) {
    _log(LogLevel.info, message, stackTrace);
  }

  /// 警告日志
  static void warning(String message, [StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, stackTrace);
  }

  /// 错误日志
  static void error(String message, [StackTrace? stackTrace]) {
    _log(LogLevel.error, message, stackTrace);
  }

  /// 内部日志方法
  static void _log(LogLevel level, String message, [StackTrace? stackTrace]) {
    if (!_enableLogging || level.index < _logLevel.index) {
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase();
    final logMessage = '$_tag [$levelStr] $timestamp: $message';

    // 使用print输出日志
    print(logMessage);

    if (stackTrace != null && level == LogLevel.error) {
      print('$_tag Stack trace: $stackTrace');
    }
  }
}

/// 日志级别枚举
enum LogLevel {
  debug,
  info,
  warning,
  error,
}
