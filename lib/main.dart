import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/profile_screen.dart';
import 'config/app_config.dart';

void main() async {
  // Глобальная обработка ошибок
  FlutterError.onError = (FlutterErrorDetails details) {
    print('🔴 Flutter Error: ${details.exception}');
    print('🔴 Stack trace: ${details.stack}');
    FlutterError.presentError(details);
  };

  // Обработка ошибок вне Flutter
  PlatformDispatcher.instance.onError = (error, stack) {
    print('🔴 Platform Error: $error');
    print('🔴 Stack trace: $stack');
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализируем и выводим конфигурацию
  print('🟢 Инициализация приложения...');
  print('🔧 ========== APP CONFIG ==========');
  print('🔧 kReleaseMode: $kReleaseMode');
  print('🔧 kDebugMode: $kDebugMode');
  print('🔧 kIsWeb: $kIsWeb');
  print('🔧 Platform.isIOS: ${!kIsWeb ? Platform.isIOS : 'N/A'}');
  print('🔧 Platform.isAndroid: ${!kIsWeb ? Platform.isAndroid : 'N/A'}');
  print('🔧 baseApiUrl: ${AppConfig.baseApiUrl}');
  print('🔧 baseUrl: ${AppConfig.baseUrl}');
  print('🔧 ================================');
  
  try {
    print('🟢 Инициализация локализации...');
    await initializeDateFormatting('ru_RU', null);
    print('🟢 Локализация инициализирована');
  } catch (e) {
    print('🟡 Ошибка инициализации локализации: $e');
    // Продолжаем работу даже если локализация не загрузилась
  }
  
  print('🟢 Запуск приложения...');
  runApp(const BarlauApp());
}

class BarlauApp extends StatelessWidget {
  const BarlauApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('🟢 Создание BarlauApp');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            print('🟢 Создание AuthProvider');
            return AuthProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print('🟢 Создание NotificationProvider');
            return NotificationProvider();
          },
        ),
      ],
      child: MaterialApp(
        title: 'BARLAU.KZ',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ru', 'RU'),
          Locale('kk', 'KZ'),
          Locale('en', 'US'),
        ],
        locale: const Locale('ru', 'RU'),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2679DB),
          ),
          fontFamily: 'SF Pro Display',
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    print('🟢 AuthWrapper initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🟢 AuthWrapper postFrameCallback');
      try {
        context.read<AuthProvider>().checkAuthStatus();
        print('🟢 checkAuthStatus вызван');
      } catch (e) {
        print('🔴 Ошибка в checkAuthStatus: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🟢 AuthWrapper build');
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        print('🟢 AuthWrapper Consumer build - isAuthenticated: ${auth.isAuthenticated}, isLoading: ${auth.isLoading}');
        
        if (auth.isLoading) {
          print('🟡 Показываем загрузочный экран - isLoading: ${auth.isLoading}');
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2679DB)),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'BARLAU.KZ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2679DB),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('Загрузка...'),
                ],
              ),
            ),
          );
        }

        if (auth.isAuthenticated) {
          print('🟢 Пользователь авторизован, показываем MainScreen');
          try {
            return const MainScreen();
          } catch (e) {
            print('🔴 Ошибка при создании MainScreen: $e');
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Ошибка загрузки: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AuthProvider>().logout();
                      },
                      child: const Text('Выйти'),
                    ),
                  ],
                ),
              ),
            );
          }
        } else {
          print('🟡 Пользователь не авторизован, показываем LoginScreen');
          try {
            return const LoginScreen();
          } catch (e) {
            print('🔴 Ошибка при создании LoginScreen: $e');
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Ошибка загрузки экрана входа: $e'),
                  ],
                ),
              ),
            );
          }
        }
      },
    );
  }
}