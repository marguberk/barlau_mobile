import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification.dart';
import '../components/app_header.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    print('NotificationsScreen: initState вызван');
    
    // Загружаем уведомления при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    print('NotificationsScreen: build вызван');
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(
        title: 'Уведомления',
        showBackButton: true,
        showNotificationIcon: false,
        showProfileIcon: false,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2679DB)),
                  ),
                  SizedBox(height: 16),
                  Text('Загружаем уведомления...'),
                ],
              ),
            );
          }

          if (notificationProvider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                      color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                      'Ошибка загрузки',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                    notificationProvider.error!,
                    textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                    const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => notificationProvider.loadNotifications(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2679DB),
                        foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Повторить'),
                    ),
                  ],
                  ),
              ),
            );
          }

          final notifications = notificationProvider.notifications;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Нет уведомлений',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'У вас пока нет уведомлений',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => notificationProvider.loadNotifications(),
            color: const Color(0xFF2679DB),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification, notificationProvider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, NotificationProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D0D12).withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          _showNotificationDetails(notification);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Содержимое уведомления
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок уведомления
                    Text(
                            notification.title,
                            style: TextStyle(
                        fontSize: 15,
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                        ),
                    const SizedBox(height: 6),
                    
                    // Текст сообщения
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Время и индикатор
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Время
                  Text(
                    notification.timeAgo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Индикатор непрочитанного
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2679DB),
                        shape: BoxShape.circle,
                      ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          notification.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF6B7280),
            ),
          ),
            const SizedBox(height: 12),
            Text(
              notification.timeAgo,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
            ),
          ),
        ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Закрыть',
              style: TextStyle(
                color: Color(0xFF2679DB),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
 
 
 
 
 