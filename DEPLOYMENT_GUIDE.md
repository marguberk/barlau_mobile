# 📱 Руководство по публикации BARLAU.KZ Mobile App

Подробное руководство по сборке и публикации Flutter приложения BARLAU.KZ в магазинах приложений.

## 🔧 Быстрая сборка APK

### Debug APK (для тестирования)
```bash
# Автоматическая сборка
./build_apk.sh

# Или вручную
flutter build apk --debug
```

### Release APK (для публикации)
```bash
flutter build apk --release
```

## 📱 Google Play Store (Android)

### 1. Подготовка к публикации

#### Создание ключа подписи
```bash
# Создаем keystore
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Сохраняем пароли в безопасном месте!
```

#### Настройка подписи в проекте
Создайте файл `android/key.properties`:
```properties
storePassword=ваш_пароль_store
keyPassword=ваш_пароль_key
keyAlias=upload
storeFile=/Users/путь/к/upload-keystore.jks
```

#### Обновление `android/app/build.gradle`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 2. Настройка метаданных приложения

#### `android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:label="BARLAU.KZ"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher">
    
    <!-- Разрешения -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
</application>
```

#### `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "kz.barlau.mobile"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

### 3. Создание иконки приложения

#### Генерация иконок
```bash
# Установка flutter_launcher_icons
flutter pub add dev:flutter_launcher_icons

# Добавьте в pubspec.yaml:
flutter_icons:
  android: true
  ios: true
  image_path: "assets/images/logo.png"
  min_sdk_android: 21

# Генерация
flutter pub run flutter_launcher_icons:main
```

### 4. Сборка Release APK/AAB

```bash
# APK (для прямой установки)
flutter build apk --release

# AAB (для Google Play)
flutter build appbundle --release
```

### 5. Публикация в Google Play Console

1. **Создайте аккаунт разработчика** ($25 одноразово)
2. **Создайте новое приложение**
3. **Загрузите AAB файл**
4. **Заполните описание приложения**:
   - Название: BARLAU.KZ
   - Краткое описание: Система управления логистикой
   - Полное описание: [см. ниже]
   - Скриншоты: 2-8 скриншотов
   - Иконка: 512x512px
   - Графический баннер: 1024x500px

## 🍎 Apple App Store (iOS)

### 1. Подготовка к публикации

#### Настройка Bundle ID
В `ios/Runner.xcodeproj` установите:
```
Bundle Identifier: kz.barlau.mobile
```

#### Создание иконок
```bash
# Генерация iOS иконок
flutter pub run flutter_launcher_icons:main
```

### 2. Сборка iOS приложения

```bash
# Сборка для iOS
flutter build ios --release

# Открытие в Xcode для архивирования
open ios/Runner.xcworkspace
```

### 3. Публикация в App Store Connect

1. **Аккаунт Apple Developer** ($99/год)
2. **Создание App ID** в Developer Portal
3. **Архивирование в Xcode**
4. **Загрузка через Xcode или Transporter**
5. **Заполнение метаданных в App Store Connect**

## 📝 Описания для магазинов

### Краткое описание (80 символов)
```
Система управления логистикой и транспортом для компании BARLAU.KZ
```

### Полное описание

```
🚛 BARLAU.KZ - Профессиональная система управления логистикой

Мобильное приложение для сотрудников транспортно-логистической компании BARLAU.KZ. 
Полный контроль над задачами, транспортом и персоналом в одном приложении.

🔥 ОСНОВНЫЕ ВОЗМОЖНОСТИ:

✅ Управление задачами
• Просмотр и выполнение рабочих задач
• Отслеживание статуса выполнения
• Уведомления о новых заданиях

👥 Каталог сотрудников
• Полная база данных персонала
• Детальные профили с фото
• Контактная информация
• PDF резюме сотрудников

🚛 Управление транспортом
• Каталог грузового автопарка
• Фотографии и технические характеристики
• Статус и местоположение транспорта

🗺️ Интерактивная карта
• Отслеживание маршрутов
• Геолокация транспорта
• Планирование поездок

👤 Личный профиль
• Редактирование данных
• Загрузка фото профиля
• Статистика активности

🔔 Система уведомлений
• Важные оповещения
• Фильтрация по типам
• Отметка как прочитанные

🎨 СОВРЕМЕННЫЙ ДИЗАЙН:
• Интуитивный интерфейс
• Быстрая навигация
• Адаптивная верстка
• Темная тема

🔒 БЕЗОПАСНОСТЬ:
• Авторизация пользователей
• Защищенные API запросы
• Локальное шифрование данных

📱 ОФФЛАЙН РЕЖИМ:
• Работа без интернета
• Синхронизация при подключении
• Локальное сохранение данных

Приложение предназначено для внутреннего использования сотрудниками 
компании BARLAU.KZ и требует авторизации.

🏢 О компании BARLAU.KZ:
Ведущая транспортно-логистическая компания Казахстана с многолетним 
опытом грузовых перевозок и логистических решений.

📞 Поддержка: support@barlau.kz
🌐 Сайт: https://barlau.kz
```

