import 'dart:io';

void main() async {
  print('🔄 Обновление шрифтов во всем приложении...');
  
  // Список файлов для обновления
  final files = [
    'lib/screens/employees_screen.dart',
    'lib/screens/vehicles_screen.dart',
    'lib/screens/tasks_screen.dart',
    'lib/screens/trip_details_screen.dart',
    'lib/components/app_header.dart',
    'lib/components/web_image.dart',
  ];
  
  for (final file in files) {
    await updateFontInFile(file);
  }
  
  print('✅ Обновление шрифтов завершено!');
}

Future<void> updateFontInFile(String filePath) async {
  try {
    final file = File(filePath);
    if (!await file.exists()) {
      print('⚠️  Файл не найден: $filePath');
      return;
    }
    
    String content = await file.readAsString();
    int updatedCount = 0;
    
    // Обновляем все TextStyle без fontFamily
    final pattern = RegExp(r'TextStyle\s*\(\s*(?!.*fontFamily)');
    final matches = pattern.allMatches(content);
    
    for (final match in matches.toList().reversed) {
      final start = match.start;
      final end = content.indexOf(')', start);
      
      if (end != -1) {
        final before = content.substring(0, start);
        final after = content.substring(end);
        final middle = content.substring(start, end);
        
        // Добавляем fontFamily в начало TextStyle
        final updatedMiddle = middle.replaceFirst('TextStyle(', 'TextStyle(\n    fontFamily: \'SF Pro Display\',');
        
        content = before + updatedMiddle + after;
        updatedCount++;
      }
    }
    
    // Обновляем const TextStyle
    final constPattern = RegExp(r'const\s+TextStyle\s*\(\s*(?!.*fontFamily)');
    final constMatches = constPattern.allMatches(content);
    
    for (final match in constMatches.toList().reversed) {
      final start = match.start;
      final end = content.indexOf(')', start);
      
      if (end != -1) {
        final before = content.substring(0, start);
        final after = content.substring(end);
        final middle = content.substring(start, end);
        
        // Добавляем fontFamily в начало const TextStyle
        final updatedMiddle = middle.replaceFirst('const TextStyle(', 'const TextStyle(\n    fontFamily: \'SF Pro Display\',');
        
        content = before + updatedMiddle + after;
        updatedCount++;
      }
    }
    
    if (updatedCount > 0) {
      await file.writeAsString(content);
      print('✅ Обновлено $updatedCount TextStyle в $filePath');
    } else {
      print('ℹ️  Нет изменений в $filePath');
    }
    
  } catch (e) {
    print('❌ Ошибка обновления $filePath: $e');
  }
} 
 
 
 
 