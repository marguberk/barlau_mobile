import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  // 🎯 КОНФИГУРАЦИЯ СЕРВЕРА: ЛОКАЛЬНЫЙ ИЛИ ПРОДАКШН
  // Измените эту переменную для переключения между серверами
  static const bool _useProductionServer = false; // true = продакшн, false = локальный
  
  static String get baseApiUrl {
    if (kDebugMode) {
      print('🔧 AppConfig: Определяем baseApiUrl');
      print('🔧 Platform.isIOS: ${!kIsWeb ? Platform.isIOS : "N/A"}');
      print('🔧 kIsWeb: $kIsWeb');
      print('🔧 Platform.isAndroid: ${!kIsWeb ? Platform.isAndroid : "N/A"}');
    }
    
    if (_useProductionServer) {
      if (kDebugMode) print('🟢 AppConfig: Продакшн сервер -> barlau.org');
      return 'https://barlau.org/api';
    } else {
      if (kDebugMode) print('🟢 AppConfig: Локальный сервер -> localhost:8000');
      return 'http://localhost:8000/api';
    }
  }
  
  // Базовый URL для медиа файлов
  static String get baseMediaUrl {
    if (_useProductionServer) {
      if (kDebugMode) print('🟢 AppConfig: Медиа -> barlau.org');
      return 'https://barlau.org';
    } else {
      if (kDebugMode) print('🟢 AppConfig: Медиа -> localhost:8000');
      return 'http://localhost:8000';
    }
  }

  // Проверка, является ли устройство реальным (не эмулятор)
  static bool get isRealDevice {
    if (kIsWeb) return true;
    return !Platform.environment.containsKey('FLUTTER_TEST');
  }
  
  // Информация о текущей конфигурации
  static String get configInfo {
    if (_useProductionServer) {
      return 'Продакшн режим: barlau.org';
    } else {
      return 'Локальный режим: localhost:8000';
    }
  }

  // Настройки приложения
  static const String appName = 'BARLAU.KZ';
  static const String companyName = 'ТОО "БАРЛАУ"';
  static const int apiTimeout = 30; // секунды
  
  // Информация о доступных пользователях
  static const Map<String, String> availableUsers = {
    'aidana.uzakova': 'aidana.uzakova@barlau.org',
    'muratjan.ilakhunov': 'muratjan.ilakhunov@barlau.org',
    'aset.ilyamov': 'aset.ilyamov@barlau.org',
    'gabit.akhmetov': 'gabit.akhmetov@barlau.org',
    'maksat.kusaiyn': 'maksat.kusaiyn@barlau.org',
    'nazerke.sadvakasova': 'nazerke.sadvakasova@barlau.org',
    'erbolat.kudaibergen': 'erbolat.kudaibergen@barlau.org',
    'almas.sopashev': 'almas.sopashev@barlau.org',
    'serik.aidarbe': 'serik.aidarbe@barlau.org',
  };
} 