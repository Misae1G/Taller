import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure({required this.message});
  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

class AuthFailure extends Failure {
  final String? code;
  const AuthFailure({required super.message, this.code});
  @override
  List<Object?> get props => [message, code];

  factory AuthFailure.fromCode(String code) {
    final messages = {
      'invalid_credentials': 'Credenciales inválidas',
      'email_not_confirmed': 'Email no confirmado',
      'user_already_exists': 'Email ya registrado',
      'weak_password': 'Contraseña muy débil',
    };
    return AuthFailure(message: messages[code] ?? 'Error de autenticación', code: code);
  }
}