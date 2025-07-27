import '../config/app_config.dart';

class UrlHelper {
  /// Нормализует URL изображения для текущей платформы
  static String normalizeImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }
    
    // Если уже полный URL, возвращаем как есть
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // Исправляем localhost на продакшн URL для мобильных устройств
      if (AppConfig.isRealDevice && imageUrl.contains('localhost')) {
        final correctedUrl = imageUrl.replaceAll('localhost:8000', 'barlau.org').replaceAll('http://', 'https://');
        print('🔧 URL corrected for mobile: $imageUrl -> $correctedUrl');
        return correctedUrl;
      }
      return imageUrl;
    }
    
    // Если относительный путь, добавляем базовый URL
    String baseUrl = AppConfig.baseMediaUrl;
    String fullUrl = imageUrl.startsWith('/') 
        ? '$baseUrl$imageUrl' 
        : '$baseUrl/$imageUrl';
        
    print('🔧 Image URL normalized: $imageUrl -> $fullUrl');
    return fullUrl;
  }
  
  /// Нормализует API URL для текущей платформы
  static String normalizeApiUrl(String endpoint) {
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      // Если уже полный URL, исправляем localhost для мобильных
      if (AppConfig.isRealDevice && endpoint.contains('localhost')) {
        final correctedUrl = endpoint.replaceAll('localhost:8000', 'barlau.org').replaceAll('http://', 'https://');
        print('🔧 API URL corrected for mobile: $endpoint -> $correctedUrl');
        return correctedUrl;
      }
      return endpoint;
    }
    
    // Если относительный путь, добавляем базовый API URL
    String baseUrl = AppConfig.baseApiUrl;
    String fullUrl = endpoint.startsWith('/') 
        ? '$baseUrl$endpoint' 
        : '$baseUrl/$endpoint';
        
    print('🔧 API URL normalized: $endpoint -> $fullUrl');
    return fullUrl;
  }
  
  /// Создает массив URL для попытки подключения (fallback)
  static List<String> createFallbackUrls(String baseEndpoint) {
    List<String> urls = [];
    
    // Основной URL согласно конфигурации
    urls.add(normalizeApiUrl(baseEndpoint));
    
    // Если мы на мобильном устройстве, но базовый URL localhost, добавляем продакшн
    if (AppConfig.isRealDevice) {
      String prodUrl = 'https://barlau.org/api$baseEndpoint';
      if (!urls.contains(prodUrl)) {
        urls.add(prodUrl);
      }
    }
    
    // Если мы в режиме отладки на десктопе или Android эмулятор, добавляем localhost
    if (!AppConfig.isRealDevice) {
      String localUrl = '${AppConfig.baseApiUrl}$baseEndpoint';
      if (!urls.contains(localUrl)) {
        urls.add(localUrl);
      }
    }
    
    print('🔧 Fallback URLs for $baseEndpoint: $urls');
    return urls;
  }
  
  /// Проверяет, доступен ли URL
  static Future<bool> isUrlAccessible(String url) async {
    try {
      // Простая проверка доступности (можно расширить)
      return !url.contains('localhost') || !AppConfig.isRealDevice;
    } catch (e) {
      return false;
    }
  }
} 