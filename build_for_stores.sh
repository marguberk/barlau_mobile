#!/bin/bash

# Скрипт для сборки релизных версий для App Store и Google Play Store
# Использование: ./build_for_stores.sh

echo "🚀 Сборка BARLAU для публикации в магазинах приложений"
echo "================================================="

# Проверяем что мы в правильной директории
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Ошибка: Запустите скрипт из корня Flutter проекта"
    exit 1
fi

# Проверяем наличие production keystore
if [ ! -f "android/app/barlau-production.keystore" ]; then
    echo "❌ Ошибка: Production keystore не найден"
    echo "Создайте keystore командой:"
    echo "keytool -genkey -v -keystore android/app/barlau-production.keystore ..."
    exit 1
fi

# Очищаем проект
echo "🧹 Очистка проекта..."
flutter clean

# Устанавливаем зависимости
echo "📦 Установка зависимостей..."
flutter pub get

# Генерируем иконки
echo "🎨 Генерация иконок..."
flutter pub run flutter_launcher_icons:main

echo ""
echo "🤖 ANDROID СБОРКА"
echo "=================="

# Собираем Android App Bundle для Google Play Store
echo "📱 Сборка Android App Bundle (AAB) для Google Play Store..."
flutter build appbundle --release

if [ $? -eq 0 ]; then
    echo "✅ Android App Bundle собран успешно!"
    echo "📍 Файл: build/app/outputs/bundle/release/app-release.aab"
else
    echo "❌ Ошибка сборки Android App Bundle"
    exit 1
fi

# Собираем APK для тестирования
echo "📱 Сборка APK для тестирования..."
flutter build apk --release

if [ $? -eq 0 ]; then
    echo "✅ Release APK собран успешно!"
    echo "📍 Файл: build/app/outputs/flutter-apk/app-release.apk"
else
    echo "❌ Ошибка сборки Release APK"
fi

echo ""
echo "🍎 iOS СБОРКА"
echo "============="

# Собираем iOS для App Store
echo "📱 Сборка iOS для App Store..."
flutter build ios --release

if [ $? -eq 0 ]; then
    echo "✅ iOS сборка завершена успешно!"
    echo "📍 Откройте ios/Runner.xcworkspace в Xcode для архивирования"
else
    echo "❌ Ошибка сборки iOS"
fi

echo ""
echo "📊 ИТОГОВЫЙ ОТЧЕТ"
echo "================="

# Проверяем размеры файлов
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    AAB_SIZE=$(ls -lh build/app/outputs/bundle/release/app-release.aab | awk '{print $5}')
    echo "✅ Android App Bundle: $AAB_SIZE"
fi

if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    APK_SIZE=$(ls -lh build/app/outputs/flutter-apk/app-release.apk | awk '{print $5}')
    echo "✅ Android APK: $APK_SIZE"
fi

echo ""
echo "🎯 СЛЕДУЮЩИЕ ШАГИ:"
echo "==================="
echo ""
echo "📱 GOOGLE PLAY STORE:"
echo "1. Зайдите в Google Play Console: https://play.google.com/console"
echo "2. Создайте новое приложение 'BARLAU'"
echo "3. Загрузите AAB файл: build/app/outputs/bundle/release/app-release.aab"
echo "4. Заполните описание, скриншоты, иконки"
echo "5. Отправьте на ревью"
echo ""
echo "🍎 APPLE APP STORE:"
echo "1. Откройте Xcode: ios/Runner.xcworkspace"
echo "2. Product → Archive"
echo "3. Distribute App → App Store Connect"
echo "4. Зайдите в App Store Connect: https://appstoreconnect.apple.com"
echo "5. Создайте новое приложение 'BARLAU'"
echo "6. Заполните метаданные и отправьте на ревью"
echo ""
echo "💰 СТОИМОСТЬ:"
echo "- Google Play: $25 (одноразово)"
echo "- Apple App Store: $99/год"
echo ""
echo "🎉 Приложение готово к публикации!" 