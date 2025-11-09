import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _usernameKey = 'username';

  Future<bool> register(String phone, String password, String username) async {
    final prefs = await SharedPreferences.getInstance();

    final existingUser = prefs.getString('user_$phone');
    if (existingUser != null) {
      return false;
    }

    final userData = {
      'phone': phone,
      'password': password,
      'username': username,
    };

    await prefs.setString('user_$phone', json.encode(userData));
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userKey, json.encode(userData));
    await prefs.setString(_usernameKey, username);

    print('Registered user: $username, phone: $phone');
    return true;
  }

  Future<bool> login(String phone, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_$phone');

    if (userDataString == null) {
      print('User not found for phone: $phone');
      return false;
    }

    final userData = json.decode(userDataString);
    if (userData['password'] == password) {
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userKey, userDataString);
      await prefs.setString(_usernameKey, userData['username']);

      print('Login successful for user: ${userData['username']}');
      return true;
    }

    print('Wrong password for phone: $phone');
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_userKey);
    print('User logged out');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userKey);

    if (userDataString != null) {
      return json.decode(userDataString);
    }

    return null;
  }

  Future<String> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();

    final username = prefs.getString(_usernameKey);
    if (username != null && username.isNotEmpty) {
      return username;
    }

    final userDataString = prefs.getString(_userKey);
    if (userDataString != null) {
      final userData = json.decode(userDataString);
      return userData['username'] ?? 'User';
    }

    return 'User';
  }

  Future<bool> isPhoneExists(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_$phone') != null;
  }

  Future<void> debugPrintAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    print('=== DEBUG AUTH SERVICE ===');
    for (final key in keys) {
      if (key.startsWith('user_') ||
          key == _userKey ||
          key == _isLoggedInKey ||
          key == _usernameKey) {
        final value = prefs.get(key);
        print('$key: $value');
      }
    }
    print('==========================');
  }
}
