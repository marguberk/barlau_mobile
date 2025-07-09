import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../components/app_header.dart';
import '../services/pdf_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_viewer_screen.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> employee;

  const EmployeeDetailScreen({
    super.key,
    required this.employee,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  bool isLoading = false;
  Map<String, dynamic>? detailedEmployee;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadEmployeeDetails();
  }

  Future<void> _loadEmployeeDetails() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final employeeId = widget.employee['id'];
      final urls = [
        'https://barlau.org/api/employees/$employeeId/',
                  'https://barlau.org/api/employees/$employeeId/',
      ];

      http.Response? response;
      for (final url in urls) {
        try {
          response = await http.get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ).timeout(const Duration(seconds: 3));

          if (response.statusCode == 200) {
            break;
          }
        } catch (e) {
          continue;
        }
      }

      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Детальные данные сотрудника: $data');
        if (!mounted) return;
        setState(() {
          detailedEmployee = data;
        });
      }
    } catch (e) {
      print('Ошибка загрузки деталей сотрудника: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String? _getPhotoUrl(dynamic photoPath) {
    if (photoPath == null || photoPath.toString().isEmpty) {
      return null;
    }
    
    String photoStr = photoPath.toString();
    
    if (photoStr.startsWith('http')) {
      return photoStr;
    }
    
    return 'https://barlau.org$photoStr';
  }

  String _getInitials(String firstName, String lastName) {
    String firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    String lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  Future<void> _downloadPDF() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final employeeId = widget.employee['id'];
      final firstName = widget.employee['first_name'] ?? '';
      final lastName = widget.employee['last_name'] ?? '';
      final fullName = '$firstName $lastName'.trim();

      // Вариант 1: Встроенный PDF viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerScreen(
            employeeId: employeeId,
            employeeName: fullName,
          ),
        ),
      );

      // Показываем сообщение об успехе
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Открываем PDF резюме...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // В случае ошибки, пробуем открыть в браузере
      try {
        final success = await PDFService.openEmployeePDF(widget.employee['id']);
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось открыть PDF'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: $e2'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Widget _buildInfoSection(String title, String? content, IconData icon) {
    if (content == null || content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF2679DB),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF374151),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String? value, {VoidCallback? onTap}) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2679DB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2679DB),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2679DB).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2679DB).withOpacity(0.2),
        ),
      ),
      child: Text(
        skill.trim(),
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF2679DB),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLanguageItem(String language) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.language,
            color: Color(0xFF6B7280),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              language.trim(),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employee = detailedEmployee ?? widget.employee;
    final fullName = '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'.trim();
    final initials = _getInitials(employee['first_name'] ?? '', employee['last_name'] ?? '');
    final photoUrl = _getPhotoUrl(employee['photo']);
    final position = employee['position'] ?? employee['role_display'] ?? '';
    final desiredSalary = employee['desired_salary'];

    // Добавляем демонстрационные данные если поля пустые
    final demoEmployee = Map<String, dynamic>.from(employee);
    if (fullName == 'Серик Айдарбеков') {
      demoEmployee['about_me'] = demoEmployee['about_me']?.toString().isNotEmpty == true 
          ? demoEmployee['about_me'] 
          : 'Опытный руководитель с более чем 20-летним стажем в логистической отрасли. Специализируюсь на стратегическом планировании, управлении персоналом и развитии бизнеса. Имею богатый опыт в ведении переговоров и построении долгосрочных партнерских отношений.';
      
      demoEmployee['experience'] = demoEmployee['experience']?.toString().isNotEmpty == true 
          ? demoEmployee['experience'] 
          : '''2005-2025: Директор ТОО "Barlau" - Управление логистической компанией, развитие бизнеса, стратегическое планирование

2000-2005: Заместитель директора ООО "КазТранс" - Управление операционной деятельностью, координация работы отделов

1995-2000: Начальник отдела логистики АО "АлматыТранс" - Организация грузоперевозок, работа с клиентами''';
      
      demoEmployee['education'] = demoEmployee['education']?.toString().isNotEmpty == true 
          ? demoEmployee['education'] 
          : '''Казахский Национальный Университет им. аль-Фараби, Экономический факультет, специальность "Менеджмент" (1990-1995)

Алматинская Бизнес-школа, MBA программа "Стратегическое управление" (2003-2005)''';
      
      demoEmployee['key_skills'] = demoEmployee['key_skills']?.toString().isNotEmpty == true 
          ? demoEmployee['key_skills'] 
          : 'Стратегическое планирование, Управление персоналом, Развитие бизнеса, Логистика, Финансовое планирование, Ведение переговоров';
      
      demoEmployee['languages'] = demoEmployee['languages']?.toString().isNotEmpty == true 
          ? demoEmployee['languages'] 
          : '''Казахский (родной)
Русский (свободно)
Английский (продвинутый)
Китайский (базовый)''';
      
      demoEmployee['hobbies'] = demoEmployee['hobbies']?.toString().isNotEmpty == true 
          ? demoEmployee['hobbies'] 
          : 'Горный туризм, чтение книг по бизнесу, игра в теннис, фотография';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppHeader(
        title: 'Профиль',
        isConnected: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF6B7280),
          ),
        ),
        showNotificationIcon: false,
        showProfileIcon: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _downloadPDF,
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.download,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2679DB),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Основная карточка профиля
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
                        // Фото профиля
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(60),
                            border: Border.all(
                              color: const Color(0xFF2679DB).withOpacity(0.2),
                              width: 4,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(56),
                            child: photoUrl != null
                                ? Image.network(
                                    photoUrl,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 120,
                                        height: 120,
                                        color: const Color(0xFF2679DB).withOpacity(0.1),
                                        child: Center(
                                          child: Text(
                                            initials,
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2679DB),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    width: 120,
                                    height: 120,
                                    color: const Color(0xFF2679DB).withOpacity(0.1),
                                    child: Center(
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2679DB),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Имя и позиция
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          position,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // Желаемая зарплата
                        if (desiredSalary != null && desiredSalary.toString().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2679DB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Желаемая зарплата: $desiredSalary',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2679DB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Контактная информация
                  Container(
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
                        const SizedBox(height: 20),
                        _buildContactItem(
                          Icons.email_outlined,
                          'Email',
                          demoEmployee['email'],
                        ),
                        _buildContactItem(
                          Icons.phone_outlined,
                          'Телефон',
                          demoEmployee['phone'],
                        ),
                        _buildContactItem(
                          Icons.location_on_outlined,
                          'Местоположение',
                          demoEmployee['location'] ?? 'Алматы, Казахстан',
                        ),
                        if (demoEmployee['skype'] != null && demoEmployee['skype'].toString().isNotEmpty)
                          _buildContactItem(
                            Icons.video_call_outlined,
                            'Skype',
                            demoEmployee['skype'],
                          ),
                        if (demoEmployee['linkedin'] != null && demoEmployee['linkedin'].toString().isNotEmpty)
                          _buildContactItem(
                            Icons.link,
                            'LinkedIn',
                            demoEmployee['linkedin'],
                          ),
                        if (demoEmployee['portfolio_url'] != null && demoEmployee['portfolio_url'].toString().isNotEmpty)
                          _buildContactItem(
                            Icons.web,
                            'Портфолио',
                            demoEmployee['portfolio_url'],
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Ключевые навыки
                  if (demoEmployee['key_skills'] != null && demoEmployee['key_skills'].toString().isNotEmpty) ...[
                    Container(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ключевые навыки',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            children: demoEmployee['key_skills']
                                .toString()
                                .split(',')
                                .map<Widget>((skill) => _buildSkillChip(skill))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Языки
                  if (demoEmployee['languages'] != null && demoEmployee['languages'].toString().isNotEmpty) ...[
                    Container(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Языки',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...demoEmployee['languages']
                              .toString()
                              .split('\n')
                              .where((lang) => lang.trim().isNotEmpty)
                              .map<Widget>((lang) => _buildLanguageItem(lang))
                              .toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // О себе
                  _buildInfoSection(
                    'О себе',
                    demoEmployee['about_me'],
                    Icons.person_outline,
                  ),

                  // Опыт работы
                  _buildInfoSection(
                    'Опыт работы',
                    demoEmployee['experience'],
                    Icons.work_outline,
                  ),

                  // Образование
                  _buildInfoSection(
                    'Образование',
                    demoEmployee['education'],
                    Icons.school_outlined,
                  ),

                  // Навыки (skills - отличается от key_skills)
                  _buildInfoSection(
                    'Профессиональные навыки',
                    demoEmployee['skills'],
                    Icons.build_outlined,
                  ),

                  // Сертификаты
                  _buildInfoSection(
                    'Сертификаты',
                    demoEmployee['certifications'],
                    Icons.verified_outlined,
                  ),

                  // Достижения
                  _buildInfoSection(
                    'Достижения',
                    demoEmployee['achievements'],
                    Icons.emoji_events_outlined,
                  ),

                  // Курсы и тренинги
                  _buildInfoSection(
                    'Курсы и тренинги',
                    demoEmployee['courses'],
                    Icons.menu_book_outlined,
                  ),

                  // Публикации
                  _buildInfoSection(
                    'Публикации',
                    demoEmployee['publications'],
                    Icons.article_outlined,
                  ),

                  // Рекомендации
                  _buildInfoSection(
                    'Рекомендации',
                    demoEmployee['recommendations'],
                    Icons.recommend_outlined,
                  ),

                  // Хобби и интересы
                  _buildInfoSection(
                    'Хобби и интересы',
                    demoEmployee['hobbies'],
                    Icons.interests_outlined,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}