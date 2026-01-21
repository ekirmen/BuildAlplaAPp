import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._authService);

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_session');

      if (username != null) {
        final user = await _authService.getUser(username);
        if (user != null) {
          _currentUser = user;
          _isAuthenticated = true;
        } else {
          // Si el usuario ya no existe en la DB, limpiamos la sesión
          await prefs.remove('user_session');
        }
      }
    } catch (e) {
      // Error silencioso al restaurar sesión
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final (user, message) = await _authService.authenticate(username, password);

    if (user != null) {
      _currentUser = user;
      _isAuthenticated = true;
      _isLoading = false;
      
      // Guardar sesión
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session', username);
      
      notifyListeners();
      return true;
    } else {
      _errorMessage = message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() async {
    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    
    // Eliminar sesión
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
    
    notifyListeners();
  }

  Future<void> ensureDefaultAdmin() async {
    await _authService.ensureDefaultAdmin();
  }
}
