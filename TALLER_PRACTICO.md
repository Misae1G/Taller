# Taller Práctico: Sistema de Autenticación con Flutter, Supabase y Railway

## 📋 Objetivo
Crear una aplicación móvil Flutter con autenticación completa usando Supabase como backend y Railway para el reseteo de contraseñas.

---

## 🏗️ Arquitectura del Proyecto

### Clean Architecture + BLoC Pattern
```
lib/
├── main.dart
├── injection_container.dart
├── core/
│   ├── error/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── usecases/
│   │   └── usecase.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   └── constants.dart
│   └── theme/
│       └── app_theme.dart
└── features/
    └── auth/
        ├── data/
        │   ├── datasources/
        │   ├── models/
        │   └── repositories/
        ├── domain/
        │   ├── entities/
        │   ├── repositories/
        │   └── usecases/
        └── presentation/
            ├── bloc/
            ├── pages/
            └── widgets/
```

---

## 🚀 Parte 1: Configuración Inicial

### Paso 1.1: Crear proyecto Flutter
```bash
flutter create flutter_login
cd flutter_login
```

### Paso 1.2: Configurar dependencias en `pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5

  # Backend
  supabase_flutter: ^2.8.0

  # Dependency Injection
  get_it: ^8.0.2

  # Utils
  dartz: ^0.10.1
  flutter_dotenv: ^5.2.1

  # UI
  google_fonts: ^6.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
```

### Paso 1.3: Crear archivo `.env`
```env
SUPABASE_URL=tu_url_de_supabase
SUPABASE_ANON_KEY=tu_anon_key
RESET_PASSWORD_URL=https://tu-app.up.railway.app/reset-password
```

### Paso 1.4: Actualizar `pubspec.yaml` para incluir .env
```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
```

---

## 🔧 Parte 2: Configurar Supabase

### Paso 2.1: Crear proyecto en Supabase
1. Ve a [supabase.com](https://supabase.com)
2. Crea un nuevo proyecto
3. Copia la URL y ANON_KEY

### Paso 2.2: Configurar Email Templates en Supabase
1. Ve a `Authentication` → `Email Templates`
2. Selecciona "Reset Password"
3. Configura la URL de redirección:
```
https://tu-app.up.railway.app/reset-password
```

### Paso 2.3: Habilitar confirmación de email (opcional)
1. Ve a `Authentication` → `Settings`
2. En "Email Auth", configura:
   - Enable email confirmations: `true/false` según necesites

---

## 📦 Parte 3: Implementar Core Layer

### Paso 3.1: Crear `core/error/exceptions.dart`
```dart
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException({required this.message, this.statusCode});
}

class AuthException implements Exception {
  final String message;
  final String? code;
  const AuthException({required this.message, this.code});
}

class CacheException implements Exception {
  final String message;
  const CacheException({required this.message});
}
```

### Paso 3.2: Crear `core/error/failures.dart`
```dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure({required this.message});

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}
```

### Paso 3.3: Crear `core/usecases/usecase.dart`
```dart
import 'package:dartz/dartz.dart';
import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();
  @override
  List<Object?> get props => [];
}
```

### Paso 3.4: Crear `core/utils/validators.dart`
```dart
class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }
}
```

### Paso 3.5: Crear `core/theme/app_theme.dart`
```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF667EEA),
        brightness: Brightness.light,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
    );
  }
}
```

---

## 🎯 Parte 4: Domain Layer

### Paso 4.1: Crear `domain/entities/user_entity.dart`
```dart
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final bool emailConfirmed;

  const UserEntity({
    required this.id,
    required this.email,
    this.fullName,
    required this.emailConfirmed,
  });

  @override
  List<Object?> get props => [id, email, fullName, emailConfirmed];
}
```

### Paso 4.2: Crear `domain/repositories/auth_repository.dart`
```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    String? fullName,
  });

  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, UserEntity?>> getCurrentUser();

  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  Stream<UserEntity?> get authStateChanges;
}
```

### Paso 4.3: Crear Use Cases

#### `domain/usecases/sign_up_usecase.dart`
```dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase implements UseCase<UserEntity, SignUpParams> {
  final AuthRepository repository;
  SignUpUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) async {
    return await repository.signUp(
      email: params.email,
      password: params.password,
      fullName: params.fullName,
    );
  }
}

class SignUpParams extends Equatable {
  final String email;
  final String password;
  final String? fullName;

