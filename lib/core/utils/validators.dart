import 'package:email_validator/email_validator.dart';

class Validators {
  Validators._();

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'El email es requerido';
    if (!EmailValidator.validate(value.trim())) return 'Email inválido';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Contraseña requerida';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Requiere una mayúscula';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Requiere un número';
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != password) return 'Las contraseñas no coinciden';
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nombre requerido';
    if (value.trim().length < 2) return 'Nombre muy corto';
    return null;
  }
}