part of flutter_client_sse_plus;

/// SSE请求类型枚举
enum SSERequestType {
  GET('GET'),
  POST('POST');

  final String name;
  const SSERequestType(this.name);

  @override
  String toString() => name;
}
