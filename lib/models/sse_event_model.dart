part of flutter_client_sse_plus;

/// SSE事件模型
class SSEModel {
  /// 事件ID
  final String? id;

  /// 事件类型
  final String? event;

  /// 事件数据
  final String? data;

  /// 重连间隔（毫秒）
  final int? retry;

  /// 构造函数
  const SSEModel({
    this.id,
    this.event,
    this.data,
    this.retry,
  });

  /// 从JSON创建实例
  factory SSEModel.fromJson(Map<String, dynamic> json) {
    return SSEModel(
      id: json['id'] as String?,
      event: json['event'] as String?,
      data: json['data'] as String?,
      retry: json['retry'] as int?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (event != null) 'event': event,
      if (data != null) 'data': data,
      if (retry != null) 'retry': retry,
    };
  }

  /// 复制并修改
  SSEModel copyWith({
    String? id,
    String? event,
    String? data,
    int? retry,
  }) {
    return SSEModel(
      id: id ?? this.id,
      event: event ?? this.event,
      data: data ?? this.data,
      retry: retry ?? this.retry,
    );
  }

  @override
  String toString() {
    return 'SSEModel(id: $id, event: $event, data: $data, retry: $retry)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SSEModel &&
        other.id == id &&
        other.event == event &&
        other.data == data &&
        other.retry == retry;
  }

  @override
  int get hashCode {
    return id.hashCode ^ event.hashCode ^ data.hashCode ^ retry.hashCode;
  }
}
