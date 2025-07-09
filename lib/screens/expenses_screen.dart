import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../components/app_header.dart';
import 'profile_screen.dart';

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
  
  // Статический список для демо данных
  static List<Map<String, dynamic>> _demoExpenses = [
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
    {
      'id': 6,
      'title': 'Ремонт шины',
      'amount': 12000,
      'date': '2024-12-05',
      'created_at': '2024-12-05T11:20:00Z',
      'created_by': {'id': 1, 'first_name': 'Асет', 'last_name': 'Ильямов'},
    },
    {
      'id': 7,
      'title': 'Штраф за превышение',
      'amount': 5000,
      'date': '2024-12-04',
      'created_at': '2024-12-04T15:30:00Z',
      'created_by': {'id': 4, 'first_name': 'Текущий', 'last_name': 'Пользователь'},
    },
    {
      'id': 8,
      'title': 'Ночевка в гостинице',
      'amount': 8000,
      'date': '2024-12-03',
      'created_at': '2024-12-03T22:00:00Z',
      'created_by': {'id': 4, 'first_name': 'Текущий', 'last_name': 'Пользователь'},
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadEmployees();
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userRole = prefs.getString('user_role');
    
    // Получаем ID пользователя из профиля
    final userProfileJson = prefs.getString('user_profile');
    if (userProfileJson != null) {
      try {
        final userMap = json.decode(userProfileJson);
        currentUserId = userMap['id'];
        userRole = userMap['role']; // Обновляем роль из профиля
      } catch (e) {
        print('Error parsing user profile: $e');
        currentUserId = 4; // Fallback ID для демо
      }
    } else {
      currentUserId = 4; // Fallback ID для демо
    }
    
    print('ExpensesScreen: User role: $userRole');
    print('ExpensesScreen: Current user ID: $currentUserId');
    
    // Проверяем права доступа
    final allowedRoles = ['DRIVER', 'DISPATCHER', 'SUPPLIER', 'SUPERADMIN', 'ADMIN', 'DIRECTOR', 'ACCOUNTANT', 'admin'];
    canCreateExpenses = allowedRoles.contains(userRole);
    
    // Только бухгалтеры, директора и админы видят все расходы
    canViewAllExpenses = ['SUPERADMIN', 'ADMIN', 'DIRECTOR', 'ACCOUNTANT', 'admin'].contains(userRole);
    
    print('ExpensesScreen: Can create expenses: $canCreateExpenses');
    print('ExpensesScreen: Can view all expenses: $canViewAllExpenses');
    
    // Создаем демо токен для тестирования
    if (userRole != null) {
      prefs.setString('auth_token', 'demo_token_${userRole}_${DateTime.now().millisecondsSinceEpoch}');
      print('ExpensesScreen: Создан демо токен для $userRole');
    }
    
    setState(() {});
  }

  Future<void> _loadEmployees() async {
    try {
      final urls = [
        'https://barlau.org/api/employees/',
        'http://localhost:8000/api/employees/',
      ];
      
      for (final url in urls) {
        try {
          final response = await http.get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ).timeout(const Duration(seconds: 2));
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (!mounted) return;
            setState(() {
              if (data is Map && data.containsKey('results')) {
                employees = List<Map<String, dynamic>>.from(data['results']);
              } else if (data is List) {
                employees = List<Map<String, dynamic>>.from(data);
              }
            });
            print('Загружено ${employees.length} сотрудников');
            return;
          }
        } catch (e) {
          print('Ошибка для URL $url: $e');
          continue;
        }
      }
      
      // Если не удалось загрузить, используем демо данные
      setState(() {
        employees = [
          {'id': 1, 'first_name': 'Асет', 'last_name': 'Ильямов'},
          {'id': 2, 'first_name': 'Габит', 'last_name': 'Ахметов'},
          {'id': 3, 'first_name': 'Айдана', 'last_name': 'Узакова'},
        ];
      });
      print('Используются демо данные сотрудников');
    } catch (e) {
      print('Ошибка загрузки сотрудников: $e');
    }
  }

  void _showError(String message) {
    setState(() {
      isLoading = false;
      errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showAddExpenseDialog() {
    if (!canCreateExpenses) {
      _showError('У вас нет прав для создания расходов');
      return;
    }

    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Добавить расход',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Название',
                hintText: 'Введите название расхода',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2679DB)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Сумма (₸)',
                hintText: 'Введите сумму',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2679DB)),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final amountText = amountController.text.trim();
              
              if (title.isEmpty || amountText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Заполните все поля'),
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
              
              // Добавляем новый расход в начало списка
              final newExpense = {
                'id': DateTime.now().millisecondsSinceEpoch,
                'title': title,
                'amount': amount,
                'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                'created_at': DateTime.now().toIso8601String(),
                'created_by': {
                  'id': currentUserId ?? 4,
                  'first_name': 'Текущий',
                  'last_name': 'Пользователь'
                },
              };
              
              setState(() {
                _demoExpenses.insert(0, newExpense);
              });
              
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Расход добавлен'),
                  backgroundColor: Color(0xFF2679DB),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2679DB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppHeader(
        title: 'Расходы',
        isConnected: true,
        showNotificationIcon: userRole != 'DRIVER', // Скрываем уведомления для водителей
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
          // Фильтры
          if (canViewAllExpenses) _buildFilters(),
          
          // Список расходов
          Expanded(child: _buildExpensesList()),
        ],
      ),
      floatingActionButton: canCreateExpenses ? FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(),
        backgroundColor: const Color(0xFF2679DB),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Первая строка: Только сотрудник
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: selectedEmployeeId,
                hint: const Text(
                  'Все сотрудники',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                isExpanded: true,
                onChanged: (int? value) {
                  setState(() {
                    selectedEmployeeId = value;
                  });
                },
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Все сотрудники'),
                  ),
                  ...employees.map((employee) => DropdownMenuItem<int?>(
                    value: employee['id'],
                    child: Text('${employee['first_name']} ${employee['last_name']}'),
                  )),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Вторая строка: Даты
          Row(
            children: [
              // Дата начала
              Expanded(
                child: InkWell(
                  onTap: () => _selectStartDate(),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6B7280)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            startDate != null 
                                ? DateFormat('dd.MM.yyyy').format(startDate!)
                                : 'С даты',
                            style: TextStyle(
                              fontSize: 14,
                              color: startDate != null ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        if (startDate != null)
                          InkWell(
                            onTap: () => setState(() => startDate = null),
                            child: const Icon(Icons.clear, size: 16, color: Color(0xFF6B7280)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Дата окончания
              Expanded(
                child: InkWell(
                  onTap: () => _selectEndDate(),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6B7280)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            endDate != null 
                                ? DateFormat('dd.MM.yyyy').format(endDate!)
                                : 'По дату',
                            style: TextStyle(
                              fontSize: 14,
                              color: endDate != null ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        if (endDate != null)
                          InkWell(
                            onTap: () => setState(() => endDate = null),
                            child: const Icon(Icons.clear, size: 16, color: Color(0xFF6B7280)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              

            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ru'),
    );
    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ru'),
    );
    if (picked != null && picked != endDate) {
      setState(() {
        endDate = picked;
      });
    }
  }

  Widget _buildExpensesList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2679DB),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  errorMessage = null;
                });
              },
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
      );
    }

    // Применяем фильтры
    List<Map<String, dynamic>> filteredExpenses = _demoExpenses;
    
    // Для обычных пользователей показываем только их расходы
    if (!canViewAllExpenses && currentUserId != null) {
      filteredExpenses = filteredExpenses.where((expense) {
        final createdBy = expense['created_by'];
        return createdBy != null && createdBy['id'] == currentUserId;
      }).toList();
    }
    
    // Для администраторов применяем фильтр по сотрудникам
    if (canViewAllExpenses && selectedEmployeeId != null) {
      filteredExpenses = filteredExpenses.where((expense) {
        final createdBy = expense['created_by'];
        return createdBy != null && createdBy['id'] == selectedEmployeeId;
      }).toList();
    }
    
    // Применяем фильтры по датам
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

    if (filteredExpenses.isEmpty) {
      String emptyMessage = 'Нет расходов';
      if (!canViewAllExpenses) {
        emptyMessage = 'У вас пока нет расходов';
      } else if (selectedEmployeeId != null) {
        emptyMessage = 'Нет расходов для выбранного сотрудника';
      } else if (startDate != null || endDate != null) {
        emptyMessage = 'Нет расходов в выбранном периоде';
      }
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Добавьте первый расход',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            if (canCreateExpenses) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showAddExpenseDialog(),
                icon: const Icon(Icons.add, size: 20, color: Colors.white),
                label: const Text('Добавить расход', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2679DB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

    // Сортируем даты по убыванию
    List<String> sortedDates = groupedExpenses.keys.toList();
    sortedDates.sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        String date = sortedDates[index];
        List<Map<String, dynamic>> dayExpenses = groupedExpenses[date]!;
        
        // Считаем общую сумму за день
        double dayTotal = dayExpenses.fold(0.0, (sum, expense) => sum + (expense['amount'] ?? 0));
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок дня с общей суммой
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(date),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    '${NumberFormat('#,###').format(dayTotal)} ₸',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2679DB),
                    ),
                  ),
                ],
              ),
            ),
            
            // Список расходов за день
            ...dayExpenses.map((expense) => _buildExpenseItem(expense)),
            
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildExpenseItem(Map<String, dynamic> expense) {
    String title = expense['title'] ?? '';
    int amount = expense['amount'] ?? 0;
    String createdAt = expense['created_at'] ?? '';
    Map<String, dynamic>? createdBy = expense['created_by'];
    
    // Форматируем дату и время
    String formattedDateTime = '';
    if (createdAt.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(createdAt);
        formattedDateTime = DateFormat('dd.MM.yyyy в HH:mm').format(dateTime);
      } catch (e) {
        formattedDateTime = createdAt;
      }
    }
    
    // Имя сотрудника
    String employeeName = '';
    if (createdBy != null) {
      employeeName = '${createdBy['first_name'] ?? ''} ${createdBy['last_name'] ?? ''}'.trim();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF585C5F).withOpacity(0.10),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Иконка расхода
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2679DB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_outlined,
                color: Color(0xFF2679DB),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Информация о расходе
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Название
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Дата и время
                  if (formattedDateTime.isNotEmpty)
                    Text(
                      formattedDateTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  // Сотрудник (только если можем видеть всех и есть данные)
                  if (canViewAllExpenses && employeeName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 12,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          employeeName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Сумма
            Text(
              '${NumberFormat('#,###').format(amount)} ₸',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2679DB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'FUEL':
        return Icons.local_gas_station;
      case 'MAINTENANCE':
        return Icons.build;
      case 'REPAIR':
        return Icons.car_repair;
      case 'FOOD':
        return Icons.restaurant;
      case 'ACCOMMODATION':
        return Icons.hotel;
      case 'TOLL':
        return Icons.toll;
      case 'PARKING':
        return Icons.local_parking;
      default:
        return Icons.receipt;
    }
  }
} 