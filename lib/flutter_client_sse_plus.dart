library flutter_client_sse_plus;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

part 'constants/sse_request_type_enum.dart';
part 'models/sse_event_model.dart';
part 'models/sse_connection_config.dart';
part 'models/sse_subscription_config.dart';
part 'models/sse_connection_status.dart';
part 'utils/sse_logger.dart';
part 'utils/sse_retry_strategy.dart';

/// 增强版SSE客户端管理器
/// 提供完善的连接管理、错误处理、重连机制和状态监控
class SSEClientPlus {
  static final SSEClientPlus _instance = SSEClientPlus._internal();
  factory SSEClientPlus() => _instance;
  static SSEClientPlus get instance => _instance;
  SSEClientPlus._internal();

  // 连接配置
  SSEConnectionConfig? _config;

  // 状态管理
  SSEConnectionStatus _status = SSEConnectionStatus.uninitialized;
  bool _isInitialized = false;
  bool _isDisposed = false;

  // 网络检测
  final Connectivity _connectivity = Connectivity();
  ConnectivityResult _lastConnectivityResult = ConnectivityResult.none;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // 连接管理
  http.Client? _httpClient;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  Timer? _networkDebounceTimer;

  // 重连策略
  final SSERetryStrategy _retryStrategy = SSERetryStrategy();

  // 订阅管理
  final Map<String, SSESubscriptionConfig> _subscriptions = {};
  final Map<String, StreamSubscription<SSEModel>> _activeSubscriptions = {};

  // 事件流
  StreamController<SSEConnectionStatus>? _statusController;
  StreamController<SSEModel>? _eventController;

  // 重载支持标志
  bool _streamControllersClosed = false;

  // 获取器
  Stream<SSEConnectionStatus>? get statusStream => _statusController?.stream;
  Stream<SSEModel>? get eventStream => _eventController?.stream;
  SSEConnectionStatus get status => _status;
  bool get isConnected => _status == SSEConnectionStatus.connected;
  bool get isInitialized => _isInitialized;
  Map<String, SSESubscriptionConfig> get subscriptions =>
      Map.unmodifiable(_subscriptions);

  /// 初始化SSE客户端
  ///
  /// [config] 连接配置
  /// [onStatusChanged] 状态变化回调（可选）
  Future<void> initialize({
    required SSEConnectionConfig config,
    void Function(SSEConnectionStatus status, {String? message})?
        onStatusChanged,
  }) async {
    // 设置是否允许日志输出
    SSELogger.setLoggingEnabled(config.enableConsoleLogger);

    // 如果已经初始化，先释放资源
    if (_isInitialized) {
      SSELogger.info('SSEClientPlus already initialized, disposing first...');
      return;
    }

    if (_streamControllersClosed ||
        _statusController == null ||
        _eventController == null) {
      _statusController = StreamController<SSEConnectionStatus>.broadcast();
      _eventController = StreamController<SSEModel>.broadcast();
    }

    // 重置流控制器标志
    _resetStreamControllersFlag();

    // 设置状态为未初始化
    _updateStatus(SSEConnectionStatus.uninitialized);

    _config = config;
    _isInitialized = true;
    _isDisposed = false;

    // 设置状态变化监听
    if (onStatusChanged != null && _statusController != null) {
      _statusController?.stream.listen((status) {
        if (_isDisposed) return;
        onStatusChanged(status);
      });
    }

    // 启动网络监听
    await _startNetworkMonitoring();

    // 更新状态
    _updateStatus(SSEConnectionStatus.initialized);

    SSELogger.info('SSEClientPlus initialized successfully');
  }

  /// 订阅SSE事件
  ///
  /// [subscriptionId] 订阅ID，用于标识和管理订阅
  /// [url] SSE端点URL
  /// [config] 订阅配置
  /// [onEvent] 事件回调
  /// [onError] 错误回调（可选）
  Future<void> subscribe({
    required String subscriptionId,
    required String url,
    SSESubscriptionConfig? config,
    required void Function(SSEModel event) onEvent,
    void Function(dynamic error, StackTrace? stackTrace)? onError,
  }) async {
    _assertInitialized();
    _assertNotDisposed();

    if (_subscriptions.containsKey(subscriptionId)) {
      SSELogger.warning('Subscription $subscriptionId already exists');
      return;
    }

    final subscriptionConfig = config ??
        SSESubscriptionConfig(
          url: url,
          onEvent: onEvent,
        );
    _subscriptions[subscriptionId] = subscriptionConfig;

    await _createSubscription(
      subscriptionId: subscriptionId,
      url: url,
      config: subscriptionConfig,
      onEvent: onEvent,
      onError: onError,
    );

    SSELogger.info('Subscription $subscriptionId created successfully');
  }

