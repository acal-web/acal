import 'package:acalapp/features/auth/domain/user_role.dart';
import 'package:acalapp/features/users/data/users_service.dart';
import 'package:acalapp/features/users/domain/user_model.dart';
import 'package:acalapp/shared/widgets/toast/app_toast.dart';
import 'package:flutter/material.dart';

class UserFormPage extends StatefulWidget {
  final UserModel? user;
  final UsersService? usersService;

  const UserFormPage({super.key, this.user, this.usersService});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  late UsersService _usersService;
  late TextEditingController _usernameController;
  late TextEditingController _nameController;
  late TextEditingController _passwordController;
  late UserRole _selectedRole;

  bool _isLoading = false;
  bool _isCreating = true;

  @override
  void initState() {
    super.initState();
    _usersService = widget.usersService ?? UsersService();
    _isCreating = widget.user == null;

    _usernameController = TextEditingController(text: widget.user?.username ?? '');
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _passwordController = TextEditingController();
    _selectedRole = widget.user?.role ?? UserRole.administrador;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_usernameController.text.isEmpty ||
        _nameController.text.isEmpty ||
        (_isCreating && _passwordController.text.isEmpty)) {
      AppToast.error(context, 'Preencha todos os campos obrigatórios');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isCreating) {
        await _usersService.createUser(
          username: _usernameController.text,
          name: _nameController.text,
          password: _passwordController.text,
          role: _selectedRole.value,
        );
        if (mounted) {
          AppToast.success(context, 'Usuário criado com sucesso');
          Navigator.pop(context, true);
        }
      } else {
        await _usersService.updateUser(
          widget.user!.id,
          name: _nameController.text,
          role: _selectedRole.value,
          password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
        );
        if (mounted) {
          AppToast.success(context, 'Usuário atualizado com sucesso');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Erro ao salvar usuário');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreating ? 'Novo Usuário' : 'Editar Usuário'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              enabled: _isCreating && !_isLoading,
              decoration: InputDecoration(
                labelText: 'Usuário',
                hintText: 'user123',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Nome Completo',
                hintText: 'João Silva',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: _isCreating ? 'Senha' : 'Nova Senha (deixe em branco para não alterar)',
                hintText: '••••••••',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserRole>(
              initialValue: _selectedRole,
              onChanged: _isLoading ? null : (value) => setState(() => _selectedRole = value!),
              decoration: InputDecoration(
                labelText: 'Papel',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.security),
              ),
              // "customer" isn't a role staff can assign here — those accounts
              // are only ever provisioned automatically from a Customer record.
              items: UserRole.values
                  .where((role) => role != UserRole.customer)
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(_roleLabel(role.value)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _handleSave,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isCreating ? 'Criar Usuário' : 'Atualizar Usuário'),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'administrador':
        return 'Administrador';
      case 'financeiro_secretaria':
        return 'Financeiro/Secretaria';
      case 'tesoureiro':
        return 'Tesoureiro';
      default:
        return role;
    }
  }
}
