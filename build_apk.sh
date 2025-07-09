#!/bin/bash

# BARLAU.KZ Flutter APK Build Script
# Автоматическая сборка APK для Android

echo "🚀 Начинаем сборку BARLAU.KZ Flutter APK..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Проверяем Flutter
echo -e "${BLUE}📋 Проверяем Flutter окружение...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter не установлен!${NC}"
    exit 1
fi

# Очистка проекта
echo -e "${YELLOW}🧹 Очищаем проект...${NC}"
flutter clean

# Установка зависимостей
echo -e "${YELLOW}📦 Устанавливаем зависимости...${NC}"
flutter pub get

# Проверка Flutter Doctor
echo -e "${BLUE}🏥 Проверяем состояние Flutter...${NC}"
flutter doctor

# Сборка Debug APK
echo -e "${GREEN}🔨 Собираем Debug APK...${NC}"
flutter build apk --debug

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Debug APK успешно собран!${NC}"
    echo -e "${BLUE}📱 Файл: build/app/outputs/flutter-apk/app-debug.apk${NC}"
    
    # Показываем размер файла
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-debug.apk | cut -f1)
    echo -e "${BLUE}📊 Размер APK: ${APK_SIZE}${NC}"
else
    echo -e "${RED}❌ Ошибка при сборке Debug APK${NC}"
    exit 1
fi

# Сборка Release APK (если есть ключ)
echo -e "${GREEN}🔨 Пытаемся собрать Release APK...${NC}"
flutter build apk --release

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Release APK успешно собран!${NC}"
    echo -e "${BLUE}📱 Файл: build/app/outputs/flutter-apk/app-release.apk${NC}"
    
    # Показываем размер файла
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    echo -e "${BLUE}📊 Размер APK: ${APK_SIZE}${NC}"
else
    echo -e "${YELLOW}⚠️  Release APK не собран (нужен ключ подписи)${NC}"
    echo -e "${BLUE}💡 Используйте Debug APK для тестирования${NC}"
fi

echo -e "${GREEN}🎉 Сборка завершена!${NC}"
echo -e "${BLUE}📂 APK файлы находятся в: build/app/outputs/flutter-apk/${NC}"

# Копируем APK в корень для удобства
if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    cp build/app/outputs/flutter-apk/app-debug.apk ./barlau-debug.apk
    echo -e "${GREEN}📋 Debug APK скопирован как: barlau-debug.apk${NC}"
fi

if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    cp build/app/outputs/flutter-apk/app-release.apk ./barlau-release.apk
    echo -e "${GREEN}📋 Release APK скопирован как: barlau-release.apk${NC}"
fi

echo -e "${BLUE}🔗 Для установки на устройство:${NC}"
echo -e "${BLUE}   adb install barlau-debug.apk${NC}"
echo -e "${BLUE}   или перешлите файл на устройство${NC}" 