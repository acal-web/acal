import 'package:flutter/material.dart';
import 'package:acalapp/features/auth/data/auth_service.dart';
import 'package:acalapp/features/auth/data/token_storage.dart';
import 'package:acalapp/features/auth/domain/login_username.dart';
import 'package:acalapp/features/auth/presentation/current_user_scope.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Usuário e senha são obrigatórios';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.login(
        normalizeLoginUsername(_usernameController.text),
        _passwordController.text,
      );

      await TokenStorage.write(result.token);

      if (mounted) {
        CurrentUserScope.of(context).setSession(result.user, result.token);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Falha no login. Verifique suas credenciais.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: cs.surface,
      body: Row(
        children: [
          // Left side: Branding (hidden on mobile)
          if (size.width > 900)
            Expanded(
              child: Container(
                color: cs.primary,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ACAL',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sistema de Gestão de Água',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      width: 2,
                      height: 100,
                      color: cs.onPrimary.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ),
          // Right side: Login form
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width > 900 ? 64 : 32,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (size.width <= 900) ...[
                        Text(
                          'ACAL',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sistema de Gestão',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: cs.outline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                      ],
                      Text(
                        'Bem-vindo',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Entre com suas credenciais',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.outline,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _usernameController,
                        enabled: !_isLoading,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          labelText: 'Usuário ou CPF',
                          hintText: 'Usuário ou CPF',
                          prefixIcon: Icon(Icons.person_outline, color: cs.outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: cs.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: cs.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        enabled: !_isLoading,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          labelText: 'Senha ou código do cliente',
                          hintText: '••••••••',
                          prefixIcon: Icon(Icons.lock_outline, color: cs.outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: cs.outline,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: cs.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: cs.primary, width: 2),
                          ),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: cs.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: cs.error.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: cs.primary,
                          disabledBackgroundColor: cs.primary.withValues(alpha: 0.5),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(cs.onPrimary),
                                ),
                              )
                            : Text(
                                'Entrar',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          '© 2026 ACAL - Sistema de Gestão de Água',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
