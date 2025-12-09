import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String? fullName;
  const AuthSignUpRequested({required this.email, required this.password, this.fullName});
  @override
  List<Object?> get props => [email, password, fullName];
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignInRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;
  const AuthPasswordResetRequested({required this.email});
  @override
  List<Object?> get props => [email];
}

class AuthPasswordUpdateRequested extends AuthEvent {
  final String currentPassword;
  final String newPassword;
  const AuthPasswordUpdateRequested({required this.currentPassword, required this.newPassword});
  @override
  List<Object?> get props => [currentPassword, newPassword];
}

class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}

class AuthStateChanged extends AuthEvent {
  final bool isAuthenticated;
  const AuthStateChanged({required this.isAuthenticated});
  @override
  List<Object?> get props => [isAuthenticated];
}