import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

enum UserMode { customer, seller }

class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isAuthenticated = false;
  UserMode _currentMode = UserMode.customer;
  bool _isLoading = false;
  bool _isDarkMode = true;

  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  UserMode get currentMode => _currentMode;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  bool get hasBusinessProfile => _user != null && _user!['businessProfile'] != null;

  String? get businessStatus => hasBusinessProfile 
      ? _user!['businessProfile']['status'] 
      : null;

  Future<bool> loginMockGoogle(String email, String name, String? avatarUrl) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.googleSignIn(email, name, avatarUrl).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await ApiService.setToken(data['token']);
        _user = data['user'];
        _isAuthenticated = true;
        
        // Initialize Socket.io session
        try {
          SocketService.connect(_user!['id']);
        } catch (_) {}
        
        await _saveSessionLocally();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Mock Google Auth API Failed (backend unreachable). Falling back to offline mock: $e');
      
      // Fallback for UI testing when backend is not running or unreachable
      await Future.delayed(const Duration(milliseconds: 500));
      await ApiService.setToken('mock_offline_token');
      _user = {
        'id': 'offline_user_1',
        'email': email,
        'name': name,
        'avatarUrl': avatarUrl,
        'businessProfile': null
      };
      _isAuthenticated = true;
      await _saveSessionLocally();
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> _saveSessionLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_user != null) {
        await prefs.setString('user_data', jsonEncode(_user));
      }
    } catch (e) {
      print('Error saving session locally: $e');
    }
  }

  Future<void> checkSession() async {
    await ApiService.init();
    try {
      final response = await ApiService.getMe().timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = data['user'];
        _isAuthenticated = true;
        await _saveSessionLocally();
        SocketService.connect(_user!['id']);
      }
    } catch (e) {
      print('Session check failed via API: $e. Checking local storage...');
      // Fallback to local shared preferences
      try {
        final prefs = await SharedPreferences.getInstance();
        final userData = prefs.getString('user_data');
        if (userData != null) {
          _user = jsonDecode(userData);
          _isAuthenticated = true;
          // Optionally connect socket if it makes sense offline
        }
      } catch (err) {
        print('Local session restore failed: $err');
      }
    }
    notifyListeners();
  }

  void toggleUserMode() {
    if (_currentMode == UserMode.customer) {
      _currentMode = UserMode.seller;
    } else {
      _currentMode = UserMode.customer;
    }
    notifyListeners();
  }

  Future<void> reloadUserProfile() async {
    try {
      final response = await ApiService.getMe();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = data['user'];
        await _saveSessionLocally();
        notifyListeners();
      }
    } catch (e) {
      print('Profile refresh failed: $e');
    }
  }

  // Allow updating user fields like avatar locally without hitting the server
  Future<void> updateUserLocalField(String key, dynamic value) async {
    if (_user != null) {
      _user![key] = value;
      await _saveSessionLocally();
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    } catch (e) {}
    SocketService.disconnect();
    _user = null;
    _isAuthenticated = false;
    _currentMode = UserMode.customer;
    notifyListeners();
  }
}
