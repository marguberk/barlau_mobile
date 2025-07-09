#!/bin/bash

# Скрипт для сборки релизной версии BARLAU.KZ Flutter приложения
echo "🚀 Начинаем сборку релизной версии BARLAU.KZ..."

# Проверяем, что Flutter установлен
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter не найден. Установите Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Проверяем, что находимся в правильной директории
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Файл pubspec.yaml не найден. Запустите скрипт из корня Flutter проекта."
    exit 1
fi

# Очистка предыдущих сборок
echo "🧹 Очистка предыдущих сборок..."
flutter clean

# Получение зависимостей
echo "📦 Получение зависимостей..."
flutter pub get

# Проверка, что keystore файл существует
if [ ! -f "android/barlau-release-key.keystore" ]; then
    echo "⚠️  Keystore файл не найден!"
    echo "Создайте keystore файл командой:"
    echo "cd android && keytool -genkey -v -keystore barlau-release-key.keystore -alias barlau -keyalg RSA -keysize 2048 -validity 10000"
    echo "И обновите файл android/key.properties с правильными паролями"
    exit 1
fi

# Проверка настроек подписи
if grep -q "ЗАМЕНИТЕ_НА_ВАШ_ПАРОЛЬ" android/key.properties; then
    echo "⚠️  Обновите файл android/key.properties с правильными паролями!"
    exit 1
fi

# Сборка Android App Bundle (для Google Play)
echo "🤖 Сборка Android App Bundle..."
flutter build appbundle --release

if [ $? -eq 0 ]; then
    echo "✅ Android App Bundle собран успешно!"
    echo "📁 Файл: build/app/outputs/bundle/release/app-release.aab"
else
    echo "❌ Ошибка при сборке Android App Bundle"
    exit 1
fi

# Сборка APK (для тестирования)
echo "🤖 Сборка APK..."
flutter build apk --release

if [ $? -eq 0 ]; then
    echo "✅ APK собран успешно!"
    echo "📁 Файл: build/app/outputs/flutter-apk/app-release.apk"
else
    echo "❌ Ошибка при сборке APK"
    exit 1
fi

# Информация о файлах
echo ""
echo "📊 Информация о собранных файлах:"
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    AAB_SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)
    echo "   📦 App Bundle: $AAB_SIZE (для Google Play Store)"
fi

if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    echo "   📱 APK: $APK_SIZE (для тестирования)"
fi

echo ""
echo "🎉 Сборка завершена успешно!"
echo ""
echo "📋 Следующие шаги:"
echo "1. Загрузите app-release.aab в Google Play Console"
echo "2. Протестируйте app-release.apk на Android устройстве"
echo "3. Следуйте инструкциям в STORE_DEPLOYMENT_GUIDE.md" 