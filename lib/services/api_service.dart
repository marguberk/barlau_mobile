import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/task.dart';
import '../models/trip.dart';
import '../models/vehicle.dart';
import '../models/employee.dart';
import '../models/map_location.dart';

class ApiService {
  static const String baseUrl = 'https://barlau.org/api';
  static const String localUrl = 'http://localhost:8000/api';
  static const String prodUrl = 'https://barlau.org/api';
  
  // Используем продакшн URL
  static const String apiUrl = prodUrl;

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    return headers;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/login/'),
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Неверный логин или пароль',
        };
      }
    } catch (e) {
      // Для демо - успешный вход с admin/admin
      if (username == 'admin' && password == 'admin') {
        await saveToken('demo_token');
        return {
          'success': true,
          'data': {
            'token': 'demo_token',
            'user': {
              'id': 1,
              'username': 'admin',
              'first_name': 'Администратор',
              'last_name': 'BARLAU.KZ',
              'email': 'admin@barlau.kz',
              'phone': '+7 777 123 45 67',
              'role': 'admin',
              'is_active': true,
            }
          }
        };
      }
      
      return {
        'success': false,
        'error': 'Ошибка подключения к серверу',
      };
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      await removeToken();
      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка при выходе',
      };
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Токен не найден',
        };
      }

      // Для демо возвращаем тестовые данные
      return {
        'success': true,
        'data': {
          'id': 1,
          'username': 'admin',
          'first_name': 'Администратор',
          'last_name': 'BARLAU.KZ',
          'email': 'admin@barlau.kz',
          'phone': '+7 777 123 45 67',
          'role': 'admin',
          'is_active': true,
        }
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка получения профиля',
      };
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Демо данные для дашборда
      await Future.delayed(const Duration(milliseconds: 500));
      
      return {
        'success': true,
        'data': {
          'active_trips': 12,
          'available_vehicles': 8,
          'total_employees': 45,
          'pending_tasks': 7,
        }
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка получения статистики',
      };
    }
  }

  // Методы для работы с рейсами
  Future<Map<String, dynamic>> getTrips() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Демо данные рейсов
      final tripsData = [
        {
          'id': 1,
          'from_location': 'Алматы',
          'to_location': 'Астана',
          'driver_name': 'Иванов И.И.',
          'vehicle_number': 'A123BC01',
          'start_time': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'status': 'in_progress',
          'distance': 1200.0,
          'cargo': 'Электроника',
        },
        {
          'id': 2,
          'from_location': 'Шымкент',
          'to_location': 'Караганда',
          'driver_name': 'Петров П.П.',
          'vehicle_number': 'B456CD02',
          'start_time': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
          'status': 'pending',
          'distance': 850.0,
          'cargo': 'Продукты питания',
        },
        {
          'id': 3,
          'from_location': 'Атырау',
          'to_location': 'Актобе',
          'driver_name': 'Сидоров С.С.',
          'vehicle_number': 'C789EF03',
          'start_time': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'end_time': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
          'status': 'completed',
          'distance': 600.0,
          'cargo': 'Строительные материалы',
        },
      ];

      return {
        'success': true,
        'data': tripsData,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка получения рейсов',
      };
    }
  }

  // Методы для работы с машинами
  Future<Map<String, dynamic>> getVehicles() async {
    try {
      final token = await getToken();
      
      // Всегда используем реальный API
      if (false) { // Отключаем демо данные
        await Future.delayed(const Duration(milliseconds: 600));
        
        final vehiclesData = [
          {
            'id': 1,
            'number': 'A123BC01',
            'model': 'Actros',
            'brand': 'Mercedes-Benz',
            'year': 2022,
            'status': 'ACTIVE',
            'driver': {
              'id': 1,
              'name': 'Иванов И.И.',
              'phone': '+7 777 123 4567',
            },
            'photo': null,
            'fuel_type': 'DIESEL',
            'fuel_type_display': 'Дизель',
            'cargo_capacity': 25000.0,
            'max_weight': 40000.0,
            'description': 'Тягач для дальних рейсов',
            'vehicle_type': 'TRUCK',
            'vehicle_type_display': 'Грузовой',
            'vin_number': 'WDB9630281L123456',
            'engine_number': 'OM471LA001234',
            'chassis_number': 'WDB9630281L123456',
            'engine_capacity': 12.8,
            'length': 6.2,
            'width': 2.5,
            'height': 3.8,
            'color': 'Белый',
            'status_display': 'Активен',
            'status_color': '#10B981',
          },
          {
            'id': 2,
            'number': 'B456CD02',
            'model': 'Volvo FH',
            'brand': 'Volvo',
            'year': 2021,
            'status': 'ACTIVE',
            'driver': {
              'id': 2,
              'name': 'Петров П.П.',
              'phone': '+7 701 987 6543',
            },
            'photo': null,
            'fuel_type': 'DIESEL',
            'fuel_type_display': 'Дизель',
            'cargo_capacity': 28000.0,
            'max_weight': 44000.0,
            'description': 'Тягач повышенной грузоподъемности',
            'vehicle_type': 'TRUCK',
            'vehicle_type_display': 'Грузовой',
            'vin_number': 'YV2R0AEKXMA123456',
            'engine_number': 'D13K500001234',
            'chassis_number': 'YV2R0AEKXMA123456',
            'engine_capacity': 12.8,
            'length': 6.1,
            'width': 2.5,
            'height': 3.9,
            'color': 'Синий',
            'status_display': 'Активен',
            'status_color': '#10B981',
          },
          {
            'id': 3,
            'number': 'C789EF03',
            'model': 'Scania R',
            'brand': 'Scania',
            'year': 2023,
            'status': 'MAINTENANCE',
            'driver': null,
            'photo': null,
            'fuel_type': 'DIESEL',
            'fuel_type_display': 'Дизель',
            'cargo_capacity': 30000.0,
            'max_weight': 46000.0,
            'description': 'Новый тягач премиум класса',
            'vehicle_type': 'TRUCK',
            'vehicle_type_display': 'Грузовой',
            'vin_number': 'YS2R8X40005123456',
            'engine_number': 'DC13162001234',
            'chassis_number': 'YS2R8X40005123456',
            'engine_capacity': 13.0,
            'length': 6.3,
            'width': 2.5,
            'height': 4.0,
            'color': 'Красный',
            'status_display': 'На обслуживании',
            'status_color': '#F59E0B',
          },
          {
            'id': 4,
            'number': 'D012GH04',
            'model': 'TGX',
            'brand': 'MAN',
            'year': 2020,
            'status': 'INACTIVE',
            'driver': null,
            'photo': null,
            'fuel_type': 'DIESEL',
            'fuel_type_display': 'Дизель',
            'cargo_capacity': 26000.0,
            'max_weight': 42000.0,
            'description': 'Тягач в резерве',
            'vehicle_type': 'TRUCK',
            'vehicle_type_display': 'Грузовой',
            'vin_number': 'WMA06XZZ6KM123456',
            'engine_number': 'D2676LF52001234',
            'chassis_number': 'WMA06XZZ6KM123456',
            'engine_capacity': 12.4,
            'length': 6.0,
            'width': 2.5,
            'height': 3.7,
            'color': 'Серый',
            'status_display': 'Неактивен',
            'status_color': '#6B7280',
          },
        ];

        return {
          'success': true,
          'data': vehiclesData,
        };
      }
      
      // Реальный API запрос (без авторизации для тестирования)
      final headers = _getHeaders();
      // Временно отключаем авторизацию
      // if (token != null) {
      //   headers['Authorization'] = 'Bearer $token';
      // }
      
      print('🚛 Запрос к API: $apiUrl/vehicles/');
      print('🚛 Полный URL: ${Uri.parse('$apiUrl/vehicles/')}');
      final response = await http.get(
        Uri.parse('$apiUrl/vehicles/'),
        headers: headers,
      );

      print('🚛 Ответ API: ${response.statusCode}');
      print('🚛 Длина ответа: ${response.body.length} символов');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Обрабатываем ответ от vehicles API
        List<Map<String, dynamic>> processedVehicles = [];
        
        // Обрабатываем ответ от logistics API
        if (data['results'] != null) {
          print('🚛 Найдено грузовиков: ${data['results'].length}');
          for (var vehicle in data['results']) {
            // Получаем основное фото из main_photo_url
            String? photoUrl;
            if (vehicle['main_photo_url'] != null && vehicle['main_photo_url'].isNotEmpty) {
              photoUrl = vehicle['main_photo_url'];
              // Если это относительный путь, добавляем базовый URL
              if (photoUrl!.startsWith('/media/')) {
                photoUrl = 'https://barlau.org$photoUrl';
              }
              // Исправляем localhost на продакшн URL
              if (photoUrl.contains('localhost')) {
                photoUrl = photoUrl.replaceAll('localhost:8000', 'barlau.org');
                photoUrl = photoUrl.replaceAll('http://', 'https://');
              }
              print('🖼️ Найдено фото для ${vehicle['number']}: $photoUrl');
            } else {
              print('❌ Нет фото для ${vehicle['number']}');
            }
            
            // Определяем статус и цвет
            String statusDisplay = '';
            String statusColor = '#6B7280';
            
            switch (vehicle['status']) {
              case 'ACTIVE':
                statusDisplay = 'Активен';
                statusColor = '#10B981';
                break;
              case 'INACTIVE':
                statusDisplay = 'Неактивен';
                statusColor = '#6B7280';
                break;
              case 'MAINTENANCE':
                statusDisplay = 'На обслуживании';
                statusColor = '#F59E0B';
                break;
              default:
                statusDisplay = vehicle['status'] ?? 'Неизвестно';
            }
            
            // Обрабатываем информацию о водителе
            Map<String, dynamic>? driverInfo;
            if (vehicle['driver_details'] != null) {
              driverInfo = {
                'id': vehicle['driver_details']['id'],
                'name': '${vehicle['driver_details']['first_name']} ${vehicle['driver_details']['last_name']}',
                'phone': vehicle['driver_details']['phone'],
                'photo': null,
              };
            }
            
            // Обрабатываем массив фотографий
            List<Map<String, dynamic>> processedPhotos = [];
            if (vehicle['photos'] != null && vehicle['photos'] is List) {
              for (var photo in vehicle['photos']) {
                String photoUrl = photo['photo'] ?? '';
                // Исправляем localhost на продакшн URL
                if (photoUrl.contains('localhost')) {
                  photoUrl = photoUrl.replaceAll('localhost:8000', 'barlau.org');
                  photoUrl = photoUrl.replaceAll('http://', 'https://');
                }
                
                processedPhotos.add({
                  'id': photo['id'],
                  'photo': photoUrl,
                  'description': photo['description'],
                  'is_main': photo['is_main'] ?? false,
                  'uploaded_at': photo['uploaded_at'],
                });
              }
            }

            // Добавляем тестовые документы для некоторых грузовиков
            List<Map<String, dynamic>> documents = [];
            if (vehicle['id'] == 1 || vehicle['id'] == 2 || vehicle['id'] == 4) {
              documents = [
                {
                  'id': 1,
                  'title': 'Свидетельство о регистрации ТС',
                  'document_type': 'REGISTRATION',
                  'description': 'Основной документ на транспортное средство',
                  'uploaded_at': '2024-01-15T10:30:00Z',
                  'expiry_date': '2026-01-15T00:00:00Z',
                  'document': 'https://barlau.org/media/documents/registration_${vehicle['id']}.pdf',
                },
                {
                  'id': 2,
                  'title': 'Страховой полис ОСАГО',
                  'document_type': 'INSURANCE',
                  'description': 'Обязательное страхование автогражданской ответственности',
                  'uploaded_at': '2024-03-01T14:20:00Z',
                  'expiry_date': '2025-03-01T00:00:00Z',
                  'document': 'https://barlau.org/media/documents/insurance_${vehicle['id']}.pdf',
                },
                {
                  'id': 3,
                  'title': 'Техосмотр',
                  'document_type': 'INSPECTION',
                  'description': 'Диагностическая карта технического осмотра',
                  'uploaded_at': '2024-02-10T09:15:00Z',
                  'expiry_date': '2025-02-10T00:00:00Z',
                  'document': 'https://barlau.org/media/documents/inspection_${vehicle['id']}.pdf',
                },
              ];
              
              // Для грузовика с ID 4 добавляем просроченный документ
              if (vehicle['id'] == 4) {
                documents.add({
                  'id': 4,
                  'title': 'Лицензия на перевозки',
                  'document_type': 'LICENSE',
                  'description': 'Лицензия на осуществление грузовых перевозок',
                  'uploaded_at': '2023-06-01T12:00:00Z',
                  'expiry_date': '2024-06-01T00:00:00Z', // Просроченный
                  'document': 'https://barlau.org/media/documents/license_${vehicle['id']}.pdf',
                });
              }
            }

            // Формируем объект грузовика в нужном формате
            processedVehicles.add({
              'id': vehicle['id'],
              'number': vehicle['number'],
              'brand': vehicle['brand'],
              'model': vehicle['model'],
              'year': vehicle['year'],
              'status': vehicle['status'],
              'status_display': statusDisplay,
              'status_color': statusColor,
              'driver_details': vehicle['driver_details'],
              'main_photo_url': photoUrl,
              'photos': processedPhotos,
              'color': vehicle['color'],
              'vehicle_type': vehicle['vehicle_type'],
              'vehicle_type_display': vehicle['vehicle_type'] == 'TRUCK' ? 'Грузовой' : 'Легковой',
              'fuel_type': vehicle['fuel_type'],
              'fuel_type_display': vehicle['fuel_type'] == 'DIESEL' ? 'Дизель' : vehicle['fuel_type'],
              'vin_number': vehicle['vin_number'],
              'engine_number': vehicle['engine_number'],
              'chassis_number': vehicle['chassis_number'],
              'engine_capacity': vehicle['engine_capacity'],
              'length': vehicle['length'],
              'width': vehicle['width'],
              'height': vehicle['height'],
              'max_weight': vehicle['max_weight'],
              'cargo_capacity': vehicle['cargo_capacity'],
              'description': vehicle['description'],
              'documents': documents, // Добавляем документы в ответ
            });
          }
        }
        
        return {
          'success': true,
          'data': processedVehicles,
        };
      } else {
        return {
          'success': false,
          'error': 'Ошибка получения грузовиков: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка подключения к серверу: $e',
      };
    }
  }

  // Методы для работы с задачами
  Future<Map<String, dynamic>> getTasks() async {
    try {
      await Future.delayed(const Duration(milliseconds: 700));
      
      // Демо данные задач
      final tasksData = [
        {
          'id': 1,
          'title': 'Проверить документы на груз',
          'description': 'Убедиться что все документы на груз в порядке перед отправкой',
          'priority': 'HIGH',
          'status': 'NEW',
          'due_date': DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
          'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'updated_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          'assigned_user_details': {
            'id': 2,
            'first_name': 'Асхат',
            'last_name': 'Жанбаев',
            'phone': '+7 777 123 4567',
            'role': 'DRIVER',
          },
          'created_by_details': {
            'id': 1,
            'first_name': 'Администратор',
            'last_name': '',
            'phone': 'admin',
            'role': 'SUPERADMIN',
          },
          'vehicle_details': {
            'id': 1,
            'brand': 'Mercedes',
            'model': 'Actros',
            'number': 'A123BC01',
            'status': 'AVAILABLE',
          },
        },
        {
          'id': 2,
          'title': 'Заправить автомобиль',
          'description': 'Заправить полный бак перед дальней поездкой в Астану',
          'priority': 'MEDIUM',
          'status': 'IN_PROGRESS',
          'due_date': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
          'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
          'updated_at': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
          'assigned_user_details': {
            'id': 3,
            'first_name': 'Ерлан',
            'last_name': 'Смагулов',
            'phone': '+7 701 987 6543',
            'role': 'DRIVER',
          },
          'created_by_details': {
            'id': 1,
            'first_name': 'Администратор',
            'last_name': '',
            'phone': 'admin',
            'role': 'SUPERADMIN',
          },
          'vehicle_details': {
            'id': 2,
            'brand': 'Volvo',
            'model': 'FH16',
            'number': 'B456DE02',
            'status': 'BUSY',
          },
        },
        {
          'id': 3,
          'title': 'Техосмотр перед рейсом',
          'description': 'Провести полный технический осмотр автомобиля перед дальним рейсом',
          'priority': 'HIGH',
          'status': 'COMPLETED',
          'due_date': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
          'updated_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          'assigned_user_details': {
            'id': 4,
            'first_name': 'Дархан',
            'last_name': 'Оспанов',
            'phone': '+7 775 555 1234',
            'role': 'DRIVER',
          },
          'created_by_details': {
            'id': 1,
            'first_name': 'Администратор',
            'last_name': '',
            'phone': 'admin',
            'role': 'SUPERADMIN',
          },
          'vehicle_details': {
            'id': 3,
            'brand': 'Scania',
            'model': 'R450',
            'number': 'C789FG03',
            'status': 'MAINTENANCE',
          },
        },
        {
          'id': 4,
          'title': 'Обновить данные водителя',
          'description': 'Обновить персональные данные и документы водителя в системе',
          'priority': 'LOW',
          'status': 'NEW',
          'due_date': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
          'created_at': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
          'updated_at': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
          'assigned_user_details': {
            'id': 5,
            'first_name': 'Айдар',
            'last_name': 'Касымов',
            'phone': '+7 708 111 2233',
            'role': 'DRIVER',
          },
          'created_by_details': {
            'id': 1,
            'first_name': 'Администратор',
            'last_name': '',
            'phone': 'admin',
            'role': 'SUPERADMIN',
          },
        },
        {
          'id': 5,
          'title': 'Подготовить отчет по рейсу',
          'description': 'Составить детальный отчет по завершенному рейсу с указанием всех расходов',
          'priority': 'MEDIUM',
          'status': 'IN_PROGRESS',
          'due_date': DateTime.now().add(const Duration(hours: 6)).toIso8601String(),
          'created_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
          'updated_at': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
          'assigned_user_details': {
            'id': 2,
            'first_name': 'Асхат',
            'last_name': 'Жанбаев',
            'phone': '+7 777 123 4567',
            'role': 'DRIVER',
          },
          'created_by_details': {
            'id': 1,
            'first_name': 'Администратор',
            'last_name': '',
            'phone': 'admin',
            'role': 'SUPERADMIN',
          },
        },
      ];

      return {
        'success': true,
        'data': tasksData,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка получения задач',
      };
    }
  }

  // Изменить статус задачи
  Future<Map<String, dynamic>> updateTaskStatus(int taskId, String newStatus) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      return {
        'success': true,
        'message': 'Статус задачи обновлен',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка обновления статуса задачи',
      };
    }
  }

  // Методы для работы с сотрудниками
  static Future<List<Employee>> getEmployees() async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      
      // Демо данные сотрудников
      final employeesData = [
        {
          'id': 1,
          'name': 'Асхат Жанбаев',
          'position': 'Водители',
          'phone': '+7 777 123 4567',
          'email': 'askhat@barlau.kz',
          'is_active': true,
          'hire_date': '2022-03-15',
        },
        {
          'id': 2,
          'name': 'Ерлан Смагулов',
          'position': 'Водители',
          'phone': '+7 701 987 6543',
          'email': 'erlan@barlau.kz',
          'is_active': true,
          'hire_date': '2021-08-20',
        },
        {
          'id': 3,
          'name': 'Дархан Оспанов',
          'position': 'Механики',
          'phone': '+7 775 555 1234',
          'email': 'darkhan@barlau.kz',
          'is_active': true,
          'hire_date': '2020-11-10',
        },
        {
          'id': 4,
          'name': 'Айдар Касымов',
          'position': 'Водители',
          'phone': '+7 708 111 2233',
          'email': 'aidar@barlau.kz',
          'is_active': false,
          'hire_date': '2023-01-05',
        },
        {
          'id': 5,
          'name': 'Марат Алиев',
          'position': 'Диспетчеры',
          'phone': '+7 747 888 9999',
          'email': 'marat@barlau.kz',
          'is_active': true,
          'hire_date': '2019-06-12',
        },
        {
          'id': 6,
          'name': 'Нурлан Сейтов',
          'position': 'Водители',
          'phone': '+7 702 444 5555',
          'email': 'nurlan@barlau.kz',
          'is_active': true,
          'hire_date': '2022-09-30',
        },
        {
          'id': 7,
          'name': 'Болат Турсунов',
          'position': 'Механики',
          'phone': '+7 771 333 7777',
          'email': 'bolat@barlau.kz',
          'is_active': true,
          'hire_date': '2021-04-18',
        },
        {
          'id': 8,
          'name': 'Амир Жумабаев',
          'position': 'Диспетчеры',
          'phone': '+7 778 222 6666',
          'email': 'amir@barlau.kz',
          'is_active': true,
          'hire_date': '2020-02-14',
        },
      ];

      return employeesData.map((data) => Employee.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки сотрудников');
    }
  }

  // Методы для работы с картой
  static Future<List<MapLocation>> getMapLocations() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Демо данные для карты (Алматы и окрестности)
      final locationsData = [
        {
          'id': 1,
          'name': 'Главная база BARLAU.KZ',
          'latitude': 43.2220,
          'longitude': 76.8512,
          'type': 'depot',
          'description': 'Центральная база компании',
        },
        {
          'id': 2,
          'name': 'Склад №1',
          'latitude': 43.2380,
          'longitude': 76.8890,
          'type': 'warehouse',
          'description': 'Основной склад',
        },
        {
          'id': 3,
          'name': 'Mercedes Actros',
          'latitude': 43.2567,
          'longitude': 76.9286,
          'type': 'vehicle',
          'description': 'A123BC01 - В пути Алматы-Астана',
          'vehicle_id': 'A123BC01',
          'status': 'moving',
        },
        {
          'id': 4,
          'name': 'Volvo FH16',
          'latitude': 43.1950,
          'longitude': 76.8080,
          'type': 'vehicle',
          'description': 'B456CD02 - На базе',
          'vehicle_id': 'B456CD02',
          'status': 'parked',
        },
        {
          'id': 5,
          'name': 'АЗС КазМунайГаз',
          'latitude': 43.2450,
          'longitude': 76.9150,
          'type': 'gas_station',
          'description': 'Заправочная станция',
        },
        {
          'id': 6,
          'name': 'Клиент - ТОО Рахат',
          'latitude': 43.2100,
          'longitude': 76.8700,
          'type': 'client',
          'description': 'Точка доставки',
        },
        {
          'id': 7,
          'name': 'Scania R450',
          'latitude': 43.2800,
          'longitude': 76.9500,
          'type': 'vehicle',
          'description': 'C789EF03 - На ремонте',
          'vehicle_id': 'C789EF03',
          'status': 'maintenance',
        },
        {
          'id': 8,
          'name': 'Сервисный центр',
          'latitude': 43.2750,
          'longitude': 76.9450,
          'type': 'service',
          'description': 'Ремонт и обслуживание',
        },
      ];

      return locationsData.map((data) => MapLocation.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки местоположений');
    }
  }

  static Future<Map<String, dynamic>> getVehicleLocation(String vehicleId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Демо данные для конкретного транспорта
      final vehicleLocations = {
        'A123BC01': {
          'latitude': 43.2567,
          'longitude': 76.9286,
          'speed': 65.0,
          'heading': 45.0,
          'last_update': DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
        },
        'B456CD02': {
          'latitude': 43.1950,
          'longitude': 76.8080,
          'speed': 0.0,
          'heading': 0.0,
          'last_update': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
        },
        'C789EF03': {
          'latitude': 43.2800,
          'longitude': 76.9500,
          'speed': 0.0,
          'heading': 0.0,
          'last_update': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
      };

      return {
        'success': true,
        'data': vehicleLocations[vehicleId] ?? {
          'latitude': 43.2220,
          'longitude': 76.8512,
          'speed': 0.0,
          'heading': 0.0,
          'last_update': DateTime.now().toIso8601String(),
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка получения местоположения транспорта',
      };
    }
  }

  // Тестовый метод для проверки подключения
  Future<Map<String, dynamic>> testConnection() async {
    try {
      print('🧪 Тестируем подключение к: $apiUrl');
      final response = await http.get(
        Uri.parse('$apiUrl/vehicles/'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      print('🧪 Статус ответа: ${response.statusCode}');
      print('🧪 Размер ответа: ${response.body.length} байт');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🧪 Структура ответа: ${data.keys.toList()}');
        
        if (data['results'] != null) {
          print('🧪 Количество грузовиков: ${data['results'].length}');
          if (data['results'].isNotEmpty) {
            final firstVehicle = data['results'][0];
            print('🧪 Первый грузовик: ${firstVehicle['number']}');
            if (firstVehicle['photos'] != null && firstVehicle['photos'].isNotEmpty) {
              final photo = firstVehicle['photos'][0];
              print('🧪 Первое фото: ${photo['photo']}');
            }
          }
        }
        
        return {
          'success': true,
          'data': 'Подключение успешно, получено ${data['results']?.length ?? 0} грузовиков'
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      print('🧪 Ошибка подключения: $e');
      return {
        'success': false,
        'error': 'Ошибка подключения: $e'
      };
    }
  }
} 
 
 
 