  /// 取消订阅
  ///
  /// [subscriptionId] 订阅ID
  Future<void> unsubscribe(String subscriptionId) async {
    _assertInitialized();

    final subscription = _activeSubscriptions.remove(subscriptionId);
    _subscriptions.remove(subscriptionId);

    if (subscription != null) {
      await subscription.cancel();
      SSELogger.info('Subscription $subscriptionId unsubscribed');
    }

    // 如果没有活跃订阅，停止心跳
    if (_activeSubscriptions.isEmpty) {
      _stopHeartbeat();
    }
  }

  /// 取消所有订阅
  Future<void> unsubscribeAll() async {
    _assertInitialized();

    final subscriptionIds = _activeSubscriptions.keys.toList();
    for (final id in subscriptionIds) {
      await unsubscribe(id);
    }

    SSELogger.info('All subscriptions unsubscribed');
  }

  /// 重新连接所有订阅
  Future<void> reconnectAll() async {
    _assertInitialized();
    _assertNotDisposed();

    if (_subscriptions.isEmpty) {
      SSELogger.warning('No subscriptions to reconnect');
      return;
    }

    _updateStatus(SSEConnectionStatus.reconnecting);

    // 取消当前所有连接
    await _cancelAllSubscriptions();

    // 重新创建所有订阅
    for (final entry in _subscriptions.entries) {
      final subscriptionId = entry.key;
      final config = entry.value;

      await _createSubscription(
        subscriptionId: subscriptionId,
        url: config.url,
        config: config,
        onEvent: config.onEvent,
        onError: config.onError,
      );
    }

    SSELogger.info('All subscriptions reconnected');
  }

  /// 断开连接并清理资源
  Future<void> teardown() async {
    if (_isDisposed) return;

    _isDisposed = true;
    _isInitialized = false;

    // 取消所有订阅（如果已初始化）
    if (_subscriptions.isNotEmpty) {
      await _cancelAllSubscriptions();
    }

    // 取消所有定时器
    _cancelAllTimers();

    // 取消网络监听
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;

    // 关闭HTTP客户端
    _httpClient?.close();
    _httpClient = null;

    // 重置重试策略
    _retryStrategy.resetRetryCount();

    // 重置网络状态
    _lastConnectivityResult = ConnectivityResult.none;

    // 标记流控制器为已关闭状态
    _streamControllersClosed = true;
    if (_statusController != null && !_statusController!.isClosed) {
      _statusController?.close();
      _statusController = null;
    }

    if (_eventController != null && !_eventController!.isClosed) {
      _eventController?.close();
      _eventController = null;
    }

    _status = SSEConnectionStatus.disposed;
    SSELogger.info('SSEClientPlus disposed');
  }

  // ==================== 私有方法 ====================

  /// 创建订阅
  Future<void> _createSubscription({
    required String subscriptionId,
    required String url,
    required SSESubscriptionConfig config,
    required void Function(SSEModel event) onEvent,
    void Function(dynamic error, StackTrace? stackTrace)? onError,
  }) async {
    try {
      final stream = _createSSEStream(url, config);

      final subscription = stream.listen(
        (event) {
          _handleEvent(subscriptionId, event, onEvent);
        },
        onError: (error, stackTrace) {
          _handleError(subscriptionId, error, stackTrace, onError);
        },
        onDone: () {
          _handleSubscriptionDone(subscriptionId);
        },
      );

      _activeSubscriptions[subscriptionId] = subscription;
      _updateStatus(SSEConnectionStatus.connected);

      // 启动心跳检测
      _startHeartbeat();
    } catch (error, stackTrace) {
      _handleError(subscriptionId, error, stackTrace, onError);
    }
  }

  /// 创建SSE流
  Stream<SSEModel> _createSSEStream(String url, SSESubscriptionConfig config) {
    return _makeSSEConnection(url, config);
  }

