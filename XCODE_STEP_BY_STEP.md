# 🔧 Пошаговая инструкция работы с Xcode для публикации BARLAU

## 🎯 ДЕТАЛЬНЫЕ ШАГИ В XCODE

### 1. ОТКРЫТИЕ ПРОЕКТА
```bash
# Убедитесь что находитесь в папке Flutter проекта
cd /Users/almaty/cursors/maro/barlau_flutter

# Откройте ИМЕННО workspace файл (не xcodeproj!)
open ios/Runner.xcworkspace
```

### 2. ПЕРВОНАЧАЛЬНАЯ НАСТРОЙКА В XCODE

#### Шаг 2.1: Выбор проекта
1. В левой панели Xcode нажмите на **Runner** (самый верхний элемент с синей иконкой)
2. Убедитесь что выбран таргет **Runner** (не RunnerTests)

#### Шаг 2.2: Настройка General
1. Перейдите на вкладку **General**
2. Заполните поля:
   - **Display Name**: `BARLAU`
   - **Bundle Identifier**: `kz.barlau.app`
   - **Version**: `1.0.0`
   - **Build**: `1`

#### Шаг 2.3: Deployment Info
1. В разделе **Deployment Info**:
   - **iOS Deployment Target**: `12.0`
   - **iPhone Orientation**: ✅ Portrait, ✅ Landscape Left, ✅ Landscape Right
   - **iPad Orientation**: ✅ Portrait, ✅ Landscape Left, ✅ Landscape Right

### 3. НАСТРОЙКА ПОДПИСИ КОДА (SIGNING)

#### Шаг 3.1: Signing & Capabilities
1. Перейдите на вкладку **Signing & Capabilities**
2. Убедитесь что выбран **Debug** конфигурация
3. Настройте подпись:
   - ✅ **Automatically manage signing**
   - **Team**: выберите вашу команду разработчика (должна появиться после регистрации Apple Developer)
   - **Bundle Identifier**: `kz.barlau.app`
   - **Provisioning Profile**: Xcode Managed Profile

#### Шаг 3.2: Release конфигурация
1. Переключитесь на **Release** (выпадающий список рядом с Debug)
2. Повторите те же настройки:
   - ✅ **Automatically manage signing**
   - **Team**: та же команда
   - **Bundle Identifier**: `kz.barlau.app`

#### Шаг 3.3: Проверка подписи
- Должны появиться **зеленые галочки** ✅
- Если видите красные ошибки ❌, проверьте:
  - Правильно ли выбрана команда разработчика
  - Уникален ли Bundle Identifier
  - Активен ли Apple Developer аккаунт

### 4. НАСТРОЙКА ИКОНКИ ПРИЛОЖЕНИЯ

#### Шаг 4.1: Открытие Assets
1. В левой панели найдите папку **Runner**
2. Откройте **Assets.xcassets**
3. Выберите **AppIcon**

#### Шаг 4.2: Добавление иконок
Вам нужны иконки следующих размеров:
- **20x20**: @1x, @2x, @3x
- **29x29**: @1x, @2x, @3x  
- **40x40**: @1x, @2x, @3x
- **60x60**: @2x, @3x
- **1024x1024**: @1x (для App Store)

**Как добавить**:
1. Перетащите файлы иконок в соответствующие ячейки
2. Или нажмите на ячейку и выберите файл через диалог

### 5. ТЕСТОВАЯ СБОРКА

#### Шаг 5.1: Выбор устройства
1. В верхней панели Xcode найдите выпадающий список устройств
2. Выберите **Any iOS Device (arm64)**
3. НЕ выбирайте симулятор для релизной сборки!

#### Шаг 5.2: Сборка проекта
1. Нажмите **Product** в меню
2. Выберите **Build** (или нажмите ⌘+B)
3. Дождитесь завершения сборки
4. Проверьте что нет ошибок (красных значков)

### 6. СОЗДАНИЕ АРХИВА ДЛЯ APP STORE

#### Шаг 6.1: Подготовка к архивированию
1. Убедитесь что выбрано **Any iOS Device (arm64)**
2. Проверьте схему сборки:
   - **Product** → **Scheme** → **Edit Scheme**
   - Выберите **Archive** в левой панели
   - **Build Configuration**: должно быть **Release**
   - Нажмите **Close**

#### Шаг 6.2: Создание архива
1. **Product** → **Archive** (или ⌘+Shift+B)
2. Процесс займет 5-15 минут
3. Не закрывайте Xcode во время архивирования!
4. После завершения откроется **Organizer**

