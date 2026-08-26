import 'package:flutter/material.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/customer_portal/data/customer_auth_service.dart';
import 'package:acalapp/features/customer_portal/data/portal_token_storage.dart';
import 'package:acalapp/features/customer_portal/presentation/current_customer_scope.dart';
import 'package:acalapp/shared/formatters/document_formatter.dart';
import 'package:go_router/go_router.dart';

class CustomerLoginPage extends StatefulWidget {
  const CustomerLoginPage({super.key});

  @override
  State<CustomerLoginPage> createState() => _CustomerLoginPageState();
}

class _CustomerLoginPageState extends State<CustomerLoginPage> {
  final _documentController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  late CustomerAuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = CustomerAuthService();
  }

  @override
  void dispose() {
    _documentController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final document = _documentController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final code = _codeController.text.trim();

    if (document.isEmpty || code.isEmpty) {
      setState(() => _errorMessage = 'CPF e código do cliente são obrigatórios');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.login(document, code);
      await PortalTokenStorage.write(result.token);

      if (mounted) {
        CurrentCustomerScope.of(context).setSession(result.customer, result.token);
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.body is Map ? (e.body['message'] as String? ?? _genericError) : _genericError);
    } catch (_) {
      setState(() => _errorMessage = _genericError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static const _genericError = 'Não foi possível entrar. Verifique o CPF e o código do cliente.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Área do Sócio',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Entre com seu CPF e o código do cliente',
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.outline),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _documentController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.number,
                  inputFormatters: [DocumentInputFormatter(DocumentKind.cpf)],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'CPF',
                    hintText: '000.000.000-00',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleLogin(),
                  decoration: const InputDecoration(
                    labelText: 'Código do cliente',
                    prefixIcon: Icon(Icons.pin_outlined),
                    border: OutlineInputBorder(),
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
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.error, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(cs.onPrimary)),
                        )
                      : const Text('Entrar'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => context.go('/login'),
                    child: const Text('Sou funcionário'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
