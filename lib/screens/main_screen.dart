import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import 'tasks_screen.dart';
import 'vehicles_screen.dart';
import 'trips_screen.dart';
import 'employees_screen.dart';
import 'expenses_screen.dart';
import '../components/svg_icon.dart';
import '../providers/notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String? userRole;
  bool canAccessExpenses = false;
  
  List<Widget> _screens = [];
  List<BottomNavigationBarItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    // Загружаем уведомления при входе в приложение
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
    });
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Получаем роль из сохраненного профиля пользователя
    final userProfileJson = prefs.getString('user_profile');
    if (userProfileJson != null) {
      try {
        final userMap = json.decode(userProfileJson);
        userRole = userMap['role'];
      } catch (e) {
        print('Error parsing user profile: $e');
        userRole = null;
      }
    } else {
      userRole = null;
    }
    
    canAccessExpenses = ['DRIVER', 'DISPATCHER', 'SUPPLIER', 'SUPERADMIN', 'ADMIN', 'DIRECTOR', 'ACCOUNTANT', 'admin'].contains(userRole);
    
    // Отладочная информация
    print('=== MainScreen Debug ===');
    print('User profile JSON found: ${userProfileJson != null}');
    print('User role: $userRole');
    print('Can access expenses: $canAccessExpenses');
    print('Allowed roles: DRIVER, DISPATCHER, SUPPLIER, SUPERADMIN, ADMIN, DIRECTOR, ACCOUNTANT');
    
    _buildScreensAndNavigation();
    setState(() {});
  }

  void _buildScreensAndNavigation() {
    // Определяем, какие страницы доступны для текущей роли
    final canAccessEmployees = ['SUPERADMIN', 'ADMIN', 'DIRECTOR', 'HR_MANAGER', 'ACCOUNTANT'].contains(userRole);
    final canAccessTrips = !['ACCOUNTANT'].contains(userRole);
    final canAccessVehicles = !['ACCOUNTANT'].contains(userRole);
    
    // Базовые экраны для всех ролей
    _screens = [
      ExpensesScreen(),
      const TasksScreen(),
    ];

    _navItems = [
      BottomNavigationBarItem(
        icon: SvgIcon(
          assetName: 'receipt.svg',
          width: 20,
          height: 20,
          color: const Color(0xFF9CA3AF),
        ),
        activeIcon: SvgIcon(
          assetName: 'receipt.svg',
          width: 20,
          height: 20,
          color: const Color(0xFF2679DB),
        ),
        label: 'Расходы',
      ),
      BottomNavigationBarItem(
        icon: SvgIcon(
          assetName: 'check-square.svg',
          width: 20,
          height: 20,
          color: const Color(0xFF9CA3AF),
        ),
        activeIcon: SvgIcon(
          assetName: 'check-square.svg',
          width: 20,
          height: 20,
          color: const Color(0xFF2679DB),
        ),
        label: 'Задачи',
      ),
    ];

    // Добавляем страницу заездов только для разрешенных ролей
    if (canAccessTrips) {
      _screens.add(const TripsScreen());
      _navItems.add(
        BottomNavigationBarItem(
          icon: SvgIcon(
            assetName: 'location.svg',
            width: 20,
            height: 20,
            color: const Color(0xFF9CA3AF),
          ),
          activeIcon: SvgIcon(
            assetName: 'location.svg',
            width: 20,
            height: 20,
            color: const Color(0xFF2679DB),
          ),
          label: 'Заезды',
        ),
      );
    }

    // Добавляем страницу грузовиков только для разрешенных ролей
    if (canAccessVehicles) {
      _screens.add(const VehiclesScreen());
      _navItems.add(
        BottomNavigationBarItem(
          icon: SvgIcon(
            assetName: 'truck.svg',
            width: 20,
            height: 20,
            color: const Color(0xFF9CA3AF),
          ),
          activeIcon: SvgIcon(
            assetName: 'truck.svg',
            width: 20,
            height: 20,
            color: const Color(0xFF2679DB),
          ),
          label: 'Грузовики',
        ),
      );
    }

    // Добавляем страницу сотрудников только для разрешенных ролей
    if (canAccessEmployees) {
      _screens.add(const EmployeesScreen());
      _navItems.add(
        BottomNavigationBarItem(
          icon: SvgIcon(
            assetName: 'employee.svg',
            width: 20,
            height: 20,
            color: const Color(0xFF9CA3AF),
          ),
          activeIcon: SvgIcon(
            assetName: 'employee.svg',
            width: 20,
            height: 20,
            color: const Color(0xFF2679DB),
          ),
          label: 'Сотрудники',
        ),
      );
    }

    print('Total screens: ${_screens.length}');
    print('Total nav items: ${_navItems.length}');
    print('Can access employees: $canAccessEmployees');
    print('Can access trips: $canAccessTrips');
    print('Can access vehicles: $canAccessVehicles');
  }

  @override
  Widget build(BuildContext context) {
    // Если экраны еще не загружены, показываем индикатор загрузки
    if (_screens.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2679DB)),
        ),
      );
    }

    // Для водителей показываем только страницу расходов без нижнего меню
    if (userRole == 'DRIVER') {
      return const Scaffold(
        body: ExpensesScreen(),
      );
    }

    // Для остальных ролей показываем полный интерфейс с нижним меню
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2679DB),
          unselectedItemColor: const Color(0xFF9CA3AF),
          selectedLabelStyle: const TextStyle(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
          items: _navItems,
        ),
      ),
    );
  }
} 
 
 
 
 