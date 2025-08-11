import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/notification.dart';
import '../services/safe_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      // Получаем валидный токен
      String? token = await SafeApiService.getValidToken();
      
      if (token == null) {
        print('NotificationProvider: Токен не найден, используем демо данные');
        _loadDemoNotifications();
        _error = 'Токен авторизации не найден. Показаны демо данные.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Загружаем уведомления с сервера с авторизацией
      final response = await http.get(
        Uri.parse('https://barlau.org/api/notifications/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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
  void _loadDemoNotifications() async {
    // Получаем информацию о текущем пользователе
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('user_role') ?? '';
    final userName = prefs.getString('user_name') ?? '';
    
    print('NotificationProvider: Загружаем демо уведомления для роли: $userRole');
    
    List<NotificationModel> demoNotifications = [];
    
    // Общие уведомления для всех
    demoNotifications.add(
      NotificationModel(
        id: 'demo-1',
        title: 'Добро пожаловать!',
        message: 'Добро пожаловать в систему BARLAU.KZ',
        type: 'SYSTEM',
        priority: 'NORMAL',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    );
    
    // Персональные уведомления в зависимости от роли
    switch (userRole) {
      case 'DRIVER':
        demoNotifications.addAll([
          NotificationModel(
            id: 'demo-2',
            title: 'Новая поездка',
            message: 'Вам назначена поездка "Алматы - Астана" на завтра',
            type: 'TRIP',
            priority: 'HIGH',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
          NotificationModel(
            id: 'demo-3',
            title: 'Техосмотр',
            message: 'Напоминание: техосмотр грузовика через 3 дня',
            type: 'MAINTENANCE',
            priority: 'HIGH',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ]);
        break;
        
      case 'ACCOUNTANT':
        demoNotifications.addAll([
          NotificationModel(
            id: 'demo-2',
            title: 'Новый расход',
            message: 'Добавлен расход: Ремонт грузовика на сумму 150000 тг',
            type: 'EXPENSE',
            priority: 'HIGH',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
          ),
          NotificationModel(
            id: 'demo-3',
            title: 'Отчет готов',
            message: 'Финансовый отчет за месяц готов к проверке',
            type: 'REPORT',
            priority: 'NORMAL',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ]);
        break;
        
      case 'DIRECTOR':
        demoNotifications.addAll([
          NotificationModel(
            id: 'demo-2',
            title: 'Важная задача',
            message: 'Требуется ваше решение по крупному контракту',
            type: 'TASK',
            priority: 'URGENT',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
          NotificationModel(
            id: 'demo-3',
            title: 'Финансовый отчет',
            message: 'Ежемесячный финансовый отчет готов к рассмотрению',
            type: 'REPORT',
            priority: 'HIGH',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ]);
        break;
        
      case 'ADMIN':
      case 'SUPERADMIN':
        demoNotifications.addAll([
          NotificationModel(
            id: 'demo-2',
            title: 'Новый пользователь',
            message: 'Зарегистрирован новый водитель Арман Вадиев',
            type: 'USER',
            priority: 'NORMAL',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
          ),
          NotificationModel(
            id: 'demo-3',
            title: 'Системное уведомление',
            message: 'Обновление системы завершено успешно',
            type: 'SYSTEM',
            priority: 'LOW',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
        ]);
        break;
        
      default:
        // Для остальных ролей
        demoNotifications.add(
          NotificationModel(
            id: 'demo-2',
            title: 'Новая задача',
            message: 'Вам назначена задача "Проверка документов"',
            type: 'TASK',
            priority: 'NORMAL',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
          ),
        );
    }
    
    _notifications = demoNotifications;
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






