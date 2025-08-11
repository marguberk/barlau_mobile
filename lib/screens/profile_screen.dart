import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../components/app_header.dart';
import 'profile_edit_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppHeader(
        title: 'Профиль',
        isConnected: true,
        showNotificationIcon: false,
        showProfileIcon: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          
          if (user == null) {
            // Автоматически перенаправляем на страницу входа
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            });
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2679DB)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Перенаправление на страницу входа...',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Карточка профиля
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF585C5F).withOpacity(0.10),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                        spreadRadius: -12,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Аватар
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2679DB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: _buildProfileImage(user),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Имя пользователя
                      Text(
                        '${user.firstName} ${user.lastName}',
                        style: const TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      
                      // Роль
                      Text(
                        _getRoleDisplayName(user.role),
                        style: const TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      
                      // Статус активности
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: user.isActive 
                              ? const Color(0xFF10B981).withOpacity(0.1)
                              : const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: user.isActive 
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              user.isActive ? 'Активен' : 'Неактивен',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: user.isActive 
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Контактная информация
                if (user.email.isNotEmpty || user.phone.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF585C5F).withOpacity(0.10),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                          spreadRadius: -12,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Контактная информация',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Email
                        if (user.email.isNotEmpty)
                          _buildContactItem(
                            icon: Icons.email_outlined,
                            text: user.email,
                          ),
                        
                        // Телефон
                        if (user.phone.isNotEmpty) ...[
                          if (user.email.isNotEmpty) const SizedBox(height: 12),
                          _buildContactItem(
                            icon: Icons.phone_outlined,
                            text: user.phone,
                          ),
                        ],
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Статистика
                _buildStatCard(
                  title: 'Задачи',
                  icon: Icons.check_circle_outline,
                  iconColor: const Color(0xFF2679DB),
                  count: '4 активных',
                ),
                
                const SizedBox(height: 12),
                
                _buildStatCard(
                  title: 'Уведомления',
                  icon: Icons.notifications_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  count: '3 новых',
                ),
                
                if (user.role == 'DRIVER') ...[
                  const SizedBox(height: 12),
                  _buildStatCard(
                    title: 'Поездки',
                    icon: Icons.local_shipping_outlined,
                    iconColor: const Color(0xFF10B981),
                    count: '2 активных',
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Кнопка редактирования профиля
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileEditScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2679DB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Редактировать профиль',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Кнопка выхода
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showLogoutDialog(context, authProvider),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Выйти из системы',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Информация о приложении
                Text(
                  'BARLAU.KZ v1.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF666D80).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildContactItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String count,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF585C5F).withOpacity(0.10),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Row(
        children: [
          // Иконка
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Информация
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'DRIVER':
        return 'Водитель';
      case 'DIRECTOR':
        return 'Директор';
      case 'SUPERADMIN':
        return 'Суперадмин';
      case 'ACCOUNTANT':
        return 'Бухгалтер';
      case 'MANAGER':
        return 'Менеджер';
      case 'TECH':
        return 'Технический специалист';
      case 'DISPATCHER':
        return 'Диспетчер';
      default:
        return role;
    }
  }
  
  Widget _buildProfileImage(User user) {
    // Используем ту же логику, что и в карточках сотрудников
    final photoUrl = _getPhotoUrl(user.profilePicture, user.id);
    
    print('📸 Профиль: ${user.firstName} ${user.lastName}');
    print('📸 profilePicture: ${user.profilePicture}');
    print('📸 photoUrl: $photoUrl');
    
    if (photoUrl != null) {
      return Image.network(
        photoUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
        errorBuilder: (context, error, stackTrace) {
          print('Ошибка загрузки фото профиля: $error');
          return const Icon(
            Icons.person,
            size: 40,
            color: Color(0xFF2679DB),
          );
        },
      );
    }
    
    // Дефолтная иконка
    return const Icon(
      Icons.person,
      size: 40,
      color: Color(0xFF2679DB),
    );
  }

  String? _getPhotoUrl(dynamic photoPath, int userId) {
    if (photoPath == null || photoPath.toString().isEmpty) {
      return null;
    }
    
    String photoStr = photoPath.toString();
    
    // Если уже полный URL, добавляем параметр для очистки кеша
    if (photoStr.startsWith('http')) {
      return '$photoStr?user_id=$userId&t=${DateTime.now().millisecondsSinceEpoch}';
    }
    
    // Если это относительный путь, формируем полный URL с параметром кеша
    return 'https://barlau.org$photoStr?user_id=$userId&t=${DateTime.now().millisecondsSinceEpoch}';
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Выход из системы',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Вы уверены, что хотите выйти из системы?',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666D80),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Отмена',
                style: TextStyle(
                  color: Color(0xFF666D80),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authProvider.logout();
                // Выход из аккаунта автоматически переведет на страницу входа через AuthWrapper
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Выйти',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} 
 
 