import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signUp({required String email, required String password, String? fullName});
  Future<UserModel> signIn({required String email, required String password});
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updatePassword(String newPassword);
  Future<bool> verifyPassword(String password);
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient client;
  AuthRemoteDataSourceImpl({required this.client});
  GoTrueClient get _auth => client.auth;

  @override
  Future<UserModel> signUp({required String email, required String password, String? fullName}) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );
      if (response.user == null) throw const AuthException(message: 'Error al crear cuenta');
      return UserModel.fromSupabaseUser(response.user!);
    } on AuthApiException catch (e) {
      throw AuthException(message: _parseError(e.message), code: e.code);
    }
  }

  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    try {
      final response = await _auth.signInWithPassword(email: email, password: password);
      if (response.user == null) throw const AuthException(message: 'Credenciales inválidas');
      return UserModel.fromSupabaseUser(response.user!);
    } on AuthApiException catch (e) {
      throw AuthException(message: _parseError(e.message), code: e.code);
    }
  }

  @override
  Future<void> signOut() async => await _auth.signOut();

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    return user != null ? UserModel.fromSupabaseUser(user) : null;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final redirectUrl = dotenv.env['RESET_PASSWORD_URL'] ?? 'http://localhost:3000/reset-password';
    await _auth.resetPasswordForEmail(email, redirectTo: redirectUrl);
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<bool> verifyPassword(String password) async {
    try {
      final email = _auth.currentUser?.email;
      if (email == null) return false;
      await _auth.signInWithPassword(email: email, password: password);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      return user != null ? UserModel.fromSupabaseUser(user) : null;
    });
  }

  String _parseError(String message) {
    final errors = {
      'Invalid login credentials': 'Credenciales inválidas',
      'Email not confirmed': 'Email no confirmado',
      'User already registered': 'Email ya registrado',
    };
    return errors[message] ?? message;
  }
}