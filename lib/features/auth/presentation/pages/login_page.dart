import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthSignInRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    Icon(Icons.lock_outline, size: 80, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 24),
                    const Text('Bienvenido', textAlign: TextAlign.center, 
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 48),
                    AuthTextField(
                      controller: _emailController,
                      label: 'Email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _passwordController,
                      label: 'Contraseña',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      validator: (v) => v?.isEmpty == true ? 'Requerida' : null,
                      enabled: !isLoading,
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading ? null : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                          );
                        },
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AuthButton(
                      text: 'Iniciar Sesión',
                      onPressed: _handleLogin,
                      isLoading: isLoading,
                      icon: Icons.login,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('¿No tienes cuenta? '),
                        TextButton(
                          onPressed: isLoading ? null : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterPage()),
                            );
                          },
                          child: const Text('Regístrate'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}