### Ключевые слова (100 символов)
```
логистика, транспорт, грузоперевозки, BARLAU, управление, задачи, карта, GPS, персонал
```

## 🖼️ Требования к графическим материалам

### Android (Google Play)
- **Иконка**: 512x512px, PNG
- **Скриншоты**: 
  - Телефон: 1080x1920px (минимум 2, максимум 8)
  - Планшет: 1200x1920px (опционально)
- **Баннер**: 1024x500px, PNG/JPG

### iOS (App Store)
- **Иконка**: 1024x1024px, PNG (без альфа-канала)
- **Скриншоты**:
  - iPhone 6.7": 1290x2796px
  - iPhone 6.5": 1242x2688px
  - iPhone 5.5": 1242x2208px
  - iPad Pro 12.9": 2048x2732px

## 🚀 Автоматизация сборки

### GitHub Actions (CI/CD)
Создайте `.github/workflows/build.yml`:

```yaml
name: Build Flutter APK

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.27.4'
    
    - name: Install dependencies
      run: flutter pub get
      working-directory: ./barlau_flutter
    
    - name: Build APK
      run: flutter build apk --release
      working-directory: ./barlau_flutter
    
    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: barlau-release-apk
        path: barlau_flutter/build/app/outputs/flutter-apk/app-release.apk
```

## 📊 Аналитика и мониторинг

### Firebase Analytics
```bash
# Добавление Firebase
flutter pub add firebase_analytics
flutter pub add firebase_core
```

### Crashlytics
```bash
# Мониторинг ошибок
flutter pub add firebase_crashlytics
```

## 🔄 Обновления приложения

### Версионирование
В `pubspec.yaml`:
```yaml
version: 1.0.0+1
# 1.0.0 - версия для пользователей
# +1 - build number (увеличивать при каждой сборке)
```

### Автоматические обновления
- **Android**: Через Google Play (автоматически)
- **iOS**: Через App Store (требует одобрения)

## 🛡️ Безопасность

### Обфускация кода
```bash
# Сборка с обфускацией
flutter build apk --release --obfuscate --split-debug-info=./debug-info/
```

### Защита API ключей
- Используйте `--dart-define` для секретных данных
- Храните ключи в переменных окружения
- Не коммитьте `key.properties` в git

## 📈 Метрики и KPI

### Основные метрики:
- Количество загрузок
- Активные пользователи (DAU/MAU)
- Время сессии
- Retention rate
- Crash-free sessions

## 🎯 Чек-лист перед публикацией

### ✅ Технические требования:
- [ ] Сборка без ошибок
- [ ] Тестирование на реальных устройствах
- [ ] Проверка всех функций
- [ ] Тестирование оффлайн режима
- [ ] Проверка производительности

### ✅ Контент:
- [ ] Описание приложения
- [ ] Скриншоты актуальные
- [ ] Иконка высокого качества
- [ ] Политика конфиденциальности
- [ ] Условия использования

### ✅ Правовые аспекты:
- [ ] Соответствие политикам магазинов
- [ ] Права на использование контента
- [ ] Возрастной рейтинг
- [ ] Региональные ограничения

---

## 📞 Поддержка

При возникновении проблем с публикацией:
- 📧 Email: support@barlau.kz
- 📱 Telegram: @barlau_support
- 🌐 Документация: https://docs.barlau.kz

**Удачной публикации! 🚀** 
 
 
 
 
 