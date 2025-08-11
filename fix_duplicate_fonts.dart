import 'dart:io';

void main() async {
  print('🔄 Исправление дублирования fontFamily...');
  
  // Список файлов для проверки
  final files = [
    'lib/screens/employees_screen.dart',
    'lib/screens/vehicles_screen.dart',
    'lib/screens/tasks_screen.dart',
    'lib/screens/trip_details_screen.dart',
    'lib/components/app_header.dart',
    'lib/components/web_image.dart',
    'lib/screens/profile_screen.dart',
    'lib/screens/expenses_screen.dart',
  ];
  
  for (final file in files) {
    await fixDuplicateFontsInFile(file);
  }
  
  print('✅ Исправление дублирования завершено!');
}

Future<void> fixDuplicateFontsInFile(String filePath) async {
  try {
    final file = File(filePath);
    if (!await file.exists()) {
      print('⚠️  Файл не найден: $filePath');
      return;
    }
    
    String content = await file.readAsString();
    int fixedCount = 0;
    
    // Исправляем дублирование fontFamily
    final pattern = RegExp(r"fontFamily: 'SF Pro Display',\\s*fontFamily: 'SF Pro Display'");
    final matches = pattern.allMatches(content);
    
    for (final match in matches.toList().reversed) {
      final before = content.substring(0, match.start);
      final after = content.substring(match.end);
      content = before + 'fontFamily: \'SF Pro Display\',' + after;
      fixedCount++;
    }
    
    if (fixedCount > 0) {
      await file.writeAsString(content);
      print('✅ Исправлено $fixedCount дублирований в $filePath');
    } else {
      print('ℹ️  Нет дублирований в $filePath');
    }
    
  } catch (e) {
    print('❌ Ошибка исправления $filePath: $e');
  }
} 
 
 
 
 