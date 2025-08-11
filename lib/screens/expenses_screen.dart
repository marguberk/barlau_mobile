import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../components/app_header.dart';
import 'profile_screen.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/safe_api_service.dart';
import 'package:flutter/foundation.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String? userRole;
  bool canCreateExpenses = false;
  bool canViewAllExpenses = false;
  bool isLoading = false;
  String? errorMessage;
  
    // Сотрудники для фильтрации
  List<Map<String, dynamic>> employees = [];
  int? selectedEmployeeId;
  

  
  // Фильтры по датам
  DateTime? startDate;
  DateTime? endDate;
  
  // ID текущего пользователя (для фильтрации своих расходов)
  int? currentUserId;
  
  // Реальные данные с API
  List<Map<String, dynamic>> allExpenses = [];
  List<Map<String, dynamic>> filteredExpenses = [];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _loadUserInfo();
    await _loadExpenses();
    await _loadEmployees();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    userRole = prefs.getString('user_role') ?? 'DRIVER';
    currentUserId = prefs.getInt('user_id');
    
    print('ExpensesScreen: User role: $userRole');
    print('ExpensesScreen: Current user ID: $currentUserId');
    
    // Определяем права доступа
    final allowedRoles = ['DRIVER', 'DISPATCHER', 'SUPPLIER', 'SUPERADMIN', 'ADMIN', 'DIRECTOR', 'ACCOUNTANT', 'admin'];
    canCreateExpenses = allowedRoles.contains(userRole);
    canViewAllExpenses = ['SUPERADMIN', 'ADMIN', 'DIRECTOR', 'ACCOUNTANT', 'admin'].contains(userRole);
    
    print('ExpensesScreen: Can create expenses: $canCreateExpenses');
    print('ExpensesScreen: Can view all expenses: $canViewAllExpenses');
    
    // Создаем демо токен для тестирования
    if (kDebugMode) {
      print('ExpensesScreen: Создан демо токен для $userRole');
    }
  }

  Future<void> _loadExpenses() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      print('ExpensesScreen: Загружаем расходы с API...');
      
      // Получаем валидный токен с принудительным обновлением
      String? authToken = await SafeApiService.getValidToken();
      
      // Если токен не получен, пытаемся принудительно обновить
      if (authToken == null) {
        print('ExpensesScreen: Токен не получен, пытаемся принудительно обновить...');
        authToken = await SafeApiService.forceRefreshToken();
      }
      
      print('ExpensesScreen: Токен авторизации для загрузки: ${authToken != null ? 'есть' : 'нет'}');
      
      // Формируем заголовки
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      
      // Добавляем токен авторизации если есть
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      final response = await http.get(
        Uri.parse('${AppConfig.baseApiUrl}/expenses/'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      print('ExpensesScreen: Ответ сервера при загрузке: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> expenses = [];
        
          if (data is Map && data.containsKey('results')) {
          expenses = List<Map<String, dynamic>>.from(data['results']);
          } else if (data is List) {
          expenses = List<Map<String, dynamic>>.from(data);
          }
        
        // Отладочная информация о первом расходе
        if (expenses.isNotEmpty) {
          print('ExpensesScreen: Пример данных расхода: ${expenses.first}');
        }
        
        if (!mounted) return;
        setState(() {
          allExpenses = expenses;
          filteredExpenses = List.from(allExpenses);
          errorMessage = null;
        });
        
        print('ExpensesScreen: Загружено ${expenses.length} расходов из базы данных');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('ExpensesScreen: Ошибка загрузки расходов: $e');
      if (!mounted) return;
    
    setState(() {
        errorMessage = 'Ошибка загрузки с сервера. Показаны демо данные.';
        allExpenses = _getDemoExpenses();
        filteredExpenses = List.from(allExpenses);
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseApiUrl}/employees/'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> employeesList = [];
        
        if (data is Map && data.containsKey('results')) {
          employeesList = List<Map<String, dynamic>>.from(data['results']);
        } else if (data is List) {
          employeesList = List<Map<String, dynamic>>.from(data);
        }
        
        if (mounted) {
    setState(() {
            employees = employeesList;
          });
        }
      }
    } catch (e) {
      print('ExpensesScreen: Ошибка загрузки сотрудников: $e');
    }
  }



  // Демо данные для случая ошибки API
  List<Map<String, dynamic>> _getDemoExpenses() {
    return [
      {
        'id': 1,
        'title': 'Заправка на трассе',
        'amount': 15000,
        'date': '2024-12-07',
        'created_at': '2024-12-07T10:30:00Z',
        'created_by': {'id': 1, 'first_name': 'Асет', 'last_name': 'Ильямов'},
      },
      {
        'id': 2,
        'title': 'Обед в кафе',
        'amount': 3500,
        'date': '2024-12-07',
        'created_at': '2024-12-07T12:15:00Z',
        'created_by': {'id': 2, 'first_name': 'Габит', 'last_name': 'Ахметов'},
      },
      {
        'id': 3,
        'title': 'Парковка',
        'amount': 500,
        'date': '2024-12-07',
        'created_at': '2024-12-07T14:20:00Z',
        'created_by': {'id': 1, 'first_name': 'Асет', 'last_name': 'Ильямов'},
      },
      {
        'id': 4,
        'title': 'Мойка автомобиля',
        'amount': 2000,
        'date': '2024-12-06',
        'created_at': '2024-12-06T16:45:00Z',
        'created_by': {'id': 3, 'first_name': 'Айдана', 'last_name': 'Узакова'},
      },
      {
        'id': 5,
        'title': 'Покупка воды',
        'amount': 800,
        'date': '2024-12-06',
        'created_at': '2024-12-06T09:30:00Z',
        'created_by': {'id': 2, 'first_name': 'Габит', 'last_name': 'Ахметов'},
      },
    ];
  }

  void _showAddExpenseDialog() {
    if (!canCreateExpenses) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('У вас нет прав для создания расходов'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  const Expanded(
                    child: Text(
          'Добавить расход',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
                        fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                ),
              ),
                ],
            ),
            const SizedBox(height: 16),
              
              // Поле названия
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    hintText: 'Название расхода',
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Поле суммы
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  controller: amountController,
              keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    hintText: 'Сумма (₸)',
                    hintStyle: TextStyle(fontFamily: 'SF Pro Display', color: Color(0xFF9CA3AF), fontSize: 13),
                    suffixText: '₸',
                    suffixStyle: TextStyle(
                      fontFamily: 'SF Pro Display',
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
            ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Кнопки
              Row(
                children: [
                  Expanded(
                    child: TextButton(
            onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
            child: const Text(
              'Отмена',
                        style: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.w500, fontSize: 14),
                      ),
            ),
          ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
              final title = titleController.text.trim();
              final amountText = amountController.text.trim();
              
              if (title.isEmpty || amountText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                              content: Text('Заполните название и сумму'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              final amount = int.tryParse(amountText);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Введите корректную сумму'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
                        // Создаем новый расход с автоматической датой
                        final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
                        await _createExpense(title, amount, currentDate);
                        
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2679DB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Добавить',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
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

  Future<void> _createExpense(String title, int amount, String date) async {
    try {
      print('ExpensesScreen: Создаем расход: $title, $amount, $date');
      
      // Получаем валидный токен с принудительным обновлением
      String? authToken = await SafeApiService.getValidToken();
      
      // Если токен не получен, пытаемся принудительно обновить
      if (authToken == null) {
        print('ExpensesScreen: Токен не получен, пытаемся принудительно обновить...');
        authToken = await SafeApiService.forceRefreshToken();
      }
      
      print('ExpensesScreen: Токен авторизации: ${authToken != null ? 'есть' : 'нет'}');
      
      // Формируем заголовки
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      // Добавляем токен авторизации если есть
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      // Отправляем на сервер
      final response = await http.post(
        Uri.parse('${AppConfig.baseApiUrl}/expenses/'),
        headers: headers,
        body: json.encode({
          'amount': amount,
          'category': 'OTHER', // Добавляем обязательное поле
          'description': title, // Используем title как описание
          'date': date,
          'created_by': currentUserId ?? 22, // Добавляем ID пользователя
        }),
      );
      
      print('ExpensesScreen: Ответ сервера: ${response.statusCode}');
      print('ExpensesScreen: Тело ответа: ${response.body}');
      
      if (response.statusCode == 201) {
        final newExpense = json.decode(response.body);
        
        setState(() {
          allExpenses.insert(0, newExpense);
          filteredExpenses = List.from(allExpenses);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Расход добавлен'),
            backgroundColor: Color(0xFF2679DB),
          ),
        );
        
        print('ExpensesScreen: Расход успешно создан на сервере');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('ExpensesScreen: Ошибка создания расхода: $e');
      
      // В случае ошибки добавляем локально
              final newExpense = {
                'id': DateTime.now().millisecondsSinceEpoch,
                'title': title,
                'amount': amount,
        'date': date,
                'created_at': DateTime.now().toIso8601String(),
                'created_by': {
                  'id': currentUserId ?? 4,
                  'first_name': 'Текущий',
                  'last_name': 'Пользователь'
                },
              };
              
              setState(() {
        allExpenses.insert(0, newExpense);
        filteredExpenses = List.from(allExpenses);
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Расход добавлен локально (ошибка сервера: $e)'),
          backgroundColor: Colors.orange,
      ),
    );
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return '--:--';
    }
    try {
      final date = DateTime.parse(dateStr);
      // Конвертируем в UTC+5 (Алматы)
      final utc5Date = date.toUtc().add(const Duration(hours: 5));
      return DateFormat('HH:mm').format(utc5Date);
    } catch (e) {
      return '--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppHeader(
        title: 'Расходы',
        isConnected: errorMessage == null && allExpenses.isNotEmpty,
        showNotificationIcon: userRole != 'DRIVER',
        onNotificationTap: () {
          // Обработка нажатия на уведомления
        },
        onProfileTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        },
      ),
      body: Column(
        children: [
          // Статус подключения
          if (errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadExpenses,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          
          // Фильтры
          if (canViewAllExpenses) _buildFilters(),
          
          // Список расходов
          Expanded(child: _buildExpensesList()),
        ],
      ),
      floatingActionButton: canCreateExpenses ? Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2679DB).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(),
        backgroundColor: const Color(0xFF2679DB),
        foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, size: 28),
        ),
      ) : null,
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF585C5F).withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
        ),
        ],
      ),
              child: Row(
        children: [
            // Фильтры по датам
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildDateFilter(
                    label: 'С даты',
                    date: startDate,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF2679DB),
                              ),
                ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                  setState(() {
                          startDate = date;
                          _applyFilters();
                        });
                      }
                    },
                  ),
                    ),
                        const SizedBox(width: 8),
                        Expanded(
                  child: _buildDateFilter(
                    label: 'По дату',
                    date: endDate,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF2679DB),
                            ),
                          ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setState(() {
                          endDate = date;
                          _applyFilters();
                        });
                      }
                    },
                    ),
                  ),
              ],
                ),
              ),
              
          // Кнопка сброса
          if (startDate != null || endDate != null) ...[
              const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  startDate = null;
                  endDate = null;
                  selectedEmployeeId = null;
                  _applyFilters();
                });
              },
                  child: Container(
                padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(4),
                    ),
                child: const Icon(
                  Icons.refresh,
                  size: 14,
                  color: Color(0xFF6B7280),
                            ),
                          ),
                          ),
                      ],
        ],
      ),
    );
  }

  Widget _buildDateFilter({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 12,
              color: date != null ? const Color(0xFF2679DB) : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                date != null ? DateFormat('dd.MM.yyyy').format(date) : label,
                style: TextStyle(
                  fontSize: 12,
                  color: date != null ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ],
        ),
        ),
      );
    }

  void _applyFilters() {
    filteredExpenses = allExpenses;
    
    // Фильтр по сотруднику
    if (!canViewAllExpenses && currentUserId != null) {
      filteredExpenses = filteredExpenses.where((expense) {
        final createdBy = expense['created_by'];
        return createdBy != null && createdBy['id'] == currentUserId;
      }).toList();
    }
    
    if (canViewAllExpenses && selectedEmployeeId != null) {
      filteredExpenses = filteredExpenses.where((expense) {
        final createdBy = expense['created_by'];
        if (createdBy == null) return false;
        
        if (createdBy is Map<String, dynamic>) {
          return createdBy['id'] == selectedEmployeeId;
        } else if (createdBy is int) {
          return createdBy == selectedEmployeeId;
        }
        return false;
      }).toList();
    }
    
    // Фильтр по датам
    if (startDate != null || endDate != null) {
      filteredExpenses = filteredExpenses.where((expense) {
        final dateStr = expense['date'] ?? '';
        if (dateStr.isEmpty) return false;
        
        try {
          final expenseDate = DateTime.parse(dateStr);
          
          if (startDate != null && expenseDate.isBefore(startDate!)) {
            return false;
          }
          
          if (endDate != null && expenseDate.isAfter(endDate!.add(const Duration(days: 1)))) {
            return false;
          }
          
          return true;
        } catch (e) {
          return false;
        }
      }).toList();
    }
  }

  Widget _buildExpensesList() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2679DB)),
            ),
            SizedBox(height: 16),
            Text('Загружаем расходы...'),
          ],
        ),
      );
    }

    if (filteredExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 16),
            Text(
              !canViewAllExpenses 
                ? 'У вас пока нет расходов'
                : 'Расходы не найдены',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              !canViewAllExpenses
                ? 'Создайте свой первый расход'
                : 'Попробуйте изменить фильтры',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
              ),
            ),
            if (canCreateExpenses) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showAddExpenseDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Добавить расход'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2679DB),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Группируем расходы по датам
    Map<String, List<Map<String, dynamic>>> groupedExpenses = {};
    for (var expense in filteredExpenses) {
      String date = expense['date'] ?? '';
      if (!groupedExpenses.containsKey(date)) {
        groupedExpenses[date] = [];
      }
      groupedExpenses[date]!.add(expense);
    }

    // Сортируем даты
    List<String> sortedDates = groupedExpenses.keys.toList();
    sortedDates.sort((a, b) => b.compareTo(a)); // Новые даты первыми

    return RefreshIndicator(
      onRefresh: _loadExpenses,
      color: const Color(0xFF2679DB),
      child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        String date = sortedDates[index];
        List<Map<String, dynamic>> dayExpenses = groupedExpenses[date]!;
        
        // Считаем общую сумму за день
          double dayTotal = dayExpenses.fold(0.0, (sum, expense) {
            var amount = expense['amount'];
            if (amount is String) {
              amount = double.tryParse(amount) ?? 0.0;
            } else if (amount is int) {
              amount = amount.toDouble();
            } else if (amount is double) {
              // уже double
            } else {
              amount = 0.0;
            }
            return sum + amount;
          });
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Заголовок дня
            Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(date),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                      '${dayExpenses.length} расходов • ${NumberFormat('#,###').format(dayTotal)} ₸',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
              const SizedBox(height: 8),
            
            // Список расходов за день
            ...dayExpenses.map((expense) => _buildExpenseItem(expense)),
              const SizedBox(height: 16),
          ],
        );
      },
      ),
    );
  }

  Widget _buildExpenseItem(Map<String, dynamic> expense) {
    // Получаем название расхода (приоритет: description, затем title)
    String title = expense['description'] ?? expense['title'] ?? '';
    
    // Безопасное преобразование amount (может быть строкой с десятичными)
    var amountRaw = expense['amount'];
    int amount = 0;
    if (amountRaw is String) {
      // Убираем десятичные знаки и конвертируем в int
      String cleanAmount = amountRaw.split('.')[0];
      amount = int.tryParse(cleanAmount) ?? 0;
    } else if (amountRaw is int) {
      amount = amountRaw;
    } else if (amountRaw is double) {
      amount = amountRaw.toInt();
    }
    
    String createdAt = expense['created_at'] ?? '';
    
    // Безопасная обработка created_by_details (новое поле с данными пользователя)
    String employeeName = '';
    var createdByDetails = expense['created_by_details'];
    if (createdByDetails != null && createdByDetails is Map<String, dynamic>) {
      String firstName = createdByDetails['first_name'] ?? '';
      String lastName = createdByDetails['last_name'] ?? '';
      String username = createdByDetails['username'] ?? '';
      
      if (firstName.isNotEmpty && lastName.isNotEmpty) {
        // Сокращаем фамилию до первой буквы
        employeeName = '$firstName ${lastName[0]}.';
      } else if (firstName.isNotEmpty) {
        employeeName = firstName;
      } else if (lastName.isNotEmpty) {
        employeeName = lastName;
      } else if (username.isNotEmpty) {
        // Если нет имени/фамилии, используем username, но не показываем роль
        employeeName = username;
      }
    } else {
      // Fallback на старый формат created_by
      var createdBy = expense['created_by'];
    if (createdBy != null) {
        if (createdBy is Map<String, dynamic>) {
          String firstName = createdBy['first_name'] ?? '';
          String lastName = createdBy['last_name'] ?? '';
          if (firstName.isNotEmpty && lastName.isNotEmpty) {
            employeeName = '$firstName ${lastName[0]}.';
          } else if (firstName.isNotEmpty) {
            employeeName = firstName;
          } else if (lastName.isNotEmpty) {
            employeeName = lastName;
          }
        } else if (createdBy is int) {
          employeeName = _getEmployeeNameById(createdBy);
        } else if (createdBy is String) {
          employeeName = createdBy;
        }
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF585C5F).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Информация о расходе
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                            fontSize: 15,
                    ),
                  ),
                      ),
                    Text(
                        NumberFormat('#,###').format(amount) + ' ₸',
                      style: const TextStyle(
                          color: Color(0xFF2679DB),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                      ),
                    ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Время в левом нижнем углу
                      Text(
                        _formatTime(createdAt),
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                      ),
                      // Автор в правом нижнем углу
                      if (canViewAllExpenses && employeeName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            employeeName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Метод для получения имени сотрудника по ID
  String _getEmployeeNameById(int employeeId) {
    try {
      final employee = employees.firstWhere(
        (emp) => emp['id'] == employeeId,
        orElse: () => <String, dynamic>{},
      );
      
      if (employee.isNotEmpty) {
        String firstName = employee['first_name'] ?? '';
        String lastName = employee['last_name'] ?? '';
        String username = employee['username'] ?? '';
        
        if (firstName.isNotEmpty && lastName.isNotEmpty) {
          return '$firstName ${lastName[0]}.';
        } else if (firstName.isNotEmpty) {
          return firstName;
        } else if (lastName.isNotEmpty) {
          return lastName;
        } else if (username.isNotEmpty) {
          return username;
        }
      }
    } catch (e) {
      print('ExpensesScreen: Ошибка поиска сотрудника с ID $employeeId: $e');
    }
    
    return 'Сотрудник #$employeeId';
  }
} 
