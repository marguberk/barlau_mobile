import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/safe_api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  final ApiService _apiService = ApiService();

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  // Сохранение пользователя в локальное хранилище
  Future<void> _saveUserToLocal(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(user.toJson());
      await prefs.setString('user_profile', userJson);
      print('AuthProvider: Профиль сохранен локально');
    } catch (e) {
      print('AuthProvider: Ошибка сохранения профиля: $e');
    }
  }

  // Загрузка пользователя из локального хранилища
  Future<User?> _loadUserFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_profile');
      if (userJson != null) {
        final userMap = json.decode(userJson);
        print('AuthProvider: Профиль загружен из локального хранилища');
        return User.fromJson(userMap);
      }
    } catch (e) {
      print('AuthProvider: Ошибка загрузки профиля: $e');
    }
    return null;
  }

  // Удаление пользователя из локального хранилища
  Future<void> _removeUserFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile');
      print('AuthProvider: Профиль удален из локального хранилища');
    } catch (e) {
      print('AuthProvider: Ошибка удаления профиля: $e');
    }
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      print('AuthProvider: Начинаем проверку статуса авторизации');
      // Сначала пробуем загрузить из локального хранилища
      final localUser = await _loadUserFromLocal();
      if (localUser != null) {
        _user = localUser;
        _isAuthenticated = true;
        _error = null;
        print('AuthProvider: Профиль загружен из локального хранилища');
        print('AuthProvider: Используем локально сохраненный профиль');
      }

      // Если есть локальные данные, используем их как основные
      if (localUser != null) {
        print('AuthProvider: Найдены локальные данные, используем их');
        _isAuthenticated = true;
        _error = null;
      } else {
        print('AuthProvider: Локальных данных нет, требуется авторизация');
        _isAuthenticated = false;
        _user = null;
        _error = null;
      }
    } catch (e) {
      // Если произошла ошибка, но есть локальные данные - используем их
      final localUser = await _loadUserFromLocal();
      if (localUser != null) {
        _user = localUser;
        _isAuthenticated = true;
        _error = null;
        print('AuthProvider: Используем локальные данные из-за ошибки сети');
      } else {
        _isAuthenticated = false;
        _user = null;
        _error = 'Ошибка проверки авторизации';
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('AuthProvider: Попытка входа для пользователя $username');
      
      // Используем безопасный API
      final result = await SafeApiService.safeLogin(username, password);
      
      print('AuthProvider: Результат SafeApiService.safeLogin: ${result['success']}');
      print('AuthProvider: Данные пользователя: ${result['data']?['user']}');
      
      if (result['success']) {
        if (result['data']['user'] != null) {
          print('AuthProvider: Создаем пользователя из JSON');
          _user = User.fromJson(result['data']['user']);
          print('AuthProvider: Пользователь создан: ${_user!.username}, роль: ${_user!.role}');
          
          // Сохраняем пользователя локально
          await _saveUserToLocal(_user!);
          print('AuthProvider: Пользователь сохранен локально');
        }
        _isAuthenticated = true;
        _error = null;
        print('AuthProvider: Авторизация успешна, устанавливаем _isAuthenticated = true');
        _isLoading = false;
        notifyListeners();
        print('AuthProvider: notifyListeners() вызван после успешной авторизации');
        return true;
      } else {
        print('AuthProvider: Авторизация неуспешна: ${result['error']}');
        _error = result['error'] ?? 'Неверный логин или пароль';
        _isAuthenticated = false;
        _user = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('AuthProvider: Ошибка при входе - $e');
      _error = 'Ошибка входа в систему';
      _isAuthenticated = false;
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
    } catch (e) {
      // Игнорируем ошибки при выходе
    }

    _user = null;
    _isAuthenticated = false;
    _error = null;
    _isLoading = false;
    
    // Удаляем локальные данные
    await _removeUserFromLocal();
    
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? profilePicture,
    bool removeAvatar = false,
  }) async {
    if (_user == null) {
      print('AuthProvider: Пользователь не найден для обновления');
      return false;
    }

    print('AuthProvider: Начинаем обновление профиля');
    print('AuthProvider: Старые данные - ${_user!.firstName} ${_user!.lastName}, ${_user!.email}');
    print('AuthProvider: Новые данные - $firstName $lastName, $email');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Здесь будет вызов API для обновления профиля
      // Пока что обновляем локально
      
      String? newProfilePicture = _user!.profilePicture;
      
      if (removeAvatar) {
        newProfilePicture = null;
        print('AuthProvider: Удаляем аватарку');
      } else if (profilePicture != null) {
        newProfilePicture = profilePicture;
        print('AuthProvider: Новая аватарка: $profilePicture');
      }
      
      final oldUser = _user;
      _user = User(
        id: _user!.id,
        username: _user!.username,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        role: _user!.role,
        isActive: _user!.isActive,
        profilePicture: newProfilePicture,
      );

      print('AuthProvider: Обновленный пользователь создан');
      print('AuthProvider: Новый пользователь - ${_user!.firstName} ${_user!.lastName}, ${_user!.email}');

      // Сохраняем обновленный профиль локально
      await _saveUserToLocal(_user!);
      print('AuthProvider: Профиль сохранен локально успешно');

      _isLoading = false;
      notifyListeners();
      print('AuthProvider: notifyListeners() вызван');
      return true;
    } catch (e) {
      _error = 'Ошибка обновления профиля';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
} 
 
 
 