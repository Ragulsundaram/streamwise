import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _username;
  String? _email;
  static const String _userKey = 'users';
  static const String _currentUserKey = 'current_user';
  bool _isInitialized = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  String? get email => _email;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_currentUserKey);
      if (userData != null) {
        final Map<String, dynamic> user = jsonDecode(userData);
        _username = user['username'];
        _email = user['email'];
        _isLoggedIn = true;
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isStrongPassword(String password) {
    return password.length >= 8 && 
           RegExp(r'[A-Z]').hasMatch(password) &&
           RegExp(r'[a-z]').hasMatch(password) &&
           RegExp(r'[0-9]').hasMatch(password) &&
           RegExp(r'[!@#\$&*~]').hasMatch(password);
  }

  String _hashPassword(String password) {
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(password + salt);
    return '${sha256.convert(bytes).toString()}:$salt';
  }

  bool _verifyPassword(String password, String hashedPassword) {
    final parts = hashedPassword.split(':');
    if (parts.length != 2) return false;
    final salt = parts[1];
    final bytes = utf8.encode(password + salt);
    return sha256.convert(bytes).toString() == parts[0];
  }

  Future<Map<String, dynamic>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_userKey);
    if (usersJson == null) return {};
    return Map<String, dynamic>.from(jsonDecode(usersJson));
  }

  Future<void> _saveUsers(Map<String, dynamic> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(users));
  }

  Future<void> clearUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_currentUserKey);
    debugPrint('All users cleared');
  }

  Future<(bool, String)> login(String username, String password) async {
    try {
      final users = await _getUsers();
      
      // Find user by username
      final userEntry = users.entries.firstWhere(
        (entry) => entry.value['username'] == username,
        orElse: () => MapEntry('', {}),
      );

      if (userEntry.value.isEmpty) {
        return (false, 'User not found');
      }

      if (!_verifyPassword(password, userEntry.value['password'])) {
        return (false, 'Invalid password');
      }

      _isLoggedIn = true;
      _username = username;
      _email = userEntry.key;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, jsonEncode({
        'username': _username,
        'email': _email,
      }));
      
      notifyListeners();
      debugPrint('Login successful for user: $username');
      return (true, 'Login successful');
    } catch (e) {
      debugPrint('Login error: $e');
      return (false, 'An error occurred during login');
    }
  }

  Future<(bool, String)> signup(String username, String email, String password) async {
    if (username.length < 3) {
      return (false, 'Username must be at least 3 characters long');
    }
    if (!_isValidEmail(email)) {
      return (false, 'Invalid email format');
    }
    if (!_isStrongPassword(password)) {
      return (false, 'Password must be at least 8 characters long and contain uppercase, lowercase, number and special character');
    }

    try {
      final users = await _getUsers();
      
      // Check for duplicate email
      if (users.containsKey(email)) {
        return (false, 'Email already registered');
      }

      // Check for duplicate username
      if (users.values.any((user) => user['username'] == username)) {
        return (false, 'Username already taken');
      }

      users[email] = {
        'username': username,
        'password': _hashPassword(password),
      };
      
      await _saveUsers(users);
      debugPrint('Users after signup: ${jsonEncode(users)}');
      return (true, 'Signup successful');
    } catch (e) {
      debugPrint('Signup error: $e');
      return (false, 'An error occurred during signup');
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
    } finally {
      _isLoggedIn = false;
      _username = null;
      _email = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isLoggedIn = false;
    _username = null;
    _email = null;
    super.dispose();
  }
}