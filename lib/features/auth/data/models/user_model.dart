import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.fullName,
    required super.emailConfirmed,
    super.lastSignIn,
    required super.createdAt,
  });

  factory UserModel.fromSupabaseUser(supabase.User user) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      fullName: user.userMetadata?['full_name'] as String?,
      emailConfirmed: user.emailConfirmedAt != null,
      lastSignIn: user.lastSignInAt != null ? DateTime.parse(user.lastSignInAt!) : null,
      createdAt: DateTime.parse(user.createdAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'email_confirmed': emailConfirmed,
    'last_sign_in': lastSignIn?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };
}