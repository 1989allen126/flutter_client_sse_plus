import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_client_sse_plus/flutter_client_sse_plus.dart';

void main() {
  group('SSEClientPlus Tests', () {
    late SSEClientPlus client;

    setUp(() {
      client = SSEClientPlus.instance;
    });

    tearDown(() async {
      if (client.isInitialized) {
        await client.teardown();
      }
    });

    test('should initialize with valid config', () async {
      final config = SSEConnectionConfig(
        baseUrl: 'https://example.com',
        defaultHeaders: {'Authorization': 'Bearer token'},
      );

      await client.initialize(config: config);
      expect(client.isInitialized, true);
      expect(client.status, SSEConnectionStatus.initialized);
    });

    test('should not initialize twice', () async {
      final config = SSEConnectionConfig(baseUrl: 'https://example.com');

      await client.initialize(config: config);
      await client.initialize(config: config); // 第二次初始化应该被忽略

      expect(client.isInitialized, true);
    });

    test('should create subscription config correctly', () {
      final config = SSESubscriptionConfig(
        url: 'https://example.com/sse',
        method: SSERequestType.GET,
        headers: {'Content-Type': 'application/json'},
        body: {'key': 'value'},
        onEvent: (event) {},
        onError: (error, stackTrace) {},
      );

      expect(config.url, 'https://example.com/sse');
      expect(config.method, SSERequestType.GET);
      expect(config.headers['Content-Type'], 'application/json');
      expect(config.body?['key'], 'value');
    });

            test('should handle connection status changes', () async {
      final config = SSEConnectionConfig(baseUrl: 'https://example.com');

      await client.initialize(config: config);

      // 检查客户端状态
      expect(client.isInitialized, true);
      expect(client.status, SSEConnectionStatus.initialized);
    });

    test('should create SSE event model correctly', () {
      final event = SSEModel(
        id: '123',
        event: 'test',
        data: 'test data',
        retry: 5000,
      );

      expect(event.id, '123');
      expect(event.event, 'test');
      expect(event.data, 'test data');
      expect(event.retry, 5000);
    });

    test('should create SSE event model from JSON', () {
      final json = {
        'id': '123',
        'event': 'test',
        'data': 'test data',
        'retry': 5000,
      };

      final event = SSEModel.fromJson(json);

      expect(event.id, '123');
      expect(event.event, 'test');
      expect(event.data, 'test data');
      expect(event.retry, 5000);
    });

    test('should convert SSE event model to JSON', () {
      final event = SSEModel(
        id: '123',
        event: 'test',
        data: 'test data',
        retry: 5000,
      );

      final json = event.toJson();

      expect(json['id'], '123');
      expect(json['event'], 'test');
      expect(json['data'], 'test data');
      expect(json['retry'], 5000);
    });

    test('should handle retry strategy correctly', () {
      final strategy = SSERetryStrategy(
        maxRetryAttempts: 3,
        baseRetryInterval: const Duration(seconds: 1),
      );

      expect(strategy.canRetry, true);
      expect(strategy.remainingRetries, 3);

      final delay1 = strategy.getNextRetryDelay();
      expect(delay1, isNotNull);
      expect(strategy.currentRetryCount, 1);
      expect(strategy.remainingRetries, 2);

      final delay2 = strategy.getNextRetryDelay();
      expect(delay2, isNotNull);
      expect(strategy.currentRetryCount, 2);
      expect(strategy.remainingRetries, 1);

      final delay3 = strategy.getNextRetryDelay();
      expect(delay3, isNotNull);
      expect(strategy.currentRetryCount, 3);
      expect(strategy.remainingRetries, 0);

      final delay4 = strategy.getNextRetryDelay();
      expect(delay4, isNull); // 已达到最大重试次数

      strategy.resetRetryCount();
      expect(strategy.currentRetryCount, 0);
      expect(strategy.canRetry, true);
    });

    test('should handle connection config correctly', () {
      final config = SSEConnectionConfig(
        baseUrl: 'https://example.com',
        defaultHeaders: {'Authorization': 'Bearer token'},
        heartbeatInterval: const Duration(seconds: 30),
        heartbeatTimeout: const Duration(minutes: 2),
        connectionTimeout: const Duration(seconds: 10),
        maxRetryAttempts: 5,
        retryInterval: const Duration(seconds: 5),
        enableAutoReconnect: true,
        enableNetworkMonitoring: true,
      );

      expect(config.baseUrl, 'https://example.com');
      expect(config.defaultHeaders['Authorization'], 'Bearer token');
      expect(config.heartbeatInterval, const Duration(seconds: 30));
      expect(config.maxRetryAttempts, 5);
      expect(config.enableAutoReconnect, true);
    });

    test('should create connection config from JSON', () {
      final json = {
        'baseUrl': 'https://example.com',
        'defaultHeaders': {'Authorization': 'Bearer token'},
        'heartbeatIntervalSeconds': 30,
        'heartbeatTimeoutMinutes': 2,
        'connectionTimeoutSeconds': 10,
        'maxRetryAttempts': 5,
        'retryIntervalSeconds': 5,
        'enableAutoReconnect': true,
        'enableNetworkMonitoring': true,
      };

      final config = SSEConnectionConfig.fromJson(json);

      expect(config.baseUrl, 'https://example.com');
      expect(config.defaultHeaders['Authorization'], 'Bearer token');
      expect(config.heartbeatInterval, const Duration(seconds: 30));
      expect(config.maxRetryAttempts, 5);
    });

    test('should convert connection config to JSON', () {
      final config = SSEConnectionConfig(
        baseUrl: 'https://example.com',
        defaultHeaders: {'Authorization': 'Bearer token'},
        heartbeatInterval: const Duration(seconds: 30),
        maxRetryAttempts: 5,
      );

      final json = config.toJson();

      expect(json['baseUrl'], 'https://example.com');
      expect(json['defaultHeaders']['Authorization'], 'Bearer token');
      expect(json['heartbeatIntervalSeconds'], 30);
      expect(json['maxRetryAttempts'], 5);
    });

    test('should handle connection status enum correctly', () {
      expect(SSEConnectionStatus.connected.description, '已连接');
      expect(SSEConnectionStatus.disconnected.description, '断开连接');
      expect(SSEConnectionStatus.error.description, '连接错误');

      expect(SSEConnectionStatus.connected.isActive, true);
      expect(SSEConnectionStatus.disconnected.isActive, false);
      expect(SSEConnectionStatus.error.isError, true);
      expect(SSEConnectionStatus.failed.isError, true);
      expect(SSEConnectionStatus.disposed.isTerminated, true);
    });

    test('should handle request type enum correctly', () {
      expect(SSERequestType.GET.name, 'GET');
      expect(SSERequestType.POST.name, 'POST');
      expect(SSERequestType.GET.toString(), 'GET');
      expect(SSERequestType.POST.toString(), 'POST');
    });

    test('should handle log levels correctly', () {
      SSELogger.setLogLevel(LogLevel.info);
      SSELogger.setLoggingEnabled(true);

      // 这些调用不应该抛出异常
      SSELogger.debug('Debug message');
      SSELogger.info('Info message');
      SSELogger.warning('Warning message');
      SSELogger.error('Error message');
    });
  });
}
