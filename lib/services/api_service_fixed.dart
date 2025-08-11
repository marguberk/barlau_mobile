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
      return {
        'success': false,
        'error': 'Ошибка подключения к серверу',
      };
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      await removeToken();
      return {
        'success': true,
        'message': 'Выход выполнен успешно',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка при выходе',
      };
    }
  }

  // Методы для работы с рейсами
  Future<Map<String, dynamic>> getTrips() async {
    try {
      final token = await getToken();
      final headers = _getHeaders(includeAuth: true);
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$apiUrl/trips/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['results'] ?? data,
        };
      } else {
        return {
          'success': false,
          'error': 'Ошибка получения рейсов: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка получения рейсов: $e',
      };
    }
  }

  // Методы для работы с машинами
  Future<Map<String, dynamic>> getVehicles() async {
    try {
      final token = await getToken();
      final headers = _getHeaders(includeAuth: true);
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$apiUrl/vehicles/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['results'] ?? data,
        };
      } else {
        return {
          'success': false,
          'error': 'Ошибка получения машин: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка получения машин: $e',
      };
    }
  }

  // Методы для работы с задачами
  Future<Map<String, dynamic>> getTasks() async {
    try {
      final token = await getToken();
      final headers = _getHeaders(includeAuth: true);
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$apiUrl/tasks/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['results'] ?? data,
        };
      } else {
        return {
          'success': false,
          'error': 'Ошибка получения задач: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка получения задач: $e',
      };
    }
  }

  // Изменить статус задачи
  Future<Map<String, dynamic>> updateTaskStatus(int taskId, String newStatus) async {
    try {
      final token = await getToken();
      final headers = _getHeaders(includeAuth: true);
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.patch(
        Uri.parse('$apiUrl/tasks/$taskId/'),
        headers: headers,
        body: jsonEncode({
          'status': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Статус задачи обновлен',
        };
      } else {
        return {
          'success': false,
          'error': 'Ошибка обновления статуса задачи',
        };
      }
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
      final apiService = ApiService();
      final token = await apiService.getToken();
      final headers = apiService._getHeaders(includeAuth: true);
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('${apiService.apiUrl}/employees/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final employeesData = data['results'] ?? data;
        return employeesData.map((data) => Employee.fromJson(data)).toList();
      } else {
        throw Exception('Ошибка загрузки сотрудников: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки сотрудников: $e');
    }
  }

  // Методы для работы с расходами
  Future<Map<String, dynamic>> getExpenses() async {
    try {
      final token = await getToken();
      final headers = _getHeaders(includeAuth: true);
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$apiUrl/expenses/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['results'] ?? data,
        };
      } else {
        return {
          'success': false,
          'error': 'Ошибка получения расходов: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка получения расходов: $e',
      };
    }
  }

  // Методы для работы с картой
  static Future<List<MapLocation>> getMapLocations() async {
    try {
      final apiService = ApiService();
      final token = await apiService.getToken();
      final headers = apiService._getHeaders(includeAuth: true);
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('${apiService.apiUrl}/map-locations/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final locationsData = data['results'] ?? data;
        return locationsData.map((data) => MapLocation.fromJson(data)).toList();
      } else {
        throw Exception('Ошибка загрузки локаций карты: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки локаций карты: $e');
    }
  }
} 