  const SignUpParams({
    required this.email,
    required this.password,
    this.fullName,
  });

  @override
  List<Object?> get props => [email, password, fullName];
}
```

#### `domain/usecases/sign_in_usecase.dart`
```dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase implements UseCase<UserEntity, SignInParams> {
  final AuthRepository repository;
  SignInUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignInParams params) async {
    return await repository.signIn(
      email: params.email,
      password: params.password,
    );
  }
}

class SignInParams extends Equatable {
  final String email;
  final String password;

  const SignInParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}
```

#### Crear de forma similar:
- `sign_out_usecase.dart`
- `get_current_user_usecase.dart`
- `send_password_reset_usecase.dart`
- `update_password_usecase.dart`

---

## 💾 Parte 5: Data Layer

### Paso 5.1: Crear `data/models/user_model.dart`
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.fullName,
    required super.emailConfirmed,
  });

  factory UserModel.fromSupabaseUser(User user) {
    return UserModel(
      id: user.id,
      email: user.email!,
      fullName: user.userMetadata?['full_name'] as String?,
      emailConfirmed: user.emailConfirmedAt != null,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      emailConfirmed: json['email_confirmed'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'email_confirmed': emailConfirmed,
    };
  }
}
```

### Paso 5.2: Crear `data/datasources/auth_remote_datasource.dart`
```dart
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? fullName,
  });

  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updatePassword(String newPassword);
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient client;

  AuthRemoteDataSourceImpl({required this.client});

  GoTrueClient get _auth => client.auth;

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

      if (response.user == null) {
        throw const AuthException(message: 'Error al crear cuenta');
      }

      return UserModel.fromSupabaseUser(response.user!);
    } on AuthApiException catch (e) {
      throw AuthException(message: _parseError(e.message), code: e.code);
    }
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const AuthException(message: 'Credenciales inválidas');
      }

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
    final redirectUrl = dotenv.env['RESET_PASSWORD_URL'] ??
                       'http://localhost:3000/reset-password';
    await _auth.resetPasswordForEmail(email, redirectTo: redirectUrl);
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _auth.updateUser(UserAttributes(password: newPassword));
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
```

### Paso 5.3: Crear `data/repositories/auth_repository_impl.dart`
```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final user = await remoteDataSource.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(AuthFailure(message: 'Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.signIn(
        email: email,
        password: password,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(AuthFailure(message: 'Error inesperado: $e'));
    }
  }

  // Implementar los demás métodos...

  @override
  Stream<UserEntity?> get authStateChanges =>
      remoteDataSource.authStateChanges;
}
```

---

## 🎨 Parte 6: Presentation Layer

### Paso 6.1: Crear BLoC Events (`presentation/bloc/auth_event.dart`)
```dart
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

  const AuthSignUpRequested({
    required this.email,
    required this.password,
    this.fullName,
  });

  @override
  List<Object?> get props => [email, password, fullName];
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({
    required this.email,
    required this.password,
  });

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
```

### Paso 6.2: Crear BLoC States (`presentation/bloc/auth_state.dart`)
```dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  final String? message;
  const AuthLoading({this.message});
  @override
  List<Object?> get props => [message];
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated({required this.user});
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
  @override
  List<Object?> get props => [message];
}

class AuthPasswordResetSent extends AuthState {
  final String email;
  const AuthPasswordResetSent({required this.email});
  @override
  List<Object?> get props => [email];
}

class AuthSignUpSuccess extends AuthState {
  final String email;
  final bool requiresEmailConfirmation;

  const AuthSignUpSuccess({
    required this.email,
    this.requiresEmailConfirmation = true,
  });

  @override
  List<Object?> get props => [email, requiresEmailConfirmation];
}
```

### Paso 6.3: Crear BLoC (`presentation/bloc/auth_bloc.dart`)
```dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignUpUseCase signUpUseCase;
  final SignInUseCase signInUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final SendPasswordResetUseCase sendPasswordResetUseCase;
  final AuthRepository authRepository;
  StreamSubscription? _authStateSubscription;

  AuthBloc({
    required this.signUpUseCase,
    required this.signInUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
    required this.sendPasswordResetUseCase,
    required this.authRepository,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    _listenToAuthState();
  }

  void _listenToAuthState() {
    _authStateSubscription = authRepository.authStateChanges.listen((user) {
      // Manejar cambios de estado de autenticación
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Verificando sesión...'));
    final result = await getCurrentUserUseCase(const NoParams());
    result.fold(
      (_) => emit(const AuthUnauthenticated()),
      (user) => user != null
          ? emit(AuthAuthenticated(user: user))
          : emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Iniciando sesión...'));
    final result = await signInUseCase(
      SignInParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  // Implementar el resto de los handlers...

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
```

