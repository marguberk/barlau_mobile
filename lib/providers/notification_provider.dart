import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/notification.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Получить количество непрочитанных уведомлений
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  
  // Получить только непрочитанные уведомления
  List<NotificationModel> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();

  // Получить срочные уведомления
  List<NotificationModel> get urgentNotifications =>
      _notifications.where((n) => n.isUrgent).toList();

  // Получить уведомления по типу
  List<NotificationModel> getNotificationsByType(String type) =>
      _notifications.where((n) => n.type == type).toList();

  // Получить уведомления по приоритету
  List<NotificationModel> getNotificationsByPriority(String priority) =>
      _notifications.where((n) => n.priority == priority).toList();

  Future<void> loadNotifications() async {
    if (_isLoading) {
      print('NotificationProvider: Загрузка уже в процессе, пропускаем');
      return;
    }
    
    print('NotificationProvider: Начинаем загрузку уведомлений...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Загружаем уведомления с сервера
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/notifications/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? data;
        
        _notifications = results.map((json) => NotificationModel.fromJson(json)).toList();
        
        // Сортируем по дате создания (новые первыми) и приоритету
        _notifications.sort((a, b) {
          // Сначала сортируем по приоритету (срочные вверху)
          if (a.isUrgent && !b.isUrgent) return -1;
          if (!a.isUrgent && b.isUrgent) return 1;
          if (a.isHighPriority && !b.isHighPriority) return -1;
          if (!a.isHighPriority && b.isHighPriority) return 1;
          
          // Затем по времени создания
          return b.createdAt.compareTo(a.createdAt);
        });
        
        print('NotificationProvider: Загружено ${_notifications.length} уведомлений');
        print('NotificationProvider: Непрочитанных: $unreadCount');
        print('NotificationProvider: Срочных: ${urgentNotifications.length}');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('NotificationProvider: Ошибка загрузки - $e');
      // В случае ошибки загружаем демо данные
      _loadDemoNotifications();
      _error = 'Ошибка загрузки с сервера. Показаны демо данные.';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Демо данные для тестирования
  void _loadDemoNotifications() {
    _notifications = [
      NotificationModel(
        id: 'demo-1',
        title: 'Новая задача',
        message: 'Вам назначена задача "Проверка техосмотра"',
        type: 'TASK',
        priority: 'HIGH',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      NotificationModel(
        id: 'demo-2',
        title: 'Крупный расход',
        message: 'Добавлен расход: Ремонт на сумму 150000 тг',
        type: 'EXPENSE',
        priority: 'HIGH',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: 'demo-3',
        title: 'Истек срок документа!',
        message: 'СРОЧНО! У VOLVO FH16 (A123BC01) истек срок: Техпаспорт',
        type: 'DOCUMENT',
        priority: 'URGENT',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 'demo-4',
        title: 'Новая поездка',
        message: 'Создана поездка "Алматы - Астана"',
        type: 'TRIP',
        priority: 'NORMAL',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      NotificationModel(
        id: 'demo-5',
        title: 'Добавлен новый транспорт',
        message: 'В систему добавлен транспорт: MAN TGX (B456CD02)',
        type: 'VEHICLE',
        priority: 'LOW',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index == -1) return;

      final notification = _notifications[index];
      
      if (!notificationId.startsWith('demo-')) {
        // Реальное уведомление - отправляем запрос на сервер
        final response = await http.patch(
          Uri.parse('https://barlau.org/api/notifications/$notificationId/'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({'read': true}),
        );
        
        if (response.statusCode == 200) {
          // Успешно отмечено на сервере, обновляем локально
          _notifications[index] = notification.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
          notifyListeners();
        }
      } else {
        // Демо данные - просто обновляем локально
        _notifications[index] = notification.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      print('NotificationProvider: Ошибка при отметке уведомления - $e');
      // В случае ошибки все равно обновляем локально
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead() async {
    try {
      // Отправляем запрос на сервер для отметки всех как прочитанные
      final response = await http.post(
        Uri.parse('https://barlau.org/api/notifications/mark_all_read/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 204) {
        // Успешно отмечено на сервере, обновляем локально
        final now = DateTime.now();
        _notifications = _notifications.map((n) => n.copyWith(
          isRead: true,
          readAt: now,
        )).toList();
        notifyListeners();
      }
    } catch (e) {
      print('NotificationProvider: Ошибка при отметке всех уведомлений - $e');
      // В случае ошибки все равно обновляем локально
      final now = DateTime.now();
      _notifications = _notifications.map((n) => n.copyWith(
        isRead: true,
        readAt: now,
      )).toList();
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index == -1) return;

      if (!notificationId.startsWith('demo-')) {
        // Реальное уведомление - отправляем запрос на сервер
        final response = await http.delete(
          Uri.parse('https://barlau.org/api/notifications/$notificationId/'),
          headers: {
            'Content-Type': 'application/json',
          },
        );
        
        if (response.statusCode == 204) {
          // Успешно удалено на сервере, удаляем локально
          _notifications.removeAt(index);
          notifyListeners();
        }
      } else {
        // Демо данные - просто удаляем локально
        _notifications.removeAt(index);
        notifyListeners();
      }
    } catch (e) {
      print('NotificationProvider: Ошибка при удалении уведомления - $e');
      // В случае ошибки все равно удаляем локально
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications.removeAt(index);
        notifyListeners();
      }
    }
  }

  // Добавить новое уведомление (для Push уведомлений)
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    
    // Сортируем снова с учетом приоритета
    _notifications.sort((a, b) {
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;
      if (a.isHighPriority && !b.isHighPriority) return -1;
      if (!a.isHighPriority && b.isHighPriority) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    
    notifyListeners();
  }

  // Очистить все уведомления
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  // Очистить ошибку
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 






