import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final bool emailConfirmed;
  final DateTime? lastSignIn;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    this.fullName,
    required this.emailConfirmed,
    this.lastSignIn,
    required this.createdAt,
  });

  String get initials {
    if (fullName != null && fullName!.isNotEmpty) {
      final parts = fullName!.trim().split(' ');
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      return fullName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  String get displayName => fullName ?? email.split('@').first;

  @override
  List<Object?> get props => [id, email, fullName, emailConfirmed, lastSignIn, createdAt];
}