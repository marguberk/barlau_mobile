# AppHeader Component

Единообразный компонент верхнего меню для всех экранов приложения BARLAU.KZ.

## Особенности

- ✅ Единый дизайн во всем приложении
- ✅ Индикатор подключения к серверу
- ✅ Кнопки уведомлений и профиля
- ✅ Настраиваемый заголовок
- ✅ Возможность скрыть иконки при необходимости

## Использование

```dart
AppHeader(
  title: 'Название экрана',
  isConnected: true, // или false для красного индикатора
  onNotificationTap: () {
    // Обработка нажатия на уведомления
  },
  onProfileTap: () {
    // Переход к профилю
  },
)
```

## Параметры

| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `title` | `String` | ✅ | Заголовок экрана |
| `isConnected` | `bool` | ❌ | Статус подключения (по умолчанию: `true`) |
| `showNotificationIcon` | `bool` | ❌ | Показать иконку уведомлений (по умолчанию: `true`) |
| `showProfileIcon` | `bool` | ❌ | Показать иконку профиля (по умолчанию: `true`) |
| `onNotificationTap` | `VoidCallback?` | ❌ | Обработчик нажатия на уведомления |
| `onProfileTap` | `VoidCallback?` | ❌ | Обработчик нажатия на профиль |

## Индикатор подключения

- 🟢 **Зеленый** - подключение к серверу активно
- 🔴 **Красный** - нет подключения к серверу

## Примеры использования

### Стандартный экран
```dart
AppHeader(
  title: 'Задачи',
  isConnected: errorMessage == null && allTasks.isNotEmpty,
)
```

### Экран профиля (без иконок)
```dart
AppHeader(
  title: 'Профиль',
  isConnected: true,
  showNotificationIcon: false,
  showProfileIcon: false,
)
```

### С кастомными обработчиками
```dart
AppHeader(
  title: 'Карта',
  isConnected: true,
  onNotificationTap: () => _showNotifications(),
  onProfileTap: () => Navigator.pushNamed(context, '/profile'),
)
``` 