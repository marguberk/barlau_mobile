import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SafeApiService {
  static const String prodUrl = 'https://barlau.org/api';
  static const Duration timeout = Duration(seconds: 5);
  
  // Безопасный HTTP запрос с таймаутом
  static Future<Map<String, dynamic>> safeRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$prodUrl$endpoint');
      final defaultHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?headers,
      };
      
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(
            uri,
            headers: defaultHeaders,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(timeout);
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: defaultHeaders,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(timeout);
          break;
        case 'DELETE':
          response = await http.delete(
            uri,
            headers: defaultHeaders,
          ).timeout(timeout);
          break;
        default:
          response = await http.get(
            uri,
            headers: defaultHeaders,
          ).timeout(timeout);
      }
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = response.body.isNotEmpty 
            ? jsonDecode(response.body) 
            : {};
        return {
          'success': true,
          'data': data,
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('SafeApiService: Ошибка запроса к $endpoint - $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
        'statusCode': 0,
      };
    }
  }
  
  // Проверка доступности сервера
  static Future<bool> isServerAvailable() async {
    try {
      final result = await safeRequest('/vehicles/', headers: {'timeout': '3'});
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }
  
  // Безопасная авторизация
  static Future<Map<String, dynamic>> safeLogin(String username, String password) async {
    try {
      print('SafeApiService: Попытка входа для $username');
      
      // Для демо режима
      if (username == 'admin' && password == 'admin') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', 'demo_token');
        await prefs.setString('user_role', 'SUPERADMIN');
        await prefs.setString('user_name', 'admin');
        
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
              'role': 'SUPERADMIN',
              'is_active': true,
            }
          }
        };
      }
      
      // Для тестовых водителей
      if ((username == 'yunus' || username == 'arman') && password == '123') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', 'demo_driver_token');
        await prefs.setString('user_role', 'DRIVER');
        await prefs.setString('user_name', username);
        
        Map<String, dynamic> userData = {
          'id': username == 'yunus' ? 15 : 16,
          'username': username,
          'role': 'DRIVER',
          'is_active': true,
        };
        
        if (username == 'yunus') {
          userData.addAll({
            'first_name': 'Юнус',
            'last_name': 'Алиев',
            'email': 'yunus@gmail.com',
            'phone': '+7 (777) 159 03 06',
          });
        } else {
          userData.addAll({
            'first_name': 'Арман',
            'last_name': 'Вадиев',
            'email': 'arman@gmail.com',
            'phone': '+7 (777) 123 45 67',
          });
        }
        
        print('SafeApiService: Водитель $username успешно авторизован');
        return {
          'success': true,
          'data': {
            'token': 'demo_driver_token',
            'user': userData,
          }
        };
      }
      
      // Пробуем реальную авторизацию через JWT endpoint
      print('SafeApiService: Отправляем запрос к /auth/token/');
      final result = await safeRequest('/auth/token/', 
        method: 'POST',
        body: {
          'username': username,
          'password': password,
        }
      );
      
      print('SafeApiService: Результат авторизации: ${result['success']}');
      if (result['success']) {
        print('SafeApiService: Токен получен: ${result['data']['access'] != null}');
        
        // JWT возвращает access и refresh токены
        if (result['data']['access'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', result['data']['access']);
          await prefs.setString('refresh_token', result['data']['refresh'] ?? '');
          
          // Получаем информацию о пользователе отдельным запросом
          print('SafeApiService: Получаем профиль пользователя');
          
          // Пробуем разные endpoints для получения профиля
          List<String> profileEndpoints = ['/employees/me/', '/users/me/', '/profile/'];
          Map<String, dynamic>? profileResult;
          
          for (String endpoint in profileEndpoints) {
            print('SafeApiService: Пробуем endpoint $endpoint');
            final tempResult = await safeRequest(endpoint, 
              headers: {
                'Authorization': 'Bearer ${result['data']['access']}',
              }
            );
            if (tempResult['success']) {
              profileResult = tempResult;
              print('SafeApiService: Успешно получен профиль через $endpoint');
              break;
            }
          }
          
          if (profileResult != null && profileResult['success']) {
            final user = profileResult['data'];
            await prefs.setString('user_role', user['role'] ?? 'DRIVER');
            await prefs.setString('user_name', user['username'] ?? username);
            
            return {
              'success': true,
              'data': {
                'token': result['data']['access'],
                'user': user,
              }
            };
          } else {
            print('SafeApiService: Не удалось получить профиль через API');
            // Декодируем JWT токен для получения информации о пользователе
            try {
              final tokenParts = result['data']['access'].split('.');
              if (tokenParts.length >= 2) {
                final payload = tokenParts[1];
                // Добавляем padding если нужно
                String normalizedPayload = payload;
                switch (payload.length % 4) {
                  case 1:
                    normalizedPayload += '===';
                    break;
                  case 2:
                    normalizedPayload += '==';
                    break;
                  case 3:
                    normalizedPayload += '=';
                    break;
                }
                
                final decodedBytes = base64Decode(normalizedPayload);
                final decodedPayload = utf8.decode(decodedBytes);
                final tokenData = jsonDecode(decodedPayload);
                
                print('SafeApiService: Данные из JWT токена: $tokenData');
                
                return {
                  'success': true,
                  'data': {
                    'token': result['data']['access'],
                    'user': {
                      'id': tokenData['user_id'] ?? 0,
                      'username': tokenData['username'] ?? username,
                      'first_name': tokenData['first_name'] ?? '',
                      'last_name': tokenData['last_name'] ?? '',
                      'email': tokenData['email'] ?? '',
                      'phone': tokenData['phone'] ?? '',
                      'role': tokenData['role'] ?? 'DRIVER',
                      'is_active': true,
                    }
                  }
                };
              }
            } catch (e) {
              print('SafeApiService: Ошибка декодирования JWT: $e');
            }
            
            // Создаем базовый профиль пользователя
            return {
              'success': true,
              'data': {
                'token': result['data']['access'],
                'user': {
                  'username': username,
                  'first_name': '',
                  'last_name': '',
                  'email': '',
                  'phone': '',
                  'role': 'DRIVER',
                  'is_active': true,
                }
              }
            };
          }
        }
      } else {
        print('SafeApiService: Ошибка авторизации: ${result['error']}');
      }
      
      return result;
    } catch (e) {
      print('SafeApiService: Исключение при авторизации: $e');
      return {
        'success': false,
        'error': 'Ошибка авторизации: $e',
      };
    }
  }
  
  // Получение данных с fallback
  static Future<Map<String, dynamic>> getDataWithFallback(
    String endpoint,
    List<Map<String, dynamic>> fallbackData,
  ) async {
    try {
      final result = await safeRequest(endpoint);
      
      if (result['success']) {
        return {
          'success': true,
          'data': result['data'],
          'source': 'server',
        };
      } else {
        return {
          'success': true,
          'data': fallbackData,
          'source': 'fallback',
          'warning': 'Используются тестовые данные',
        };
      }
    } catch (e) {
      return {
        'success': true,
        'data': fallbackData,
        'source': 'fallback',
        'warning': 'Сервер недоступен, используются тестовые данные',
      };
    }
  }
} 