import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WialonService {
  static const String _baseUrl = 'https://hosting.wialon.com';
  static const String _apiUrl = 'https://hosting.wialon.com/wialon/ajax.html';
  
  String? _token;
  String? _userId;
  
  /// Получение токена авторизации с полными правами
  Future<String?> getAuthToken({String? userName}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedToken = prefs.getString('wialon_token');
      final tokenExpiry = prefs.getInt('wialon_token_expiry');
      
      // Проверяем, есть ли валидный токен в кэше
      if (cachedToken != null && tokenExpiry != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now < tokenExpiry) {
          _token = cachedToken;
          print('✅ Используем кэшированный токен Wialon');
          return cachedToken;
        }
      }
      
      // Получаем новый токен
      final user = userName ?? 'BARLAU_KZ';
      final authUrl = '$_baseUrl/login.html?'
          'client_id=hosting.wialon.com/&'
          'access_type=-1&'
          'activation_time=0&'
          'duration=0&'
          'lang=ru&'
          'flags=0&'
          'user=$user&'
          'redirect_uri=login.html&'
          'response_type=token&'
          'css_url';
      
      print('🔐 Получаем токен Wialon: $authUrl');
      
      final response = await http.get(Uri.parse(authUrl));
      
      if (response.statusCode == 200) {
        // Извлекаем токен из ответа
        final body = response.body;
        final tokenMatch = RegExp(r'token=([^&]+)').firstMatch(body);
        
        if (tokenMatch != null) {
          _token = tokenMatch.group(1);
          
          // Сохраняем токен в кэш (на 24 часа)
          final expiry = DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch;
          await prefs.setString('wialon_token', _token!);
          await prefs.setInt('wialon_token_expiry', expiry);
          
          print('✅ Токен Wialon получен и сохранен');
          return _token;
        }
      }
      
      print('❌ Ошибка получения токена Wialon: ${response.statusCode}');
      return null;
      
    } catch (e) {
      print('❌ Ошибка авторизации Wialon: $e');
      return null;
    }
  }
  
  /// Отправка запроса к Wialon API
  Future<Map<String, dynamic>?> _makeRequest({
    required String svc,
    required Map<String, dynamic> params,
  }) async {
    try {
      if (_token == null) {
        await getAuthToken();
        if (_token == null) {
          print('❌ Не удалось получить токен Wialon');
          return null;
        }
      }
      
      final requestData = {
        'svc': svc,
        'params': json.encode(params),
        'sid': _token,
      };
      
      print('🌐 Wialon API запрос: $svc');
      
      final response = await http.post(
        Uri.parse(_apiUrl),
        body: requestData,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['error'] != null) {
          print('❌ Wialon API ошибка: ${data['error']}');
          return null;
        }
        
        return data;
      }
      
      print('❌ Ошибка Wialon API: ${response.statusCode}');
      return null;
      
    } catch (e) {
      print('❌ Ошибка Wialon API запроса: $e');
      return null;
    }
  }
  
  /// Получение списка всех трекеров
  Future<List<Map<String, dynamic>>?> getTrackers() async {
    try {
      final result = await _makeRequest(
        svc: 'core/search_items',
        params: {
          'spec': {
            'itemsType': 'avl_resource',
            'propName': 'sys_name',
            'propValueMask': '*',
            'sortType': 'sys_name',
          },
          'force': 1,
          'flags': 0x1,
        },
      );
      
      if (result != null && result['items'] != null) {
        final items = List<Map<String, dynamic>>.from(result['items']);
        print('📡 Найдено трекеров: ${items.length}');
        return items;
      }
      
      return null;
      
    } catch (e) {
      print('❌ Ошибка получения трекеров: $e');
      return null;
    }
  }
  
  /// Получение данных о местоположении трекера
  Future<Map<String, dynamic>?> getTrackerLocation(String trackerId) async {
    try {
      final result = await _makeRequest(
        svc: 'core/search_items',
        params: {
          'spec': {
            'itemsType': 'avl_unit',
            'propName': 'sys_id',
            'propValueMask': trackerId,
            'sortType': 'sys_name',
          },
          'force': 1,
          'flags': 0x1,
        },
      );
      
      if (result != null && result['items'] != null && result['items'].isNotEmpty) {
        final tracker = result['items'][0];
        print('📍 Данные трекера $trackerId получены');
        return tracker;
      }
      
      return null;
      
    } catch (e) {
      print('❌ Ошибка получения данных трекера: $e');
      return null;
    }
  }
  
  /// Получение истории маршрута
  Future<List<Map<String, dynamic>>?> getRouteHistory({
    required String trackerId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final result = await _makeRequest(
        svc: 'core/search_items',
        params: {
          'spec': {
            'itemsType': 'avl_unit',
            'propName': 'sys_id',
            'propValueMask': trackerId,
            'sortType': 'sys_name',
          },
          'force': 1,
          'flags': 0x1,
        },
      );
      
      if (result != null && result['items'] != null && result['items'].isNotEmpty) {
        final tracker = result['items'][0];
        
        // Получаем историю маршрута
        final historyResult = await _makeRequest(
          svc: 'core/search_items',
          params: {
            'spec': {
              'itemsType': 'avl_unit',
              'propName': 'sys_id',
              'propValueMask': trackerId,
              'sortType': 'sys_name',
            },
            'force': 1,
            'flags': 0x1,
            'timeFrom': startTime.millisecondsSinceEpoch ~/ 1000,
            'timeTo': endTime.millisecondsSinceEpoch ~/ 1000,
          },
        );
        
        if (historyResult != null && historyResult['items'] != null) {
          final history = List<Map<String, dynamic>>.from(historyResult['items']);
          print('🛣️ История маршрута получена: ${history.length} точек');
          return history;
        }
      }
      
      return null;
      
    } catch (e) {
      print('❌ Ошибка получения истории маршрута: $e');
      return null;
    }
  }
  
  /// Получение статуса трекера (онлайн/оффлайн)
  Future<bool?> isTrackerOnline(String trackerId) async {
    try {
      final location = await getTrackerLocation(trackerId);
      if (location != null) {
        final lastMessage = location['last_message_time'];
        if (lastMessage != null) {
          final lastMessageTime = DateTime.fromMillisecondsSinceEpoch(lastMessage * 1000);
          final now = DateTime.now();
          final difference = now.difference(lastMessageTime);
          
          // Считаем трекер онлайн, если последнее сообщение было менее 5 минут назад
          return difference.inMinutes < 5;
        }
      }
      
      return false;
      
    } catch (e) {
      print('❌ Ошибка проверки статуса трекера: $e');
      return null;
    }
  }
  
  /// Получение всех трекеров с их статусом
  Future<List<Map<String, dynamic>>?> getAllTrackersWithStatus() async {
    try {
      final trackers = await getTrackers();
      if (trackers == null) return null;
      
      final trackersWithStatus = <Map<String, dynamic>>[];
      
      for (final tracker in trackers) {
        final trackerId = tracker['id'];
        final isOnline = await isTrackerOnline(trackerId);
        
        trackersWithStatus.add({
          ...tracker,
          'is_online': isOnline ?? false,
        });
      }
      
      print('📊 Статус трекеров обновлен: ${trackersWithStatus.length}');
      return trackersWithStatus;
      
    } catch (e) {
      print('❌ Ошибка получения статуса трекеров: $e');
      return null;
    }
  }
}

// Модель данных трекера
class WialonTracker {
  final String id;
  final String name;
  final bool isOnline;
  final double? latitude;
  final double? longitude;
  final double? speed;
  final DateTime? lastMessageTime;
  
  WialonTracker({
    required this.id,
    required this.name,
    required this.isOnline,
    this.latitude,
    this.longitude,
    this.speed,
    this.lastMessageTime,
  });
  
  factory WialonTracker.fromJson(Map<String, dynamic> json) {
    return WialonTracker(
      id: json['id'] ?? '',
      name: json['nm'] ?? '',
      isOnline: json['is_online'] ?? false,
      latitude: json['pos']?['y']?.toDouble(),
      longitude: json['pos']?['x']?.toDouble(),
      speed: json['pos']?['s']?.toDouble(),
      lastMessageTime: json['last_message_time'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['last_message_time'] * 1000)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_online': isOnline,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'last_message_time': lastMessageTime?.millisecondsSinceEpoch,
    };
  }
}
