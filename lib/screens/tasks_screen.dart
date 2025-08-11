import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/app_header.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Map<String, dynamic>> allTasks = [];
  List<Map<String, dynamic>> filteredTasks = [];
  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> vehicles = [];
  bool isLoading = false;
  String? errorMessage;
  
  // Счетчики по статусам
  int todoCount = 0;
  int progressCount = 0;
  int doneCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadTasks(),
      _loadEmployees(),
      _loadVehicles(),
    ]);
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      // Получаем информацию о текущем пользователе
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;
      final userRole = currentUser?.role ?? '';
      final userId = currentUser?.id ?? 0;
      
      print('Загружаем задачи для пользователя: ${currentUser?.username} (ID: $userId, Роль: $userRole)');
      
      // Определяем, нужно ли фильтровать задачи по пользователю
      final shouldFilterByUser = !['SUPERADMIN', 'ADMIN', 'DIRECTOR'].contains(userRole);
      
      // Получаем токен авторизации
      final apiService = ApiService();
      final token = await apiService.getToken();
      
      // Пробуем разные endpoints - правильный путь для задач
      final urls = [
        '${AppConfig.baseApiUrl}/tasks/',
      ];
      
      http.Response? response;
      for (final url in urls) {
        try {
          print('Пробуем URL: $url');
          
          final headers = {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          };
          
          // Добавляем токен авторизации, если он есть
          if (token != null && token.isNotEmpty) {
            headers['Authorization'] = 'Bearer $token';
            print('Добавлен токен авторизации для запроса задач');
          }
          
          response = await http.get(
            Uri.parse(url),
            headers: headers,
          ).timeout(const Duration(seconds: 3));
          
          if (response.statusCode == 200) {
            print('Успешное подключение к: $url');
            print('Ответ сервера: ${response.body}');
            break;
          } else {
            print('Статус код для $url: ${response.statusCode}');
          }
        } catch (e) {
          print('Ошибка для URL $url: $e');
          continue;
        }
      }
      
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> tasks = [];
        
        if (data is Map && data.containsKey('results')) {
          tasks = List<Map<String, dynamic>>.from(data['results']);
        } else if (data is List) {
          tasks = List<Map<String, dynamic>>.from(data);
        }
        
        // Фильтруем задачи по пользователю, если необходимо
        if (shouldFilterByUser && userId > 0) {
          print('🔍 Начинаем фильтрацию задач для пользователя ID: $userId');
          print('🔍 Тип userId: ${userId.runtimeType}');
          print('🔍 Всего задач до фильтрации: ${tasks.length}');
          
          tasks = tasks.where((task) {
            final assignedUserId = task['assigned_to'] ?? task['assigned_user'] ?? task['assigned_user_id'];
            final taskId = task['id'];
            final taskTitle = task['title'];
            
            print('🔍 Задача ID: $taskId, Название: "$taskTitle"');
            print('🔍   assigned_to: ${task['assigned_to']} (тип: ${task['assigned_to']?.runtimeType})');
            print('🔍   assigned_user: ${task['assigned_user']} (тип: ${task['assigned_user']?.runtimeType})');
            print('🔍   assigned_user_id: ${task['assigned_user_id']} (тип: ${task['assigned_user_id']?.runtimeType})');
            print('🔍   Итоговый assignedUserId: $assignedUserId (тип: ${assignedUserId?.runtimeType})');
            print('🔍   userId: $userId (тип: ${userId.runtimeType})');
            print('🔍   Сравнение: $assignedUserId == $userId = ${assignedUserId == userId}');
            
            return assignedUserId == userId;
          }).toList();
          print('✅ Отфильтровано ${tasks.length} задач для пользователя ID: $userId');
        } else {
          print('Показываем все задачи (роль: $userRole)');
        }
        
        if (!mounted) return;
        setState(() {
          allTasks = tasks;
          filteredTasks = List.from(allTasks);
          _updateTaskCounts();
          errorMessage = null;
        });
        
        print('Загружено ${tasks.length} задач из базы данных');
        print('Статистика: NEW: $todoCount, IN_PROGRESS: $progressCount, COMPLETED: $doneCount');
      } else {
        throw Exception('Не удалось подключиться к серверу');
      }
    } catch (e) {
      print('Ошибка загрузки задач: $e');
      if (!mounted) return;
      
      // Получаем информацию о текущем пользователе для фильтрации тестовых данных
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;
      final userRole = currentUser?.role ?? '';
      final userId = currentUser?.id ?? 0;
      final shouldFilterByUser = !['SUPERADMIN', 'ADMIN', 'DIRECTOR'].contains(userRole);
      
      // Убираем тестовые данные полностью
      
      setState(() {
        errorMessage = 'Ошибка загрузки задач: $e';
        // Не показываем тестовые данные - только реальные данные с сервера
        allTasks = [];
        filteredTasks = [];
        _updateTaskCounts();
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }



  Future<void> _loadEmployees() async {
    try {
      // Получаем токен авторизации
      final apiService = ApiService();
      final token = await apiService.getToken();
      
      final urls = [
        '${AppConfig.baseApiUrl}/employees/',
        '${AppConfig.baseApiUrl}/api/employees/',
        'https://barlau.org/api/employees/',
      ];
      
      for (final url in urls) {
        try {
          print('Пробуем загрузить сотрудников с: $url');
          
          final headers = {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          };
          
          // Добавляем токен авторизации, если он есть
          if (token != null && token.isNotEmpty) {
            headers['Authorization'] = 'Bearer $token';
            print('Добавлен токен авторизации для запроса сотрудников');
          }
          
          final response = await http.get(
            Uri.parse(url),
            headers: headers,
          ).timeout(const Duration(seconds: 5));
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            print('Ответ сервера сотрудников: ${response.body}');
            if (!mounted) return;
            setState(() {
              if (data is Map && data.containsKey('results')) {
                employees = List<Map<String, dynamic>>.from(data['results']);
              } else if (data is List) {
                employees = List<Map<String, dynamic>>.from(data);
              }
            });
            print('Загружено ${employees.length} сотрудников');
            print('📋 Список сотрудников:');
            for (final emp in employees) {
              print('   ID: ${emp['id']}, Имя: ${emp['full_name']}, Username: ${emp['username']}');
            }
            return;
          } else {
            print('Статус код для $url: ${response.statusCode}');
          }
        } catch (e) {
          print('Ошибка для URL $url: $e');
          continue;
        }
      }
      
      // Если не удалось загрузить с сервера, оставляем пустой список
      print('Не удалось загрузить сотрудников с сервера');
      setState(() {
        employees = [];
      });
    } catch (e) {
      print('Ошибка загрузки сотрудников: $e');
    }
  }

  Future<void> _loadVehicles() async {
    try {
      // Получаем токен авторизации
      final apiService = ApiService();
      final token = await apiService.getToken();
      
      final urls = [
        '${AppConfig.baseApiUrl}/vehicles/',
      ];
      
      for (final url in urls) {
        try {
          final headers = {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          };
          
          // Добавляем токен авторизации, если он есть
          if (token != null && token.isNotEmpty) {
            headers['Authorization'] = 'Bearer $token';
            print('Добавлен токен авторизации для запроса грузовиков');
          }
          
          final response = await http.get(
            Uri.parse(url),
            headers: headers,
          ).timeout(const Duration(seconds: 2));
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (!mounted) return;
            setState(() {
              if (data is Map && data.containsKey('results')) {
                vehicles = List<Map<String, dynamic>>.from(data['results']);
              } else if (data is List) {
                vehicles = List<Map<String, dynamic>>.from(data);
              }
            });
            print('Загружено ${vehicles.length} транспортных средств');
            return;
          }
        } catch (e) {
          print('Ошибка для URL $url: $e');
          continue;
        }
      }
    } catch (e) {
      print('Ошибка загрузки транспорта: $e');
    }
  }

  void _updateTaskCounts() {
    todoCount = filteredTasks.where((task) => task['status'] == 'NEW').length;
    progressCount = filteredTasks.where((task) => task['status'] == 'IN_PROGRESS').length;
    doneCount = filteredTasks.where((task) => task['status'] == 'COMPLETED').length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppHeader(
        title: 'Задачи',
        isConnected: errorMessage == null && allTasks.isNotEmpty,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2679DB)))
        : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки данных',
                    style: TextStyle(
    fontFamily: 'SF Pro Display',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Не удалось загрузить задачи с сервера',
                    style: TextStyle(
    fontFamily: 'SF Pro Display',
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadTasks,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2679DB),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Попробовать снова'),
                  ),
                  const SizedBox(height: 32),
                  // Не показываем задачи при ошибке
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Нет данных для отображения',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : _buildTasksList(),
      floatingActionButton: _canCreateTasks() ? FloatingActionButton(
        onPressed: () => _showCreateTaskModal(),
        backgroundColor: const Color(0xFF2679DB),
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 24),
      ) : null,
    );
  }

  Widget _buildTasksList() {
    return Column(
      children: [
        // Контент задач
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTasks,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // К выполнению
                  _buildTaskGroup(
                    'К выполнению',
                    todoCount,
                    const Color(0xFF64748B),
                    Icons.radio_button_unchecked,
                    filteredTasks.where((task) => task['status'] == 'NEW').toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // В работе
                  _buildTaskGroup(
                    'В работе',
                    progressCount,
                    const Color(0xFFF59E0B),
                    Icons.schedule,
                    filteredTasks.where((task) => task['status'] == 'IN_PROGRESS').toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Выполнено
                  _buildTaskGroup(
                    'Выполнено',
                    doneCount,
                    const Color(0xFF10B981),
                    Icons.check_circle_outline,
                    filteredTasks.where((task) => task['status'] == 'COMPLETED').toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskGroup(String title, int count, Color color, IconData icon, List<Map<String, dynamic>> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок группы
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
    fontFamily: 'SF Pro Display',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Задачи
        if (tasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Нет задач',
              style: TextStyle(
    fontFamily: 'SF Pro Display',
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          )
        else
          ...tasks.map((task) => _buildTaskCard(task)).toList(),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final isCompleted = task['status'] == 'COMPLETED';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showTaskDetailsModal(task),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              // Чекпоинт
              GestureDetector(
                onTap: () => _changeTaskStatus(task),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFF2679DB) : Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: isCompleted ? const Color(0xFF2679DB) : const Color(0xFFD1D5DB),
                      width: 1.5,
                    ),
                  ),
                  child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      )
                    : null,
                ),
              ),
              const SizedBox(width: 12),
              
              // Содержимое задачи
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task['title'] ?? '',
                            style: TextStyle(
    fontFamily: 'SF Pro Display',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isCompleted ? const Color(0xFF9CA3AF) : const Color(0xFF1F2937),
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        _buildPriorityBadge(task['priority']),
                      ],
                    ),
                    if (task['description'] != null && task['description'].isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task['description'],
                        style: TextStyle(
    fontFamily: 'SF Pro Display',
                          fontSize: 13,
                          color: isCompleted ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Text(
                          _formatDate(task['due_date']),
                          style: const TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const Spacer(),
                        
                        // Аватар исполнителя
                        if (task['assigned_user_details'] != null)
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: const Color(0xFF2679DB).withOpacity(0.1),
                            child: Text(
                              (task['assigned_user_details']['first_name'] != null && 
                               task['assigned_user_details']['first_name'].isNotEmpty) 
                                ? task['assigned_user_details']['first_name'][0].toUpperCase()
                                : 'U',
                              style: const TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2679DB),
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
      ),
    );
  }

  Widget _buildPriorityBadge(String? priority) {
    Color color;
    String text;
    
    switch (priority) {
      case 'HIGH':
        color = const Color(0xFFEF4444);
        text = 'Срочно';
        break;
      case 'MEDIUM':
        color = const Color(0xFF2679DB);
        text = 'Средний';
        break;
      case 'LOW':
        color = const Color(0xFF10B981);
        text = 'Низкий';
        break;
      default:
        color = const Color(0xFF6B7280);
        text = 'Не указан';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: TextStyle(
    fontFamily: 'SF Pro Display',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Без срока';
    
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM', 'ru').format(date);
    } catch (e) {
      return 'Без срока';
    }
  }

  Future<void> _changeTaskStatus(Map<String, dynamic> task) async {
    String newStatus;
    switch (task['status']) {
      case 'NEW':
        newStatus = 'IN_PROGRESS';
        break;
      case 'IN_PROGRESS':
        newStatus = 'COMPLETED';
        break;
      default:
        return; // Завершенные задачи не меняем
    }

    // Обновляем статус через API
    await _updateTaskStatus(task['id'], newStatus);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Статус задачи изменен')),
    );

    // Попытка обновить на сервере
    try {
      final urls = [
        '${AppConfig.baseApiUrl}/logistics/tasks/${task['id']}/change_status/',
        '${AppConfig.baseApiUrl}/api/tasks/${task['id']}/change_status/',
      ];
      
      for (final url in urls) {
        try {
          final response = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({'status': newStatus}),
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            return; // Успешно обновлено
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      print('Ошибка обновления статуса: $e');
    }
  }

  void _showTaskDetailsModal(Map<String, dynamic> task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailsModal(
        task: task,
        onTaskUpdated: _loadTasks,
        onStatusChanged: _changeTaskStatus,
      ),
    );
  }

  void _showCreateTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTaskModal(
        employees: employees,
        vehicles: vehicles,
        onTaskCreated: _loadTasks,
      ),
    );
  }

  Future<void> _updateTaskStatus(int taskId, String newStatus) async {
    try {
      final urls = [
        '${AppConfig.baseApiUrl}/tasks/$taskId/',
                  '${AppConfig.baseApiUrl}/tasks/$taskId/',
        '${AppConfig.baseApiUrl}/api/tasks/$taskId/',
      ];
      
      for (final url in urls) {
        try {
          final response = await http.patch(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: json.encode({'status': newStatus}),
          ).timeout(const Duration(seconds: 10));
          
          if (response.statusCode == 200) {
            print('Статус задачи $taskId обновлен на $newStatus');
            // Обновляем локальные данные
            setState(() {
              final taskIndex = allTasks.indexWhere((task) => task['id'] == taskId);
              if (taskIndex != -1) {
                allTasks[taskIndex]['status'] = newStatus;
                filteredTasks = List.from(allTasks);
                _updateTaskCounts();
              }
            });
            return;
          } else {
            print('Ошибка обновления статуса для $url: ${response.statusCode}');
          }
        } catch (e) {
          print('Ошибка для URL $url: $e');
          continue;
        }
      }
      
      // Если не удалось обновить на сервере, обновляем локально
      print('Не удалось обновить на сервере, обновляем локально');
      setState(() {
        final taskIndex = allTasks.indexWhere((task) => task['id'] == taskId);
        if (taskIndex != -1) {
          allTasks[taskIndex]['status'] = newStatus;
          filteredTasks = List.from(allTasks);
          _updateTaskCounts();
        }
      });
    } catch (e) {
      print('Ошибка обновления статуса задачи: $e');
      // Обновляем локально в случае ошибки
      setState(() {
        final taskIndex = allTasks.indexWhere((task) => task['id'] == taskId);
        if (taskIndex != -1) {
          allTasks[taskIndex]['status'] = newStatus;
          filteredTasks = List.from(allTasks);
          _updateTaskCounts();
        }
      });
    }
  }

  String _formatFullDate(String? dateStr) {
    if (dateStr == null) return 'Не указана';
    
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy', 'ru').format(date);
    } catch (e) {
      return 'Не указана';
    }
  }

  String _getFirstLetter(String? name) {
    if (name == null || name.isEmpty) return 'U';
    return name[0].toUpperCase();
  }

  bool _canCreateTasks() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?.role ?? '';
    
    // Только админы, директор и диспетчер могут создавать задачи
    final canCreate = ['SUPERADMIN', 'ADMIN', 'DIRECTOR', 'DISPATCHER'].contains(userRole);
    print('Права на создание задач для роли $userRole: $canCreate');
    return canCreate;
  }
}