  /// 建立SSE连接
  Stream<SSEModel> _makeSSEConnection(
      String url, SSESubscriptionConfig config) async* {
    final client = _httpClient ??= http.Client();
    var currentEvent = SSEModel();

    try {
      final request = http.Request(
        config.method.name,
        Uri.parse(url),
      );

      // 设置请求头
      request.headers.addAll(config.headers);
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      // 设置请求体
      if (config.body != null) {
        request.body = jsonEncode(config.body);
      }

      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw HttpException(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (_isDisposed) break;

        final parsedEvent = _parseSSELine(line);
        if (parsedEvent != null) {
          // 合并事件数据
          currentEvent = _mergeSSEEvent(currentEvent, parsedEvent);
        } else if (line.isEmpty) {
          // 空行表示事件结束
          if (currentEvent.data != null ||
              currentEvent.event != null ||
              currentEvent.id != null) {
            yield currentEvent;
            currentEvent = SSEModel();
          }
        }
      }
    } catch (error) {
      SSELogger.error('SSE connection failed: $error');
      rethrow;
    }
  }

  /// 合并SSE事件
  SSEModel _mergeSSEEvent(SSEModel current, SSEModel newEvent) {
    return SSEModel(
      id: newEvent.id ?? current.id,
      event: newEvent.event ?? current.event,
      data: newEvent.data != null
          ? (current.data != null
              ? '${current.data}\n${newEvent.data}'
              : newEvent.data)
          : current.data,
      retry: newEvent.retry ?? current.retry,
    );
  }

  /// 解析SSE行
  SSEModel? _parseSSELine(String line) {
    if (line.isEmpty) return null;

    final colonIndex = line.indexOf(':');
    if (colonIndex == -1) return null;

    final field = line.substring(0, colonIndex).trim();
    final value = line.substring(colonIndex + 1).trim();

    switch (field) {
      case 'event':
        return SSEModel(event: value);
      case 'data':
        return SSEModel(data: value);
      case 'id':
        return SSEModel(id: value);
      case 'retry':
        // 处理重连间隔
        final retryMs = int.tryParse(value);
        if (retryMs != null) {
          _retryStrategy.setRetryInterval(Duration(milliseconds: retryMs));
        }
        return null;
      default:
        return null;
    }
  }

  /// 处理事件
  void _handleEvent(
      String subscriptionId, SSEModel event, void Function(SSEModel) onEvent) {
    try {
      // 检查是否已释放
      if (_isDisposed) {
        SSELogger.warning('SSEClientPlus is disposed, ignoring event');
        return;
      }

      // 发送到全局事件流（安全添加）
      if (_eventController != null && !_eventController!.isClosed && !_streamControllersClosed) {
        if (_isDisposed) return;
        _eventController?.add(event);
      }

      // 调用订阅回调
      onEvent(event);

      // 重置重连计数
      _retryStrategy.resetRetryCount();

      // 更新最后活动时间
      _subscriptions[subscriptionId]?.updateLastActivity();
    } catch (error, stackTrace) {
      SSELogger.error('Error handling event: $error', stackTrace);
    }
  }

  /// 处理错误
  void _handleError(
    String subscriptionId,
    dynamic error,
    StackTrace? stackTrace,
    void Function(dynamic error, StackTrace? stackTrace)? onError,
  ) {
    // 检查是否已释放
    if (_isDisposed) {
      SSELogger.warning('SSEClientPlus is disposed, ignoring error');
      return;
    }

    SSELogger.error('Subscription $subscriptionId error: $error', stackTrace);

    // 调用错误回调
    onError?.call(error, stackTrace);

    // 更新状态
    _updateStatus(SSEConnectionStatus.error, message: error.toString());

    // 尝试重连
    _scheduleReconnect(subscriptionId);
  }

  /// 处理订阅完成
  void _handleSubscriptionDone(String subscriptionId) {
    // 检查是否已释放
    if (_isDisposed) {
      SSELogger.warning(
          'SSEClientPlus is disposed, ignoring subscription done');
      return;
    }

    SSELogger.info('Subscription $subscriptionId completed');

    _activeSubscriptions.remove(subscriptionId);

    if (_activeSubscriptions.isEmpty) {
      _updateStatus(SSEConnectionStatus.disconnected);
    }
  }

