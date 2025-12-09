import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/update_password_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignUpUseCase signUpUseCase;
  final SignInUseCase signInUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final SendPasswordResetUseCase sendPasswordResetUseCase;
  final UpdatePasswordUseCase updatePasswordUseCase;
  final AuthRepository authRepository;
  StreamSubscription? _authStateSubscription;

  AuthBloc({
    required this.signUpUseCase,
    required this.signInUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
    required this.sendPasswordResetUseCase,
    required this.updatePasswordUseCase,
    required this.authRepository,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthPasswordUpdateRequested>(_onPasswordUpdateRequested);
    on<AuthErrorCleared>(_onErrorCleared);
    on<AuthStateChanged>(_onAuthStateChanged);
    _listenToAuthState();
  }

  void _listenToAuthState() {
    _authStateSubscription = authRepository.authStateChanges.listen((user) {
      if (user != null && state is! AuthAuthenticated) {
        add(const AuthStateChanged(isAuthenticated: true));
      } else if (user == null && state is AuthAuthenticated) {
        add(const AuthStateChanged(isAuthenticated: false));
      }
    });
  }

  Future<void> _onAuthCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Verificando sesión...'));
    final result = await getCurrentUserUseCase(const NoParams());
    result.fold(
      (_) => emit(const AuthUnauthenticated()),
      (user) => user != null ? emit(AuthAuthenticated(user: user)) : emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onSignUpRequested(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Creando cuenta...'));
    final result = await signUpUseCase(SignUpParams(
      email: event.email, password: event.password, fullName: event.fullName,
    ));
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => user.emailConfirmed
          ? emit(AuthAuthenticated(user: user))
          : emit(AuthSignUpSuccess(email: user.email)),
    );
  }

  Future<void> _onSignInRequested(AuthSignInRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Iniciando sesión...'));
    final result = await signInUseCase(SignInParams(email: event.email, password: event.password));
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> _onSignOutRequested(AuthSignOutRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Cerrando sesión...'));
    final result = await signOutUseCase(const NoParams());
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onPasswordResetRequested(AuthPasswordResetRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Enviando correo...'));
    final result = await sendPasswordResetUseCase(SendPasswordResetParams(email: event.email));
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(AuthPasswordResetSent(email: event.email)),
    );
  }

  Future<void> _onPasswordUpdateRequested(AuthPasswordUpdateRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Actualizando contraseña...'));
    final result = await updatePasswordUseCase(UpdatePasswordParams(
      currentPassword: event.currentPassword, newPassword: event.newPassword,
    ));
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(const AuthPasswordUpdated()),
    );
  }

  void _onErrorCleared(AuthErrorCleared event, Emitter<AuthState> emit) {
    emit(const AuthUnauthenticated());
  }

  Future<void> _onAuthStateChanged(AuthStateChanged event, Emitter<AuthState> emit) async {
    if (event.isAuthenticated) {
      final result = await getCurrentUserUseCase(const NoParams());
      result.fold(
        (_) => emit(const AuthUnauthenticated()),
        (user) => user != null ? emit(AuthAuthenticated(user: user)) : null,
      );
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}