### Paso 6.4: Crear Widgets Reutilizables

#### `presentation/widgets/auth_text_field.dart`
```dart
import 'package:flutter/material.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;
  final void Function(String)? onFieldSubmitted;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.enabled = true,
    this.onFieldSubmitted,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword && _obscureText,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      enabled: widget.enabled,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.prefixIcon),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() => _obscureText = !_obscureText);
                },
              )
            : null,
      ),
    );
  }
}
```

#### `presentation/widgets/auth_button.dart`
```dart
import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon),
                    const SizedBox(width: 8),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }
}
```

### Paso 6.5: Crear Páginas

Ver archivos creados anteriormente:
- `login_page.dart`
- `register_page.dart`
- `forgot_password_page.dart`
- `home_page.dart`
- `splash_page.dart`

---

## 🔌 Parte 7: Dependency Injection

### Paso 7.1: Crear `injection_container.dart`
```dart
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/sign_up_usecase.dart';
import 'features/auth/domain/usecases/sign_in_usecase.dart';
import 'features/auth/domain/usecases/sign_out_usecase.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/send_password_reset_usecase.dart';
import 'features/auth/domain/usecases/update_password_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  sl.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => SendPasswordResetUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePasswordUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      signUpUseCase: sl(),
      signInUseCase: sl(),
      signOutUseCase: sl(),
      getCurrentUserUseCase: sl(),
      sendPasswordResetUseCase: sl(),
      authRepository: sl(),
    ),
  );
}
```

---

## 🚦 Parte 8: Main.dart

### Paso 8.1: Configurar `main.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: '.env');

  // Inicializar Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Inicializar dependencias
  await di.initDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
      ],
      child: MaterialApp(
        title: 'Flutter Auth Clean',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashPage(),
      ),
    );
  }
}
```

---

## 🌐 Parte 9: Web Server para Reset Password (Railway)

### Paso 9.1: Crear estructura del proyecto web
```
web_reset_password/
├── public/
│   ├── reset-password.html
│   ├── styles.css
│   └── app.js
├── server.js
├── package.json
└── Procfile
```

### Paso 9.2: Crear `package.json`
```json
{
  "name": "reset-password",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

### Paso 9.3: Crear `server.js`
```javascript
const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'reset-password.html'));
});

app.get('/reset-password', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'reset-password.html'));
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
```

### Paso 9.4: Crear `Procfile`
```
web: node server.js
```

### Paso 9.5: Crear `public/app.js`
```javascript
const SUPABASE_URL = 'TU_URL_DE_SUPABASE';
const SUPABASE_KEY = 'TU_ANON_KEY';

document.getElementById('resetForm').addEventListener('submit', async (e) => {
  e.preventDefault();

  const password = document.getElementById('password').value;
  const confirmPassword = document.getElementById('confirmPassword').value;
  const errorDiv = document.getElementById('error');
  const successDiv = document.getElementById('success');
  const submitBtn = document.getElementById('submitBtn');
  const btnText = document.getElementById('btnText');
  const btnLoader = document.getElementById('btnLoader');

  errorDiv.style.display = 'none';
  successDiv.style.display = 'none';

  if (password !== confirmPassword) {
    errorDiv.textContent = 'Las contraseñas no coinciden';
    errorDiv.style.display = 'block';
    return;
  }

  if (password.length < 6) {
    errorDiv.textContent = 'La contraseña debe tener al menos 6 caracteres';
    errorDiv.style.display = 'block';
    return;
  }

  // Obtener access token de la URL
  const hash = window.location.hash.substring(1);
  const params = new URLSearchParams(hash);
  const accessToken = params.get('access_token');

  if (!accessToken) {
    errorDiv.textContent = 'Token inválido o expirado';
    errorDiv.style.display = 'block';
    return;
  }

  submitBtn.disabled = true;
  btnText.style.display = 'none';
  btnLoader.style.display = 'inline-block';

  try {
    const response = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${accessToken}`
      },
      body: JSON.stringify({ password })
    });

    if (response.ok) {
      successDiv.textContent = '¡Contraseña actualizada exitosamente!';
      successDiv.style.display = 'block';
      document.getElementById('resetForm').reset();

      setTimeout(() => {
        window.close();
      }, 3000);
    } else {
      const error = await response.json();
      errorDiv.textContent = error.message || 'Error al actualizar contraseña';
      errorDiv.style.display = 'block';
    }
  } catch (error) {
    errorDiv.textContent = 'Error de conexión. Intenta nuevamente.';
    errorDiv.style.display = 'block';
  } finally {
    submitBtn.disabled = false;
    btnText.style.display = 'inline';
    btnLoader.style.display = 'none';
  }
});
```

### Paso 9.6: Crear `public/reset-password.html`
```html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Restablecer Contraseña</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="header">
                <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                    <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                </svg>
                <h1>Restablecer Contraseña</h1>
                <p class="subtitle">Ingresa tu nueva contraseña</p>
            </div>

            <form id="resetForm">
                <div class="form-group">
                    <label for="password">Nueva Contraseña</label>
                    <input
                        type="password"
                        id="password"
                        name="password"
                        required
                        minlength="6"
                        placeholder="Mínimo 6 caracteres"
                    >
                </div>

                <div class="form-group">
                    <label for="confirmPassword">Confirmar Contraseña</label>
                    <input
                        type="password"
                        id="confirmPassword"
                        name="confirmPassword"
                        required
                        minlength="6"
                        placeholder="Repite tu contraseña"
                    >
                </div>

                <div id="error" class="error" style="display: none;"></div>
                <div id="success" class="success" style="display: none;"></div>

                <button type="submit" id="submitBtn" class="btn">
                    <span id="btnText">Restablecer Contraseña</span>
                    <span id="btnLoader" class="loader" style="display: none;"></span>
                </button>
            </form>

            <div class="footer">
                <a href="#" onclick="window.close(); return false;">Volver a la aplicación</a>
            </div>
        </div>
    </div>

    <script src="app.js"></script>