  /// 安排重连
  void _scheduleReconnect(String subscriptionId) {
    if (_isDisposed) {
      SSELogger.warning('SSEClientPlus is disposed, ignoring reconnect');
      return;
    }

    final delay = _retryStrategy.getNextRetryDelay();
    if (delay == null) {
      SSELogger.warning(
          'Max retry attempts reached for subscription $subscriptionId');
      _updateStatus(SSEConnectionStatus.failed);
      return;
    }

    SSELogger.info(
        'Scheduling reconnect for subscription $subscriptionId in ${delay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_isDisposed) return;
      _reconnectSubscription(subscriptionId);
    });
  }

  /// 重连订阅
  Future<void> _reconnectSubscription(String subscriptionId) async {
    if (_isDisposed) return;

    final config = _subscriptions[subscriptionId];
    if (config == null) return;

    SSELogger.info('Reconnecting subscription $subscriptionId');

    try {
      await _createSubscription(
        subscriptionId: subscriptionId,
        url: config.url,
        config: config,
        onEvent: config.onEvent,
        onError: config.onError,
      );
    } catch (error, stackTrace) {
      SSELogger.error(
          'Reconnect failed for subscription $subscriptionId: $error',
          stackTrace);
    }
  }

  /// 启动网络监听
  Future<void> _startNetworkMonitoring() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _lastConnectivityResult = _getPrimaryConnectivityResult(results);

      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (results) {
          if (_isDisposed) return;
          final result = _getPrimaryConnectivityResult(results);
          _handleConnectivityChange(result);
        },
      );
    } catch (error) {
      SSELogger.error('Failed to start network monitoring: $error');
    }
  }

  /// 获取主要的网络连接类型
  ConnectivityResult _getPrimaryConnectivityResult(
      List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return ConnectivityResult.none;
    }

    // 优先级：wifi > mobile > ethernet > bluetooth > vpn > none
    final priorityOrder = [
      ConnectivityResult.wifi,
      ConnectivityResult.mobile,
      ConnectivityResult.ethernet,
      ConnectivityResult.bluetooth,
      ConnectivityResult.vpn,
      ConnectivityResult.none,
    ];

    for (final priority in priorityOrder) {
      if (results.contains(priority)) {
        return priority;
      }
    }

    // 如果没有匹配的优先级，返回第一个结果
    return results.first;
  }

  /// 处理网络状态变化
  void _handleConnectivityChange(ConnectivityResult result) {
    if (_isDisposed) return;

    if (result != _lastConnectivityResult) {
      final oldStatus = _getNetworkStatusDescription(_lastConnectivityResult);
      final newStatus = _getNetworkStatusDescription(result);

      SSELogger.info('Network status changed: $oldStatus -> $newStatus');
      _lastConnectivityResult = result;

      _networkDebounceTimer?.cancel();
      _networkDebounceTimer =
          Timer(const Duration(milliseconds: 500), () async {
        if (_isNetworkAvailable(result)) {
          bool shouldReconnect = true;

          // 根据配置决定是否进行网络连通性检查
          if (_config?.enableNetworkReachabilityCheck == true) {
            SSELogger.info('Checking network reachability...');
            final isReachable = await _checkNetworkReachability();

            if (!isReachable) {
              // 有网络连接但无法访问互联网
              SSELogger.warning('Network connected but not reachable');
              _updateStatus(SSEConnectionStatus.disconnected,
                  message: '网络连接异常，无法访问互联网');
              shouldReconnect = false;
            }
          }

          if (shouldReconnect) {
            if (_lastConnectivityResult == ConnectivityResult.none) {
              // 从无网络恢复到有网络
              SSELogger.info(
                  'Network restored and reachable, attempting to reconnect');
              _updateStatus(SSEConnectionStatus.reconnecting,
                  message: '网络恢复，尝试重连');
              reconnectAll();
            } else {
              // 网络类型切换，但仍有网络
              SSELogger.info(
                  'Network type changed and reachable, reconnecting');
              _updateStatus(SSEConnectionStatus.reconnecting,
                  message: '网络切换，重新连接');
              reconnectAll();
            }
          }
        } else {
          // 网络不可用
          SSELogger.warning('Network unavailable');
          _updateStatus(SSEConnectionStatus.disconnected, message: '网络断开');
        }
      });
    }
  }

  /// 判断网络是否可用
  bool _isNetworkAvailable(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }

  /// 检查网络可达性（可选，用于更严格的网络检查）
  Future<bool> _checkNetworkReachability() async {
    // 可配置的测试服务器列表
    final testUrls = [
      'https://www.google.com',
      'https://www.baidu.com',
      'https://www.qq.com',
      'https://www.taobao.com',
    ];

    for (final url in testUrls) {
      try {
        SSELogger.debug('Testing network reachability with: $url');
        final client = http.Client();
        final response = await client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 5));
        client.close();

        if (response.statusCode == 200) {
          SSELogger.info('Network reachability test passed with: $url');
          return true;
        }
      } catch (e) {
        SSELogger.debug('Network reachability test failed with $url: $e');
        continue; // 尝试下一个服务器
      }
    }

    SSELogger.warning('All network reachability tests failed');
    return false;
  }

  /// 获取网络状态描述
  String _getNetworkStatusDescription(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi连接';
      case ConnectivityResult.mobile:
        return '移动网络';
      case ConnectivityResult.ethernet:
        return '以太网';
      case ConnectivityResult.bluetooth:
        return '蓝牙网络';
      case ConnectivityResult.vpn:
        return 'VPN连接';
      case ConnectivityResult.none:
        return '无网络连接';
      default:
        return '未知网络状态';
    }
  }

  /// 启动心跳检测
  void _startHeartbeat() {
    if (_heartbeatTimer != null) return;

    final interval = _config?.heartbeatInterval ?? const Duration(seconds: 30);

    _heartbeatTimer = Timer.periodic(interval, (timer) {
      _checkHeartbeat();
    });
  }

  /// 检查心跳
  void _checkHeartbeat() {
    if (_isDisposed || _subscriptions.isEmpty) {
      _stopHeartbeat();
      return;
    }

    final now = DateTime.now();
    final timeout = _config?.heartbeatTimeout ?? const Duration(minutes: 2);

    for (final entry in _subscriptions.entries) {
      final subscriptionId = entry.key;
      final config = entry.value;

      if (config.lastActivity != null) {
        final timeSinceLastActivity = now.difference(config.lastActivity!);
        if (timeSinceLastActivity > timeout) {
          SSELogger.warning(
              'Heartbeat timeout for subscription $subscriptionId');
          _scheduleReconnect(subscriptionId);
        }
      }
    }
  }

  /// 停止心跳检测
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 取消所有订阅
  Future<void> _cancelAllSubscriptions() async {
    final subscriptions = _activeSubscriptions.values.toList();
    _activeSubscriptions.clear();

    for (final subscription in subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
  }

  /// 取消所有定时器
  void _cancelAllTimers() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _networkDebounceTimer?.cancel();

    _heartbeatTimer = null;
    _reconnectTimer = null;
    _networkDebounceTimer = null;
  }

  /// 重新创建流控制器
  void _resetStreamControllersFlag() {
    // 重置流控制器状态标志
    _streamControllersClosed = false;

    SSELogger.info('Stream controllers reset for reload');
  }

  /// 更新连接状态
  void _updateStatus(SSEConnectionStatus status, {String? message}) {
    if (_status != status) {
      _status = status;

      // 只有在流控制器未关闭且未标记为已关闭时才添加事件
      if (_statusController != null && !_statusController!.isClosed && !_streamControllersClosed) {
        _statusController?.add(status);
      }

      SSELogger.info(
          'Connection status changed: $status${message != null ? ' - $message' : ''}');
    }
  }

  /// 断言已初始化
  void _assertInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'SSEClientPlus not initialized. Call initialize() first.');
    }
  }

  /// 断言未销毁
  void _assertNotDisposed() {
    if (_isDisposed) {
      throw StateError('SSEClientPlus has been disposed.');
    }
  }

  /// 检查是否可以重载
  bool get canReload =>
      _isDisposed && _statusController != null && _eventController != null && !_statusController!.isClosed && !_eventController!.isClosed;

  /// 重载SSE客户端
  ///
  /// [config] 新的连接配置
  /// [onStatusChanged] 状态变化回调（可选）
  Future<void> reload({
    required SSEConnectionConfig config,
    void Function(SSEConnectionStatus status, {String? message})?
        onStatusChanged,
  }) async {
    if (!canReload) {
      throw StateError(
          'SSEClientPlus cannot be reloaded. Stream controllers may be closed.');
    }

    SSELogger.info('Reloading SSEClientPlus...');
    await initialize(config: config, onStatusChanged: onStatusChanged);
    SSELogger.info('SSEClientPlus reloaded successfully');
  }
}
