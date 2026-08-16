import 'dart:convert';
import 'package:flutter/material.dart';
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
      final response = await ApiService.googleSignIn(email, name, avatarUrl);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await ApiService.setToken(data['token']);
        _user = data['user'];
        _isAuthenticated = true;
        
        // Initialize Socket.io session
        SocketService.connect(_user!['id']);
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Mock Google Auth Login Failed: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> checkSession() async {
    await ApiService.init();
    try {
      final response = await ApiService.getMe();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = data['user'];
        _isAuthenticated = true;
        SocketService.connect(_user!['id']);
      }
    } catch (e) {
      print('Session check failed: $e');
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
        notifyListeners();
      }
    } catch (e) {
      print('Profile refresh failed: $e');
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    SocketService.disconnect();
    _user = null;
    _isAuthenticated = false;
    _currentMode = UserMode.customer;
    notifyListeners();
  }
}
