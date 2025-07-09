#!/bin/bash

# Скрипт для копирования APK файла для тестирования
# Использование: ./copy_apk.sh

echo "🔄 Копирование APK файла для тестирования..."

# Проверяем наличие debug APK
if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    # Создаем папку для APK файлов если не существует
    mkdir -p "apk_for_testing"
    
    # Копируем APK с понятным именем
    cp "build/app/outputs/flutter-apk/app-debug.apk" "apk_for_testing/BARLAU-debug-$(date +%Y%m%d-%H%M).apk"
    
    echo "✅ APK файл скопирован в папку apk_for_testing/"
    echo "📱 Теперь вы можете перенести файл на Android телефон"
    echo ""
    echo "Размер файла:"
    ls -lh apk_for_testing/BARLAU-debug-*.apk | tail -1
    echo ""
    echo "📋 Инструкция по установке:"
    echo "1. Перенесите APK файл на Android телефон"
    echo "2. Включите 'Неизвестные источники' в настройках безопасности"
    echo "3. Нажмите на APK файл для установки"
    echo "4. Приложение появится как 'BARLAU' в списке приложений"
    
else
    echo "❌ APK файл не найден. Сначала выполните: flutter build apk --debug"
fi 