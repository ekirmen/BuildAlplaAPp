import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  Future<(UserModel?, String)> authenticate(String username, String password) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();

      if (response == null) {
        return (null, 'Usuario no encontrado');
      }

      final user = UserModel.fromJson(response);
      
      if (user.salt != null && user.password != null) {
        final hashedPassword = _hashPassword(password, user.salt!);
        if (hashedPassword == user.password) {
          return (user, 'OK');
        }
      }

      return (null, 'Contraseña incorrecta');
    } catch (e) {
      return (null, 'Error de conexión: $e');
    }
  }

  Future<UserModel?> getUser(String username) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();

      if (response != null) {
        return UserModel.fromJson(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }


  Future<(bool, String)> createUser({
    required String username,
    required String password,
    required String role,
    required String name,
  }) async {
    try {
      final exists = await _supabase
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (exists != null) {
        return (false, 'Usuario ya existe');
      }

      final salt = _generateSalt();
      final hashedPassword = _hashPassword(password, salt);

      await _supabase.from('users').insert({
        'username': username,
        'password': hashedPassword,
        'salt': salt,
        'role': role,
        'name': name,
      });

      return (true, 'Usuario creado exitosamente');
    } catch (e) {
      return (false, 'Error: $e');
    }
  }

  Future<(bool, String)> updateUser({
    required String username,
    String? role,
    String? name,
    String? newPassword,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (role != null) updates['role'] = role;
      if (name != null) updates['name'] = name;
      
      if (newPassword != null && newPassword.isNotEmpty) {
        final salt = _generateSalt();
        final hashedPassword = _hashPassword(newPassword, salt);
        updates['password'] = hashedPassword;
        updates['salt'] = salt;
      }

      await _supabase
          .from('users')
          .update(updates)
          .eq('username', username);

      return (true, 'Usuario actualizado');
    } catch (e) {
      return (false, 'Error: $e');
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabase.from('users').select();
      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> ensureDefaultAdmin() async {
    try {
      final adminExists = await _supabase
          .from('users')
          .select('username')
          .eq('username', 'admin')
          .maybeSingle();

      if (adminExists == null) {
        final salt = _generateSalt();
        final hashedPassword = _hashPassword('admin123', salt);

        await _supabase.from('users').insert({
          'username': 'admin',
          'password': hashedPassword,
          'salt': salt,
          'role': 'admin',
          'name': 'Admin Sistema',
        });
      }
    } catch (e) {
      // Silently fail if table doesn't exist yet
    }
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    return sha256.convert(bytes).toString();
  }

  String _generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return sha256.convert(utf8.encode(random)).toString().substring(0, 32);
  }
}