</body>
</html>
```

### Paso 9.7: Crear `public/styles.css`
```css
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
    "Helvetica Neue", Arial, sans-serif;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.container {
  width: 100%;
  max-width: 450px;
}

.card {
  background: white;
  border-radius: 16px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  padding: 40px;
  animation: slideUp 0.5s ease;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.header {
  text-align: center;
  margin-bottom: 32px;
}

.icon {
  width: 64px;
  height: 64px;
  color: #667eea;
  margin-bottom: 16px;
}

h1 {
  font-size: 28px;
  color: #1a202c;
  margin-bottom: 8px;
}

.subtitle {
  color: #718096;
  font-size: 14px;
}

.form-group {
  margin-bottom: 20px;
}

label {
  display: block;
  font-weight: 500;
  color: #2d3748;
  margin-bottom: 8px;
  font-size: 14px;
}

input {
  width: 100%;
  padding: 12px 16px;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 16px;
  transition: all 0.3s;
  outline: none;
}

input:focus {
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

input::placeholder {
  color: #a0aec0;
}

.btn {
  width: 100%;
  padding: 14px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 20px rgba(102, 126, 234, 0.3);
}

.btn:active {
  transform: translateY(0);
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.loader {
  width: 20px;
  height: 20px;
  border: 3px solid rgba(255, 255, 255, 0.3);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.error {
  background: #fed7d7;
  color: #c53030;
  padding: 12px 16px;
  border-radius: 8px;
  margin-bottom: 16px;
  font-size: 14px;
  border-left: 4px solid #fc8181;
}

.success {
  background: #c6f6d5;
  color: #22543d;
  padding: 12px 16px;
  border-radius: 8px;
  margin-bottom: 16px;
  font-size: 14px;
  border-left: 4px solid #48bb78;
}

.footer {
  text-align: center;
  margin-top: 24px;
}

.footer a {
  color: #667eea;
  text-decoration: none;
  font-size: 14px;
  font-weight: 500;
  transition: color 0.3s;
}

.footer a:hover {
  color: #764ba2;
  text-decoration: underline;
}

@media (max-width: 480px) {
  .card {
    padding: 24px;
  }

  h1 {
    font-size: 24px;
  }
}
```

---

## 🚀 Parte 10: Deploy en Railway

### Paso 10.1: Preparar el repositorio
```bash
# Inicializar git (si no lo has hecho)
git init
git add .
git commit -m "Initial commit"

# Crear repositorio en GitHub y subir
git remote add origin https://github.com/tu-usuario/tu-repo.git
git push -u origin master
```

### Paso 10.2: Deploy en Railway
1. Ve a [railway.app](https://railway.app)
2. Crea una cuenta e inicia sesión
3. Click en "New Project"
4. Selecciona "Deploy from GitHub repo"
5. Autoriza Railway a acceder a tu GitHub
6. Selecciona tu repositorio
7. En Settings:
   - **Root Directory**: `web_reset_password`
   - **Builder**: Nixpacks (detecta Node.js automáticamente)
8. Click en "Deploy"
9. Una vez desplegado, copia la URL pública

### Paso 10.3: Actualizar configuraciones
1. Actualiza `.env` con la URL de Railway:
```env
RESET_PASSWORD_URL=https://tu-app.up.railway.app/reset-password
```

2. Actualiza `app.js` con tus credenciales de Supabase

3. Actualiza en Supabase la URL de reset password

---

## 🧪 Parte 11: Testing

### Paso 11.1: Crear prueba para repositorio
```dart
// test/features/auth/data/repositories/auth_repository_impl_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

class MockAuthRemoteDataSource extends Mock
    implements AuthRemoteDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
    );
  });

  group('signIn', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tUserModel = UserModel(
      id: '1',
      email: tEmail,
      emailConfirmed: true,
    );

    test('should return UserEntity when signIn is successful', () async {
      // Arrange
      when(() => mockRemoteDataSource.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => tUserModel);

      // Act
      final result = await repository.signIn(
        email: tEmail,
        password: tPassword,
      );

      // Assert
      expect(result, equals(Right(tUserModel)));
      verify(() => mockRemoteDataSource.signIn(
        email: tEmail,
        password: tPassword,
      )).called(1);
    });
  });
}
```

---

## 📱 Parte 12: Pruebas Manuales

### Checklist de pruebas:

#### ✅ Registro de usuario
1. Abre la app
2. Click en "Regístrate"
3. Llena el formulario
4. Verifica que se cree el usuario en Supabase
5. Si hay confirmación de email, revisa tu correo

#### ✅ Inicio de sesión
1. En la pantalla de login
2. Ingresa email y contraseña
3. Verifica que redirija a Home
4. Verifica que muestre el email del usuario

#### ✅ Recuperar contraseña
1. Click en "¿Olvidaste tu contraseña?"
2. Ingresa tu email
3. Revisa tu correo electrónico
4. Click en el enlace
5. Debe abrir la página web de Railway
6. Ingresa nueva contraseña
7. Intenta hacer login con la nueva contraseña

#### ✅ Cerrar sesión
1. En Home, click en el botón de logout
2. Debe volver al Login

---

## 🐛 Troubleshooting Común

### Error: "AuthException isn't a function"
**Solución:**
```dart
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
```

### Error: Gradle build failed
**Solución:**
1. Actualizar Gradle a versión 8.9
2. Actualizar Android Gradle Plugin a 8.7.3
3. Instalar NDK 27.0.12077973

### Error: Railway no detecta la app
**Solución:**
1. Asegúrate de que `Procfile` existe
2. Configura Root Directory en Railway
3. Verifica que `package.json` tenga el script `start`

### Email de reset no llega
**Solución:**
1. Verifica la configuración en Supabase
2. Revisa la carpeta de spam
3. Verifica que la URL en el template sea correcta

---

## 📚 Recursos Adicionales

- [Documentación Flutter](https://docs.flutter.dev/)
- [Documentación Supabase](https://supabase.com/docs)
- [BLoC Pattern](https://bloclibrary.dev/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Railway Docs](https://docs.railway.app/)

---

## 🎯 Próximos Pasos

1. Agregar Google/Apple Sign-In
2. Implementar refresh tokens
3. Agregar verificación de email en 2 pasos
4. Implementar dark mode
5. Agregar internacionalización (i18n)
6. Implementar pruebas unitarias completas
7. Agregar análisis con Firebase Analytics
8. Implementar CI/CD con GitHub Actions

---

## 📝 Notas Finales

- Nunca subas archivos `.env` a GitHub
- Usa `.gitignore` adecuadamente
- Mantén las dependencias actualizadas
- Implementa manejo de errores robusto
- Documenta tu código
- Realiza pruebas exhaustivas antes de producción

---

**¡Felicidades!** Has completado el taller práctico de autenticación con Flutter, Supabase y Railway.
