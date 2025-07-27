class NotificationModel {
  final String id; // UUID вместо int
  final String title;
  final String message;
  final String type; // TASK, EXPENSE, TRIP, VEHICLE, DOCUMENT, SYSTEM, URGENT, INFO
  final String priority; // LOW, NORMAL, HIGH, URGENT
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? link; // Ссылка для перехода
  final int? relatedObjectId;
  final String? relatedObjectType;
  final Map<String, dynamic>? data; // Дополнительные данные

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = 'NORMAL',
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.link,
    this.relatedObjectId,
    this.relatedObjectType,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '0',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'INFO',
      priority: json['priority'] ?? 'NORMAL',
      isRead: json['read'] ?? false, // Поле называется 'read' в Django API
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at']) : null,
      link: json['link'],
      relatedObjectId: json['related_object_id'],
      relatedObjectType: json['related_object_type'],
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'link': link,
      'related_object_id': relatedObjectId,
      'related_object_type': relatedObjectType,
      'data': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? priority,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    String? link,
    int? relatedObjectId,
    String? relatedObjectType,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      link: link ?? this.link,
      relatedObjectId: relatedObjectId ?? this.relatedObjectId,
      relatedObjectType: relatedObjectType ?? this.relatedObjectType,
      data: data ?? this.data,
    );
  }

  // Получить человеко-читаемое время создания
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин. назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${createdAt.day}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}';
    }
  }

  // Проверка на срочность
  bool get isUrgent => priority == 'URGENT' || type == 'URGENT';
  
  // Проверка на высокий приоритет
  bool get isHighPriority => priority == 'HIGH' || isUrgent;

  // Получить отображаемый тип
  String get typeDisplay {
    switch (type) {
      case 'TASK':
        return 'Задача';
      case 'EXPENSE':
        return 'Расход';
      case 'TRIP':
        return 'Поездка';
      case 'VEHICLE':
        return 'Транспорт';
      case 'DOCUMENT':
        return 'Документ';
      case 'SYSTEM':
        return 'Система';
      case 'URGENT':
        return 'Срочно';
      case 'INFO':
        return 'Информация';
      case 'WAYBILL':
        return 'Путевой лист';
      default:
        return type;
    }
  }

  // Получить отображаемый приоритет
  String get priorityDisplay {
    switch (priority) {
      case 'LOW':
        return 'Низкий';
      case 'NORMAL':
        return 'Обычный';
      case 'HIGH':
        return 'Высокий';
      case 'URGENT':
        return 'Срочный';
      default:
        return priority;
    }
  }
} 
 
 
 
 
 