// Модальное окно деталей задачи
class TaskDetailsModal extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onTaskUpdated;
  final Function(Map<String, dynamic>) onStatusChanged;

  const TaskDetailsModal({
    super.key,
    required this.task,
    required this.onTaskUpdated,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    task['title'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          
          // Содержимое
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Описание
                  if (task['description'] != null && task['description'].isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Описание',
                            style: TextStyle(
    fontFamily: 'SF Pro Display',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            task['description'],
                            style: const TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 14,
                              color: Color(0xFF111827),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Основная информация
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Статус',
                          _getStatusBadge(task['status']),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(
                          'Приоритет',
                          _getPriorityBadge(task['priority']),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Срок выполнения',
                          Text(
                            task['due_date'] != null 
                              ? (() {
                                  try {
                                    final date = DateTime.parse(task['due_date']);
                                    return DateFormat('dd MMMM yyyy', 'ru').format(date);
                                  } catch (e) {
                                    return 'Не указана';
                                  }
                                })()
                              : 'Не указана',
                            style: const TextStyle(
    fontFamily: 'SF Pro Display',
                              fontSize: 14,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(
                          'Дата создания',
                          Text(
                            task['created_at'] != null 
                              ? (() {
                                  try {
                                    final date = DateTime.parse(task['created_at']);
                                    return DateFormat('dd MMMM yyyy', 'ru').format(date);
                                  } catch (e) {
                                    return 'Не указана';
                                  }
                                })()
                              : 'Не указана',
                            style: const TextStyle(
    fontFamily: 'SF Pro Display',
                              fontSize: 14,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Исполнитель
                  if (task['assigned_user_details'] != null) ...[
                    _buildInfoItem(
                      'Исполнитель',
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF2679DB).withOpacity(0.1),
                              child: Text(
                                (task['assigned_user_details']['first_name'] != null && 
                                 task['assigned_user_details']['first_name'].isNotEmpty) 
                                  ? task['assigned_user_details']['first_name'][0].toUpperCase()
                                  : 'U',
                                style: const TextStyle(
    fontFamily: 'SF Pro Display',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2679DB),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              task['assigned_user_details']['full_name'] ?? 
                              task['assigned_user_details']['username'] ?? 
                              'Не указан',
                              style: const TextStyle(
    fontFamily: 'SF Pro Display',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Создатель
                  if (task['created_by_details'] != null) ...[
                    _buildInfoItem(
                      'Создал',
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                              child: Text(
                                (task['created_by_details']['first_name'] != null && 
                                 task['created_by_details']['first_name'].isNotEmpty) 
                                  ? task['created_by_details']['first_name'][0].toUpperCase()
                                  : 'U',
                                style: const TextStyle(
    fontFamily: 'SF Pro Display',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              task['created_by_details']['full_name'] ?? 
                              task['created_by_details']['username'] ?? 
                              'Не указан',
                              style: const TextStyle(
    fontFamily: 'SF Pro Display',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Действия
                  Row(
                    children: [
                      if (task['status'] == 'NEW') ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onStatusChanged(task);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2679DB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Начать работу'),
                          ),
                        ),
                      ] else if (task['status'] == 'IN_PROGRESS') ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onStatusChanged(task);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Завершить'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
    fontFamily: 'SF Pro Display',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _getStatusBadge(String? status) {
    Color color;
    String text;
    
    switch (status) {
      case 'NEW':
        color = const Color(0xFF64748B);
        text = 'К выполнению';
        break;
      case 'IN_PROGRESS':
        color = const Color(0xFFF59E0B);
        text = 'В работе';
        break;
      case 'COMPLETED':
        color = const Color(0xFF10B981);
        text = 'Выполнено';
        break;
      default:
        color = const Color(0xFF6B7280);
        text = 'Неизвестно';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
    fontFamily: 'SF Pro Display',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _getPriorityBadge(String? priority) {
    Color color;
    String text;
    
    switch (priority) {
      case 'HIGH':
        color = const Color(0xFFEF4444);
        text = 'Высокий';
        break;
      case 'MEDIUM':
        color = const Color(0xFF2679DB);
        text = 'Средний';
        break;
      case 'LOW':
        color = const Color(0xFF10B981);
        text = 'Низкий';
        break;
      default:
        color = const Color(0xFF6B7280);
        text = 'Не указан';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
    fontFamily: 'SF Pro Display',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String _getFirstLetter(String? name) {
    if (name == null || name.isEmpty) return 'U';
    return name[0].toUpperCase();
  }

  String _formatFullDate(String? dateStr) {
    if (dateStr == null) return 'Не указана';
    
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy', 'ru').format(date);
    } catch (e) {
      return 'Не указана';
    }
  }
}

// Модальное окно создания задачи
class CreateTaskModal extends StatefulWidget {
  final List<Map<String, dynamic>> employees;
  final List<Map<String, dynamic>> vehicles;
  final VoidCallback onTaskCreated;

  const CreateTaskModal({
    super.key,
    required this.employees,
    required this.vehicles,
    required this.onTaskCreated,
  });

  @override
  State<CreateTaskModal> createState() => _CreateTaskModalState();
}

class _CreateTaskModalState extends State<CreateTaskModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _priority = 'MEDIUM';
  DateTime? _dueDate;
  int? _assignedUserId;
  int? _vehicleId;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      width: MediaQuery.of(context).size.width,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Новая задача',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          
          // Форма
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Название
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Название задачи',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите название задачи';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Описание
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Добавить описание...',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Приоритет и дата
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _priority,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'LOW', child: Text('Низкий')),
                              DropdownMenuItem(value: 'MEDIUM', child: Text('Средний')),
                              DropdownMenuItem(value: 'HIGH', child: Text('Высокий')),
                            ],
                            onChanged: (value) => setState(() => _priority = value!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _dueDate != null 
                                  ? DateFormat('dd.MM.yyyy').format(_dueDate!)
                                  : 'Выберите дату',
                                style: TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  color: _dueDate != null 
                                    ? const Color(0xFF111827)
                                    : const Color(0xFF6B7280),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Исполнитель
                    DropdownButtonFormField<int>(
                      value: _assignedUserId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Основной исполнитель',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Выберите исполнителя'),
                        ),
                        ...widget.employees.map((employee) => DropdownMenuItem<int>(
                          value: employee['id'],
                          child: Text(
                            employee['full_name'] ?? employee['username'] ?? 'Сотрудник',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                      ],
                      onChanged: (value) {
                        print('🎯 Выбран исполнитель ID: $value');
                        setState(() => _assignedUserId = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Транспорт (опционально)
                    DropdownButtonFormField<int>(
                      value: _vehicleId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Транспорт (опционально)',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Выберите транспорт'),
                        ),
                        ...widget.vehicles.map((vehicle) => DropdownMenuItem<int>(
                          value: vehicle['id'],
                          child: Text(
                            '${vehicle['brand']} ${vehicle['model']} (${vehicle['number']})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                      ],
                      onChanged: (value) => setState(() => _vehicleId = value),
                    ),
                    const SizedBox(height: 32),
                    
                    // Кнопки
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Отмена',
                              style: TextStyle(
    fontFamily: 'SF Pro Display',color: Color(0xFF374151)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitTask,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2679DB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Создать задачу'),
                          ),
                        ),
                      ],
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

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите дату выполнения')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final taskData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'priority': _priority,
        'due_date': _dueDate!.toIso8601String(),
        if (_assignedUserId != null) 'assigned_to': _assignedUserId,
        if (_vehicleId != null) 'vehicle': _vehicleId,
      };

      print('📝 Создаем задачу с данными: $taskData');
      print('📝 assigned_to: $_assignedUserId');

      // Получаем токен авторизации
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      
      print('📝 Токен авторизации: ${authToken != null ? "есть" : "нет"}');
      
      final response = await http.post(
        Uri.parse('${AppConfig.baseApiUrl}/tasks/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        body: json.encode(taskData),
      );

      print('📝 Ответ сервера: ${response.statusCode}');
      print('📝 Тело ответа: ${response.body}');

      if (response.statusCode == 201) {
        print('✅ Задача успешно создана, обновляем список задач...');
        Navigator.pop(context);
        
        // Принудительно обновляем данные
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onTaskCreated();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Задача успешно создана')),
        );
      } else {
        throw Exception('Ошибка создания задачи: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}
 