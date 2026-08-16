import 'package:acalapp/features/users/data/users_service.dart';
import 'package:acalapp/features/users/domain/user_model.dart';
import 'package:acalapp/features/users/presentation/user_form_page.dart';
import 'package:acalapp/shared/widgets/toast/app_toast.dart';
import 'package:flutter/material.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key, this.usersService});

  final UsersService? usersService;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late UsersService _usersService;
  List<UserModel> _users = [];
  bool _isLoading = false;
  final int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _usersService = widget.usersService ?? UsersService();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _usersService.listUsers(page: _currentPage);
      final content = response['content'] as List?;
      setState(() {
        _users = (content ?? []).map((item) => UserModel.fromJson(item)).toList();
      });
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Erro ao carregar usuários');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Tem certeza que deseja excluir o usuário "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _usersService.deleteUser(user.id);
      if (mounted) {
        AppToast.success(context, 'Usuário excluído com sucesso');
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Erro ao excluir usuário');
      }
    }
  }

  Future<void> _restoreUser(UserModel user) async {
    try {
      await _usersService.restoreUser(user.id);
      if (mounted) {
        AppToast.success(context, 'Usuário restaurado com sucesso');
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Erro ao restaurar usuário');
      }
    }
  }

  void _openUserForm({UserModel? user}) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => UserFormPage(user: user, usersService: _usersService),
      ),
    ).then((refresh) {
      if (refresh == true) _loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Usuários'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.icon(
              onPressed: () => _openUserForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Novo'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum usuário encontrado',
                          style: theme.textTheme.bodyMedium?.copyWith(color: cs.outline),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    user.isActive ? cs.primary : cs.outline.withValues(alpha: 0.5),
                                child: Text(
                                  user.username[0].toUpperCase(),
                                  style: TextStyle(
                                    color: user.isActive ? cs.onPrimary : cs.outline,
                                  ),
                                ),
                              ),
                              title: Text(user.name),
                              subtitle: Row(
                                children: [
                                  Text(user.username),
                                  const SizedBox(width: 12),
                                  Chip(
                                    label: Text(_roleLabel(user.role.value)),
                                    labelStyle: theme.textTheme.labelSmall,
                                    padding: EdgeInsets.zero,
                                  ),
                                  if (!user.isActive) ...[
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: const Text('Inativo'),
                                      labelStyle: theme.textTheme.labelSmall?.copyWith(
                                        color: cs.error,
                                      ),
                                      backgroundColor: cs.error.withValues(alpha: 0.1),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _openUserForm(user: user);
                                  } else if (value == 'delete') {
                                    _deleteUser(user);
                                  } else if (value == 'restore') {
                                    _restoreUser(user);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 18),
                                        SizedBox(width: 12),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  if (user.isActive)
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 18, color: cs.error),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Excluir',
                                            style: TextStyle(color: cs.error),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    PopupMenuItem(
                                      value: 'restore',
                                      child: Row(
                                        children: [
                                          Icon(Icons.restore, size: 18, color: cs.primary),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Restaurar',
                                            style: TextStyle(color: cs.primary),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
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
