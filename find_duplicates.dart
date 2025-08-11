import 'dart:io';

void main() async {
  print('🔍 Поиск дублирований fontFamily...');
  
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
    await findDuplicatesInFile(file);
  }
  
  print('✅ Поиск завершен!');
}

Future<void> findDuplicatesInFile(String filePath) async {
  try {
    final file = File(filePath);
    if (!await file.exists()) {
      print('⚠️  Файл не найден: $filePath');
      return;
    }
    
    String content = await file.readAsString();
    final lines = content.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('fontFamily:') && line.contains('fontFamily:')) {
        print('❌ Дублирование в $filePath на строке ${i + 1}:');
        print('   $line');
      }
    }
    
  } catch (e) {
    print('❌ Ошибка проверки $filePath: $e');
  }
} 
 
 
 
 