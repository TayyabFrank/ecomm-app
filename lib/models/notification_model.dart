class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'order', 'security', 'product', 'system'
  final DateTime timestamp;
  final bool isRead;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  AppNotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AppNotificationModel.fromMap(Map<String, dynamic> map) {
    return AppNotificationModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? 'system',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }
}
