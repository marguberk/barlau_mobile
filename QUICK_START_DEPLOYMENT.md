# ⚡ Быстрый старт публикации BARLAU.KZ

## 💰 Стоимость: $124 (Google Play $25 + Apple $99/год)

## 🚀 Пошаговый план на неделю

### День 1: Регистрация аккаунтов
1. **Google Play Console**: https://play.google.com/console ($25)
2. **Apple Developer**: https://developer.apple.com/programs/ ($99/год)

### День 2-3: Android версия
```bash
# 1. Создайте ключ подписи
cd barlau_flutter/android
keytool -genkey -v -keystore barlau-release-key.keystore -alias barlau -keyalg RSA -keysize 2048 -validity 10000

# 2. Обновите android/key.properties (замените пароли)
# 3. Соберите приложение
cd ..
./build_release.sh

# 4. Загрузите app-release.aab в Google Play Console
```

### День 4-5: iOS версия (ТОЛЬКО НА MAC!)
```bash
# 1. Установите Xcode из App Store
# 2. Откройте проект
open ios/Runner.xcworkspace

# 3. В Xcode настройте Bundle ID: kz.barlau.app
# 4. Product → Archive → Distribute App → App Store Connect
```

### День 6-7: Ожидание ревью
- Google Play: 1-3 дня
- Apple App Store: 1-7 дней

## 🔧 Что уже готово

✅ **Приложение настроено на продакшн API** (barlau.org)  
✅ **Android конфигурация обновлена**  
✅ **Скрипт автоматической сборки создан**  
✅ **Версия 1.0.0 установлена**  

## 📱 Что нужно сделать

### Для Android:
1. Создать ключ подписи (keystore)
2. Обновить пароли в `android/key.properties`
3. Запустить `./build_release.sh`
4. Загрузить `.aab` файл в Google Play

### Для iOS (нужен Mac):
1. Открыть в Xcode
2. Настроить Bundle ID и команду
3. Создать архив
4. Загрузить в App Store Connect

## 🆘 Помощь

**Если что-то не работает**:
1. Читайте подробное руководство: `STORE_DEPLOYMENT_GUIDE.md`
2. Проверьте, что Flutter установлен: `flutter doctor`
3. Для iOS обязательно нужен Mac

**Полезные команды**:
```bash
# Проверка Flutter
flutter doctor

# Тестовая сборка
flutter build apk --debug

# Проверка подключения к API
curl https://barlau.org/simple-trips/
```

## 🎯 Результат

После публикации ваши сотрудники смогут:
- Скачать приложение из Google Play / App Store
- Войти с учетными данными BARLAU.KZ
- Использовать все функции системы на мобильных устройствах
- Работать с той же базой данных, что и веб-версия

**Удачи! 🚀** 