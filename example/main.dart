import 'package:flutter/material.dart';
import 'package:flutter_client_sse_plus/flutter_client_sse_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SSE Client Plus Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SSEPlusDemo(),
    );
  }
}

class SSEPlusDemo extends StatefulWidget {
  const SSEPlusDemo({super.key});

  @override
  State<SSEPlusDemo> createState() => _SSEPlusDemoState();
}

class _SSEPlusDemoState extends State<SSEPlusDemo> {
  final List<String> _messages = [];
  SSEConnectionStatus _status = SSEConnectionStatus.uninitialized;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeSSE();
  }

  Future<void> _initializeSSE() async {
    try {
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
        enableConsoleLogger: true, // 启用控制台日志
      );

      // 初始化SSE客户端
      await SSEClientPlus.instance.initialize(
        config: config,
        onStatusChanged: (status, {message}) {
          setState(() {
            _status = status;
            _isConnected = status == SSEConnectionStatus.connected;
          });
          _addMessage('状态变化: ${status.description}${message != null ? ' - $message' : ''}');
        },
      );

      // 监听全局事件
      SSEClientPlus.instance.eventStream?.listen((event) {
        _addMessage('全局事件: ${event.event} - ${event.data}');
      });

      // 订阅特定主题
      await _subscribeToTopic('user-notifications');
      await _subscribeToTopic('system-updates');

    } catch (error) {
      _addMessage('初始化失败: $error');
    }
  }

  Future<void> _subscribeToTopic(String topicId) async {
    try {
      await SSEClientPlus.instance.subscribe(
        subscriptionId: topicId,
        url: 'https://your-api-server.com/api/sse/$topicId',
        config: SSESubscriptionConfig(
          url: 'https://your-api-server.com/api/sse/$topicId',
          method: SSERequestType.GET,
          headers: {
            'X-Topic': topicId,
          },
          onEvent: (event) {
            _addMessage('[$topicId] ${event.event}: ${event.data}');
          },
          onError: (error, stackTrace) {
            _addMessage('[$topicId] 错误: $error');
          },
        ),
        onEvent: (event) {
          _addMessage('[$topicId] ${event.event}: ${event.data}');
        },
        onError: (error, stackTrace) {
          _addMessage('[$topicId] 错误: $error');
        },
      );
      _addMessage('订阅成功: $topicId');
    } catch (error) {
      _addMessage('订阅失败 [$topicId]: $error');
    }
  }

  void _addMessage(String message) {
    setState(() {
      _messages.add('${DateTime.now().toString().substring(11, 19)}: $message');
      if (_messages.length > 100) {
        _messages.removeAt(0);
      }
    });
  }

  Future<void> _reconnect() async {
    try {
      await SSEClientPlus.instance.reconnectAll();
      _addMessage('手动重连完成');
    } catch (error) {
      _addMessage('重连失败: $error');
    }
  }

  Future<void> _disconnect() async {
    try {
      _addMessage('连接已断开');
    } catch (error) {
      _addMessage('断开失败: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SSE Client Plus Demo'),
        backgroundColor: _isConnected ? Colors.green : Colors.red,
      ),
      body: Column(
        children: [
          // 状态显示
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.wifi : Icons.wifi_off,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text('状态: ${_status.description}'),
                const Spacer(),
                Text('订阅数: ${SSEClientPlus.instance.subscriptions.length}'),
              ],
            ),
          ),

          // 控制按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _isConnected ? null : _reconnect,
                  child: const Text('重连'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isConnected ? _disconnect : null,
                  child: const Text('断开'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _messages.clear();
                    });
                  },
                  child: const Text('清空日志'),
                ),
              ],
            ),
          ),

          // 消息列表
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    message,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    SSEClientPlus.instance.teardown();
    super.dispose();
  }
}
