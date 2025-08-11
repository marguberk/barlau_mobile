import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  // Переключаем на продакшн сервер
  static const bool _useProductionServer = true;
  
  static String get baseApiUrl {
    if (_useProductionServer) {
      return 'https://barlau.org/api';
    } else {
      return 'http://localhost:8000/api';
    }
  }
  
  static String get baseUrl {
    if (_useProductionServer) {
      return 'https://barlau.org';
    } else {
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