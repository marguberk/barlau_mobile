import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:feather_icons/feather_icons.dart';
import '../providers/auth_provider.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  late AnimationController _logoController;
  late AnimationController _formController;
  late AnimationController _titleController;
  late AnimationController _subtitleController;

  late Animation<double> _logoAnimation;
  late Animation<double> _formAnimation;
  late Animation<double> _titleAnimation;
  late Animation<double> _subtitleAnimation;

  @override
  void initState() {
    super.initState();

    // Предзаполняем номер телефона
    _phoneController.text = '+7';
    


    // Контроллеры анимации
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _formController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _subtitleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Анимации
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _formAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOut),
    );
    _titleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );
    _subtitleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeOut),
    );

    // Запуск анимаций
    _startAnimations();
  }

  void _startAnimations() async {
    if (!mounted) return;
    
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _logoController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _formController.forward();
    
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _titleController.forward();
    
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _subtitleController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _logoController.dispose();
    _formController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, заполните все поля'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _phoneController.text,
        _passwordController.text,
      );

      if (success && mounted) {
        // Успешная авторизация - перенаправляем на главный экран
        print('✅ Успешная авторизация, перенаправляем на главный экран');
        
        // Проверяем текущее состояние
        print('✅ Состояние до обновления - isAuthenticated: ${authProvider.isAuthenticated}, isLoading: ${authProvider.isLoading}');
        
        // Принудительно обновляем состояние AuthProvider
        authProvider.notifyListeners();
        
        // Добавляем небольшую задержку для корректного обновления UI
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Проверяем, что состояние обновилось
        print('✅ Состояние после входа - isAuthenticated: ${authProvider.isAuthenticated}, isLoading: ${authProvider.isLoading}');
        
        // Дополнительно вызываем checkAuthStatus для обновления состояния
        await authProvider.checkAuthStatus();
        print('✅ checkAuthStatus выполнен после входа');
        
        // Принудительно переходим на главный экран
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
        
      } else if (!success && mounted) {
        // Получаем конкретную ошибку из AuthProvider
        final errorMessage = authProvider.error ?? 'Неверный логин или пароль';
        
        // Показываем минималистичное уведомление об ошибке
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Иконка ошибки
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: Color(0xFFDC2626),
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Заголовок
                    const Text(
                      'Ошибка входа',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Сообщение
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Кнопка
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2679DB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Понятно',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка подключения к серверу: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF7FAFC), // bg-gray-50
          image: DecorationImage(
            image: AssetImage('assets/images/bg-dots.png'),
            fit: BoxFit.cover,
            scale: 1.25, // Уменьшаем размер фона на 20% как в веб-версии
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Логотип сверху
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: AnimatedBuilder(
                    animation: _logoAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -10 * (1 - _logoAnimation.value)),
                        child: Opacity(
                          opacity: _logoAnimation.value.clamp(0.0, 1.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/logo.png',
                                width: 42,
                                height: 23,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Barlau.kz',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF000000),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Пространство
                const SizedBox(height: 100),

                // Форма в центре
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimatedBuilder(
                    animation: _formAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 10 * (1 - _formAnimation.value)),
                        child: Opacity(
                          opacity: _formAnimation.value.clamp(0.0, 1.0),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 440),
                            margin: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width > 440 
                                  ? (MediaQuery.of(context).size.width - 440) / 2 
                                  : 0,
                            ),
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
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Заголовки
                                AnimatedBuilder(
                                  animation: _titleAnimation,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0, 10 * (1 - _titleAnimation.value)),
                                      child: Opacity(
                                        opacity: _titleAnimation.value.clamp(0.0, 1.0),
                                        child: const Text(
                                          'Войдите в систему',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF18181B), // text-zinc-950
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                AnimatedBuilder(
                                  animation: _subtitleAnimation,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0, 10 * (1 - _subtitleAnimation.value)),
                                      child: Opacity(
                                        opacity: _subtitleAnimation.value.clamp(0.0, 1.0),
                                        child: const Text(
                                          'Введите номер телефона и пароль',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF6B7280), // text-gray-500
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Поле телефона
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Номер телефона',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF6B7280), // text-gray-500
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE5E7EB), // border-gray-200
                                          width: 1,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF18181B),
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: '+7',
                                          hintStyle: TextStyle(
                                            color: Color(0xFF9CA3AF), // text-gray-400
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Поле пароля
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Пароль',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF6B7280), // text-gray-500
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE5E7EB), // border-gray-200
                                          width: 1,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _passwordController,
                                        obscureText: !_isPasswordVisible,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF18181B),
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isPasswordVisible
                                                  ? FeatherIcons.eyeOff
                                                  : FeatherIcons.eye,
                                              color: const Color(0xFF6B7280),
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isPasswordVisible = !_isPasswordVisible;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Кнопка входа
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2679DB), // bg-blue-600
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                      disabledBackgroundColor: const Color(0xFF9CA3AF),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'Войти',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),

                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Пространство внизу
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
 
 
 
 