### 7. ORGANIZER - РАБОТА С АРХИВАМИ

#### Шаг 7.1: Проверка архива
1. В **Organizer** выберите свежий архив
2. Проверьте информацию:
   - **Version**: 1.0.0
   - **Build**: 1
   - **Bundle ID**: kz.barlau.app
   - **Team**: ваша команда

#### Шаг 7.2: Валидация архива
1. Нажмите **Validate App**
2. Выберите **App Store Connect**
3. Следуйте мастеру:
   - **App Store Connect**: выберите ваш аккаунт
   - **Distribution Certificate**: Automatic
   - **Include bitcode**: ❌ НЕТ (снимите галочку)
   - **Upload symbols**: ✅ ДА
   - **Automatically manage signing**: ✅ ДА
4. Нажмите **Validate**
5. Дождитесь результата (2-5 минут)

#### Шаг 7.3: Загрузка в App Store Connect
1. После успешной валидации нажмите **Distribute App**
2. Выберите **App Store Connect**
3. Настройки:
   - **Upload**: ✅ ДА
   - **Include bitcode**: ❌ НЕТ
   - **Upload symbols**: ✅ ДА
   - **Manage Version and Build Number**: ✅ ДА
4. Нажмите **Upload**
5. Дождитесь загрузки (10-30 минут)

### 8. ВОЗМОЖНЫЕ ОШИБКИ И РЕШЕНИЯ

#### Ошибка: "No matching provisioning profiles"
**Решение**:
1. **Xcode** → **Preferences** → **Accounts**
2. Выберите ваш Apple ID
3. Нажмите **Download Manual Profiles**
4. Вернитесь в **Signing & Capabilities**
5. Переключите **Automatically manage signing** OFF и снова ON

#### Ошибка: "Bundle identifier is not available"
**Решение**:
1. Измените Bundle ID на уникальный: `kz.barlau.app.v2`
2. Или зайдите в Apple Developer Portal и зарегистрируйте App ID

#### Ошибка: "Build failed" с ошибками компиляции
**Решение**:
```bash
# Выйдите из Xcode
# Очистите Flutter проект
flutter clean
flutter pub get
cd ios && pod install && cd ..

# Откройте Xcode снова
open ios/Runner.xcworkspace

# В Xcode: Product → Clean Build Folder
# Затем: Product → Build
```

#### Ошибка: "Archive failed"
**Решение**:
1. Проверьте что выбрано **Any iOS Device**, НЕ симулятор
2. Убедитесь что **Build Configuration** = **Release**
3. Проверьте что все сертификаты валидны

### 9. ПРОВЕРКА УСПЕШНОЙ ЗАГРУЗКИ

#### Шаг 9.1: App Store Connect
1. Откройте https://appstoreconnect.apple.com
2. Войдите с вашим Apple ID
3. Перейдите в **My Apps**

#### Шаг 9.2: TestFlight
1. Выберите ваше приложение **BARLAU**
2. Перейдите на вкладку **TestFlight**
3. Раздел **iOS Builds**
4. Проверьте статус:
   - **Processing** - обрабатывается
   - **Ready to Submit** - готов к отправке
   - **Missing Compliance** - нужно заполнить информацию о шифровании

#### Шаг 9.3: Заполнение Export Compliance
1. Если статус **Missing Compliance**:
2. Нажмите на сборку
3. **Export Compliance Information**:
   - **Does your app use encryption?**: НЕТ
   - (Наше приложение использует только стандартное HTTPS шифрование)
4. Сохраните изменения

### 10. ФИНАЛЬНАЯ ПРОВЕРКА

#### Чеклист перед отправкой на ревью:
- [ ] ✅ Архив успешно создан
- [ ] ✅ Валидация прошла без ошибок
- [ ] ✅ Загрузка в App Store Connect завершена
- [ ] ✅ Статус в TestFlight: "Ready to Submit"
- [ ] ✅ Export Compliance заполнен
- [ ] ✅ Bundle ID: kz.barlau.app
- [ ] ✅ Version: 1.0.0
- [ ] ✅ Team: правильная команда разработчика

---

## 🎯 СЛЕДУЮЩИЙ ЭТАП

После успешной загрузки архива переходите к заполнению метаданных в App Store Connect:
1. Описание приложения
2. Скриншоты
3. Ценообразование
4. Информация для ревью
5. Отправка на модерацию

**Время выполнения всех шагов в Xcode**: 1-2 часа
**Время загрузки архива**: 10-30 минут
**Время обработки в App Store Connect**: 1-2 часа

**Удачи! ��📱**
