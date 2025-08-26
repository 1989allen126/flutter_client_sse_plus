# SSE Client Plus 示例

这个目录包含了 `flutter_client_sse_plus` 的使用示例。

## 文件说明

- `main.dart` - 完整的 SSE 客户端示例
- `pubspec.yaml` - 示例项目的依赖配置

## 运行示例

运行 SSE 客户端示例：

要运行完整的 SSE 客户端示例，需要先确保包依赖正确：

1. 确保 `pubspec.yaml` 中的依赖配置正确：

```yaml
dependencies:
  flutter_client_sse_plus:
    path: ../
```

2. 获取依赖：

```bash
cd example
flutter pub get
```

3. 运行示例：

```bash
flutter run
```

## 示例功能

### 简化示例功能

- ✅ 模拟连接/断开
- ✅ 模拟 SSE 事件
- ✅ 状态显示
- ✅ 消息日志
- ✅ 使用说明

### 完整示例功能

- ✅ 真实的 SSE 连接
- ✅ 多订阅管理
- ✅ 状态监控
- ✅ 错误处理
- ✅ 重连机制
- ✅ 网络监听

## 注意事项

1. **简化示例**: 不依赖实际的 SSE 包，适合快速了解 UI 和交互
2. **完整示例**: 需要正确的包依赖，适合学习实际使用
3. **网络连接**: 完整示例需要有效的 SSE 服务器端点
4. **权限**: 可能需要网络权限

## 故障排除

### 依赖问题

如果遇到依赖问题，请检查：

- `pubspec.yaml` 中的路径配置
- 父目录的包结构是否正确
- Flutter 版本兼容性

### 网络问题

如果遇到网络问题，请检查：

- 网络连接状态
- 防火墙设置
- SSE 服务器是否可用

### 编译问题

如果遇到编译问题，请检查：

- Dart SDK 版本
- Flutter 版本
- 依赖版本兼容性

## 下一步

1. 查看主包的 README 了解详细功能
2. 查看 MIGRATION_GUIDE 了解迁移方法
3. 查看 SUMMARY 了解技术细节
