import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/app_header.dart';
import 'employee_detail_screen.dart';
import '../services/safe_api_service.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<Map<String, dynamic>> allEmployees = [];
  bool isLoading = true;
  bool isConnected = false;
  bool _isLoadingEmployees = false; // Защита от множественных загрузок

  @override
  void initState() {
    super.initState();
    // Очищаем список сотрудников при инициализации
    allEmployees = [];
    
    // Загружаем сотрудников только один раз при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadEmployees();
      }
    });
  }

  Future<void> _loadEmployees() async {
    if (!mounted) return;
    
    // Защита от множественных загрузок
    if (_isLoadingEmployees) {
      print('Загрузка сотрудников уже выполняется, пропускаем...');
      return;
    }
    
    _isLoadingEmployees = true;
    setState(() {
      isLoading = true;
    });

    try {
      // Получаем валидный токен с принудительным обновлением
    String? token = await SafeApiService.getValidToken();
    
    // Если токен не получен, пытаемся принудительно обновить
    if (token == null) {
      print('DEBUG: Токен не получен, пытаемся принудительно обновить...');
      token = await SafeApiService.forceRefreshToken();
    }
    
    print('DEBUG: Токен авторизации для сотрудников: ${token != null ? 'есть' : 'нет'}');

          // Используем только продакшн URL для избежания дубликатов
      final urls = [
        'https://barlau.org/api/employees/',
      ];

    for (String url in urls) {
      try {
        print('Пробуем URL: $url');
        
        final headers = {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        };
        
        // Добавляем токен авторизации, если он есть
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
        
        final response = await http.get(
          Uri.parse(url),
          headers: headers,
        ).timeout(const Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('DEBUG: Получен ответ от $url, статус: ${response.statusCode}');
          print('DEBUG: Структура данных: ${data.runtimeType}');
          if (data is Map) {
            print('DEBUG: Ключи в данных: ${data.keys.toList()}');
          }
          
          if (!mounted) return;
          
          List<Map<String, dynamic>> employees = [];
          if (data is Map && data.containsKey('results')) {
            employees = List<Map<String, dynamic>>.from(data['results']);
            print('DEBUG: Найдено ${employees.length} сотрудников в results');
          } else if (data is List) {
            employees = List<Map<String, dynamic>>.from(data);
            print('DEBUG: Найдено ${employees.length} сотрудников в списке');
          } else {
            print('DEBUG: Неизвестная структура данных');
          }
          
                      if (employees.isNotEmpty) {
              // Убираем дубликаты по ID и имени
              final Map<int, Map<String, dynamic>> uniqueEmployees = {};
              final Set<String> seenNames = <String>{};
              final Map<String, int> nameToId = <String, int>{};
              
              print('=== ДЕТАЛЬНАЯ ПРОВЕРКА СОТРУДНИКОВ ===');
              for (final employee in employees) {
                final id = employee['id'] as int?;
                final firstName = employee['first_name'] ?? '';
                final lastName = employee['last_name'] ?? '';
                final fullName = '$firstName $lastName'.trim();
                
                print('Проверяем: ID=$id, Имя="$fullName"');
                
                if (id != null) {
                  if (!uniqueEmployees.containsKey(id) && !seenNames.contains(fullName)) {
                    uniqueEmployees[id] = employee;
                    seenNames.add(fullName);
                    nameToId[fullName] = id;
                    print('  ✅ Добавлен: ID=$id, Имя="$fullName"');
                  } else if (uniqueEmployees.containsKey(id)) {
                    print('  ❌ ДУБЛИКАТ ID: ID=$id, Имя="$fullName"');
                  } else if (seenNames.contains(fullName)) {
                    final existingId = nameToId[fullName];
                    print('  ❌ ДУБЛИКАТ ИМЕНИ: ID=$id, Имя="$fullName" (уже есть ID=$existingId)');
                  }
                } else {
                  print('  ⚠️ Без ID: Имя="$fullName"');
                }
              }
              
              final deduplicatedEmployees = uniqueEmployees.values.toList();
              print('=== РЕЗУЛЬТАТ ДЕДУПЛИКАЦИИ ===');
              print('Было ${employees.length} сотрудников, стало ${deduplicatedEmployees.length} после дедупликации');
              print('Уникальные имена: ${seenNames.toList()}');
              print('================================');
            
            // Маппим поля Django API в формат Flutter
            final mappedEmployees = deduplicatedEmployees.map((employee) => _mapEmployeeFields(employee)).toList();
            
            if (mounted) {
              setState(() {
                allEmployees = mappedEmployees;
                isLoading = false;
                isConnected = true;
              });
              print('Загружено ${allEmployees.length} сотрудников из базы данных');
            }
            
            return;
          } else {
            print('DEBUG: Список сотрудников пуст');
          }
        } else {
          print('DEBUG: Неверный статус ответа: ${response.statusCode}');
        }
      } catch (e) {
        print('Ошибка для URL $url: $e');
      }
    }

          // Если не удалось загрузить с сервера, оставляем пустой список
      print('Не удалось загрузить сотрудников с сервера');
      if (!mounted) return;
      setState(() {
        allEmployees = [];
        isLoading = false;
        isConnected = false;
      });
    } catch (e) {
      print('Ошибка загрузки сотрудников: $e');
      if (!mounted) return;
      setState(() {
        allEmployees = [];
        isLoading = false;
        isConnected = false;
      });
    } finally {
      _isLoadingEmployees = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppHeader(
        title: 'Сотрудники',
        isConnected: isConnected,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2679DB),
              ),
            )
          : allEmployees.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Color(0xFF9CA3AF),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Сотрудники не найдены',
                        style: TextStyle(
    fontFamily: 'SF Pro Display',
                          fontSize: 18,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    key: ValueKey('employees_grid_${allEmployees.length}'),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      childAspectRatio: 2.1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: allEmployees.length,
                    itemBuilder: (context, index) {
                      final employee = allEmployees[index];
                      return _buildEmployeeCard(employee);
                    },
                  ),
                ),
    );
  }

  String? _getPhotoUrl(dynamic photoPath, int employeeId) {
    if (photoPath == null || photoPath.toString().isEmpty) {
      return null;
    }
    
    String photoStr = photoPath.toString();
    
    // Если уже полный URL, добавляем параметр для очистки кеша
    if (photoStr.startsWith('http')) {
      return '$photoStr?employee_id=$employeeId&t=${DateTime.now().millisecondsSinceEpoch}';
    }
    
    // Если это относительный путь, формируем полный URL с параметром кеша
    return 'https://barlau.org$photoStr?employee_id=$employeeId&t=${DateTime.now().millisecondsSinceEpoch}';
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final fullName = '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'.trim();
    final initials = _getInitials(employee['first_name'] ?? '', employee['last_name'] ?? '');
    final role = employee['role'] ?? '';
    final roleDisplay = _getRoleDisplay(role);
    final roleColor = _getRoleColor(role);

    final position = employee['position'] ?? '';
    final dateJoined = _formatDate(employee['date_joined']);
    final photoUrl = _getPhotoUrl(employee['photo'], employee['id']);
    // Убираем debug print для уменьшения перерисовок

    return Container(
      key: ValueKey('employee_card_${employee['id']}'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D0D12).withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок с аватаром и именем
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: [
                // Аватар
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: photoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            photoUrl,
                            key: ValueKey('employee_${employee['id']}_photo'),
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                            cacheWidth: 56, // 2x для retina
                            cacheHeight: 56,
                            headers: {
                              'Cache-Control': 'no-cache',
                              'Pragma': 'no-cache',
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print('Ошибка загрузки фото для сотрудника ${employee['id']}: $error');
                              return Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
    fontFamily: 'SF Pro Display',
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
    fontFamily: 'SF Pro Display',
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                // Имя
                Expanded(
                  child: Text(
                    fullName,
                    style: const TextStyle(
    fontFamily: 'SF Pro Display',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Информация о сотруднике
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Роль
                      Row(
                        children: [
                          const Icon(
                            Icons.description_outlined,
                            size: 16,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                roleDisplay,
                                style: TextStyle(
    fontFamily: 'SF Pro Display',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: roleColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Дата присоединения
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Работает с $dateJoined',
                              style: const TextStyle(
    fontFamily: 'SF Pro Display',
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Кнопка "Посмотреть резюме"
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                onPressed: () => _showEmployeeDetails(employee),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF374151),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Посмотреть резюме',
                        style: TextStyle(
    fontFamily: 'SF Pro Display',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmployeeDetails(Map<String, dynamic> employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeDetailScreen(employee: employee),
      ),
    );
  }

  String _getInitials(String firstName, String lastName) {
    String firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    String lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  String _getRoleDisplay(String role) {
    const roleMap = {
      'DIRECTOR': 'Директор',
      'DRIVER': 'Водитель', 
      'MANAGER': 'Менеджер',
      'ACCOUNTANT': 'Бухгалтер',
      'CONSULTANT': 'Консультант',
      'TECH': 'Техотдел',
      'SUPPLIER': 'Снабженец',
      'DISPATCHER': 'Диспетчер',
      'LOGIST': 'Логист',
      'IT_MANAGER': 'IT-менеджер',
      'ADMIN': 'Администратор',
      'SUPERADMIN': 'Суперадмин',
      'EMPLOYEE': 'Сотрудник',
    };
    return roleMap[role] ?? role;
  }

  Color _getRoleColor(String role) {
    const colorMap = {
      'DIRECTOR': Color(0xFFEF4444),
      'DRIVER': Color(0xFFF59E0B),
      'MANAGER': Color(0xFF3B82F6),
      'ACCOUNTANT': Color(0xFF6366F1),
      'CONSULTANT': Color(0xFF8B5CF6),
      'TECH': Color(0xFF10B981),
      'SUPPLIER': Color(0xFF06B6D4),
      'DISPATCHER': Color(0xFFF97316),
      'LOGIST': Color(0xFF84CC16),
      'IT_MANAGER': Color(0xFF6366F1),
      'ADMIN': Color(0xFF6B7280),
      'SUPERADMIN': Color(0xFF991B1B),
      'EMPLOYEE': Color(0xFF6B7280),
    };
    return colorMap[role] ?? const Color(0xFF6B7280);
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Не указано';
    try {
      DateTime dateTime = DateTime.parse(date.toString());
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
    } catch (e) {
      return 'Не указано';
    }
  }

  // Функция для маппинга полей Django API в формат Flutter
  Map<String, dynamic> _mapEmployeeFields(Map<String, dynamic> employee) {
    return {
      ...employee,
      // Маппим поля Django в поля Flutter
      'bio': employee['about_me'] ?? employee['bio'] ?? '',
      'education': employee['education'] ?? '',
      'achievements': employee['achievements'] ?? '',
      'experience': employee['experience'] ?? '',
      'position': employee['position'] ?? '',
      'phone': employee['phone'] ?? '',
      'photo': employee['photo'],
      'date_joined': employee['date_joined'],
      'is_active': employee['is_active'] ?? true,
    };
  }
} 