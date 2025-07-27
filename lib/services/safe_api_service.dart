import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class SafeApiService {
  static String get prodUrl => AppConfig.baseApiUrl;
  static const Duration timeout = Duration(seconds: 5);
  
  // Безопасный HTTP запрос с таймаутом
  static Future<Map<String, dynamic>> safeRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseApiUrl}$endpoint');
      print('🌐 SafeAPI Request: $method $uri');
      
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
      
      print('🌐 SafeAPI Response: ${response.statusCode}');
      
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
      print('🔴 SafeApiService: Ошибка запроса к $endpoint - $e');
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
      
      // Пробуем реальную авторизацию через JWT endpoint
      print('SafeApiService: Отправляем запрос к /v1/auth/token/');
      final result = await safeRequest('/v1/auth/token/', 
        method: 'POST',
        body: {
          'username': username,
          'password': password,
        }
      );
      
      if (result['success'] && result['data'] != null) {
        print('SafeApiService: Успешная авторизация через API');
        
        // Сохраняем реальный токен из ответа API
          final prefs = await SharedPreferences.getInstance();
        final token = result['data']['access'] ?? result['data']['token'];
        if (token != null) {
          await prefs.setString('auth_token', token);
          print('SafeApiService: Реальный токен сохранен: ${token.substring(0, 20)}...');
        }
        
        // Получаем данные пользователя
        print('SafeApiService: Получаем данные пользователя...');
        final userResult = await safeRequest('/v1/users/me/', headers: {
          'Authorization': 'Bearer $token',
        });
        
        if (userResult['success'] && userResult['data'] != null) {
          final userData = userResult['data'];
          final userRole = userData['role'] ?? 'DRIVER';
          
          // Сохраняем данные пользователя
          await prefs.setString('user_role', userRole);
          await prefs.setString('user_name', username);
          await prefs.setString('user_profile', jsonEncode(userData));
          
          print('SafeApiService: Данные пользователя сохранены - роль: $userRole');
            
            return {
              'success': true,
              'data': {
              'token': token,
              'user': userData,
              }
            };
          } else {
          print('SafeApiService: Ошибка получения данных пользователя: ${userResult['error']}');
          // Возвращаем данные без профиля пользователя
                return {
                  'success': true,
                  'data': {
              'token': token,
              'user': {'username': username, 'role': 'DRIVER'},
                  }
                };
              }
      } else {
        print('SafeApiService: Ошибка авторизации через API: ${result['error']}');
        
        // Определяем конкретную ошибку
        String errorMessage = 'Неверный логин или пароль';
        if (result['error'] != null) {
          if (result['error'].toString().contains('401') || result['error'].toString().contains('Unauthorized')) {
            errorMessage = 'Неверный логин или пароль';
          } else if (result['error'].toString().contains('400') || result['error'].toString().contains('Bad Request')) {
            errorMessage = 'Неверный формат данных';
          } else if (result['error'].toString().contains('500') || result['error'].toString().contains('Internal Server Error')) {
            errorMessage = 'Ошибка сервера, попробуйте позже';
          } else if (result['error'].toString().contains('timeout') || result['error'].toString().contains('Connection')) {
            errorMessage = 'Нет подключения к серверу';
          }
      }
      
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      print('SafeApiService: Ошибка авторизации: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
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

  // Обновление профиля пользователя
  static Future<Map<String, dynamic>> updateUserProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? profilePicture,
    bool removeAvatar = false,
  }) async {
    try {
      print('SafeApiService: Обновление профиля пользователя');
      
      // Получаем токен авторизации
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        return {
          'success': false,
          'error': 'Токен авторизации не найден',
        };
      }

      // Подготавливаем данные для отправки
      final updateData = <String, dynamic>{
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
      };

      if (removeAvatar) {
        updateData['photo'] = null;
      } else if (profilePicture != null) {
        // Загружаем фото как файл
        try {
          final file = File(profilePicture);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final base64Image = base64Encode(bytes);
            // Определяем расширение файла
            final extension = profilePicture.split('.').last.toLowerCase();
            final mimeType = extension == 'jpg' || extension == 'jpeg' 
                ? 'image/jpeg' 
                : extension == 'png' 
                    ? 'image/png' 
                    : 'image/jpeg';
            updateData['photo'] = 'data:$mimeType;base64,$base64Image';
            print('SafeApiService: Фото загружено и закодировано в base64');
          } else {
            print('SafeApiService: Файл фото не найден: $profilePicture');
          }
        } catch (e) {
          print('SafeApiService: Ошибка загрузки фото: $e');
        }
      }

      print('SafeApiService: Отправляем данные: $updateData');

      // Отправляем запрос на обновление профиля
      final result = await safeRequest('/v1/users/me/', 
        method: 'PUT',
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: updateData,
      );

      if (result['success'] && result['data'] != null) {
        print('SafeApiService: Профиль успешно обновлен на сервере');
        
        // Обновляем локальные данные пользователя
        await prefs.setString('user_profile', jsonEncode(result['data']));
        
        return {
          'success': true,
          'data': result['data'],
        };
      } else {
        print('SafeApiService: Ошибка обновления профиля: ${result['error']}');
        return {
          'success': false,
          'error': result['error'] ?? 'Ошибка обновления профиля',
        };
      }
    } catch (e) {
      print('SafeApiService: Ошибка обновления профиля: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }
} 