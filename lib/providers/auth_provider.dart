import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  bool get isPatient => _user?.isPatient ?? false;
  bool get isClinician => _user?.isClinician ?? false;

  Future<void> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');

    if (userJson != null) {
      final userMap = jsonDecode(userJson);
      _user = UserModel.fromJson(userMap);
      notifyListeners();
    }
  }

  Future<bool> login(String eposta, String sifre) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.login(eposta, sifre);
      await _saveSession(_user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e.toString().contains('GEÇERSİZ_GİRİŞ')) {
        _errorMessage = 'GEÇERSİZ_GİRİŞ';
      } else {
        _errorMessage = 'BAĞLANTI_HATASI';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String ad,
    required String soyad,
    required String eposta,
    required String sifre,
    required String rolAdi,
    String? unvan,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.register(
        ad: ad,
        soyad: soyad,
        eposta: eposta,
        sifre: sifre,
        rolAdi: rolAdi,
        unvan: unvan,
      );
      await _saveSession(_user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e.toString().contains('EMAIL_KAYITLI')) {
        _errorMessage = 'EMAIL_KAYITLI';
      } else {
        _errorMessage = 'BAĞLANTI_HATASI';
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
