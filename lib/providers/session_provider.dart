import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SessionProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? user;
  String role = 'USER';
  bool isLoading = true;

  void init() {
    _authService.authStateChanges().listen((u) async {
      user = u;
      if (user != null) {
        role = await _authService.getRole(user!.uid);
      } else {
        role = 'USER';
      }
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> refreshRole() async {
    if (user == null) return;
    role = await _authService.getRole(user!.uid);
    notifyListeners();
  }

  AuthService get auth => _authService;
}
