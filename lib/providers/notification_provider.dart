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
        Uri.parse('https://barlau.org/api/notifications/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? data;
        
        _notifications = results.map((json) => _parseNotificationFromApi(json)).toList();
        print('NotificationProvider: Загружено ${_notifications.length} уведомлений, непрочитанных: $unreadCount');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('NotificationProvider: Ошибка загрузки - $e');
      // В случае ошибки показываем пустой список и ошибку
      _notifications = [];
      _error = 'Ошибка загрузки с сервера. Показаны тестовые данные.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index == -1) return;

      final notification = _notifications[index];
      final originalId = notification.data?['originalId'];
      
      if (originalId != null) {
        // Отправляем запрос на сервер
              final response = await http.post(
        Uri.parse('https://barlau.org/api/notifications/$originalId/mark_read/'),
          headers: {
            'Content-Type': 'application/json',
          },
        );
        
        if (response.statusCode == 204) {
          // Успешно отмечено на сервере, обновляем локально
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          notifyListeners();
        }
      } else {
        // Для тестовых данных просто обновляем локально
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      print('NotificationProvider: Ошибка при отметке уведомления - $e');
      // В случае ошибки все равно обновляем локально
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
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
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('NotificationProvider: Ошибка при отметке всех уведомлений - $e');
      // В случае ошибки все равно обновляем локально
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      // Здесь будет вызов API для удаления уведомления
      
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      _error = 'Ошибка при удалении уведомления';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Парсинг уведомления из API ответа
  NotificationModel _parseNotificationFromApi(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].hashCode, // Используем hashCode от UUID для int id
      title: json['title'] ?? 'Уведомление',
      message: json['message'] ?? '',
      type: _mapApiTypeToLocal(json['type']),
      isRead: json['read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      data: {
        'originalId': json['id'],
        'link': json['link'],
      },
    );
  }

  // Маппинг типов уведомлений из API в локальные типы
  String _mapApiTypeToLocal(String? apiType) {
    switch (apiType?.toUpperCase()) {
      case 'TASK':
        return 'task';
      case 'WAYBILL':
        return 'info';
      case 'EXPENSE':
        return 'warning';
      case 'SYSTEM':
        return 'system';
      case 'DOCUMENT':
        return 'info';
      default:
        return 'info';
    }
  }

  // Генерация тестовых уведомлений
  List<NotificationModel> _generateMockNotifications() {
    final now = DateTime.now();
    
    return [
      NotificationModel(
        id: 1,
        title: 'Новая задача назначена',
        message: 'Вам назначена новая задача: "Доставка груза в Алматы"',
        type: 'task',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 15)),
        data: {'taskId': 123, 'priority': 'high'},
      ),
      NotificationModel(
        id: 2,
        title: 'Обновление системы',
        message: 'Система будет обновлена сегодня в 22:00. Возможны кратковременные перебои.',
        type: 'system',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 3,
        title: 'Задача выполнена',
        message: 'Задача "Транспортировка оборудования" успешно завершена',
        type: 'success',
        isRead: true,
        createdAt: now.subtract(const Duration(hours: 4)),
        data: {'taskId': 122},
      ),
      NotificationModel(
        id: 4,
        title: 'Требует внимания',
        message: 'Грузовик №45 требует технического обслуживания',
        type: 'warning',
        isRead: false,
        createdAt: now.subtract(const Duration(days: 1)),
        data: {'vehicleId': 45},
      ),
      NotificationModel(
        id: 5,
        title: 'Новое сообщение',
        message: 'У вас новое сообщение от диспетчера',
        type: 'info',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      NotificationModel(
        id: 6,
        title: 'Ошибка в системе',
        message: 'Обнаружена ошибка в модуле отчетности. Обратитесь к администратору.',
        type: 'error',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      NotificationModel(
        id: 7,
        title: 'Профиль обновлен',
        message: 'Ваш профиль был успешно обновлен',
        type: 'success',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }
} 






