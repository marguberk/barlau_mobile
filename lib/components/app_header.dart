import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/profile_screen.dart';
import '../screens/notifications_screen.dart';
import '../providers/notification_provider.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showNotificationIcon;
  final bool showProfileIcon;
  final bool showBackButton;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final bool isConnected;
  final Widget? leading;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    required this.title,
    this.showNotificationIcon = true,
    this.showProfileIcon = true,
    this.showBackButton = false,
    this.onNotificationTap,
    this.onProfileTap,
    this.isConnected = true,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Кнопка назад
              if (showBackButton) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF6B7280),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              // Leading widget (например, кнопка назад)
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              
              // Заголовок
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              
              // Иконка уведомлений
              if (showNotificationIcon)
                Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, child) {
                    return InkWell(
                      onTap: () {
                        print('AppHeader: Нажатие на иконку уведомлений');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            const Center(
                              child: Icon(
                                Icons.notifications_outlined,
                                color: Color(0xFF6B7280),
                                size: 20,
                              ),
                            ),
                            // Бейдж с количеством непрочитанных
                            if (notificationProvider.unreadCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  constraints: const BoxConstraints(minWidth: 16),
                                  height: 16,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      notificationProvider.unreadCount > 99 
                                          ? '99+' 
                                          : notificationProvider.unreadCount.toString(),
                                      style: const TextStyle(
                                        fontFamily: 'SF Pro Display',
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              
              if (showNotificationIcon && showProfileIcon)
                const SizedBox(width: 8),
              
              // Иконка профиля
              if (showProfileIcon)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    onPressed: onProfileTap ?? () {
                      // Переход к профилю
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                    icon: const Icon(
                      Icons.person_outline,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              
              // Дополнительные действия
              if (actions != null) ...[
                const SizedBox(width: 8),
                ...actions!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}