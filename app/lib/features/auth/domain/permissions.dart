import 'package:acalapp/features/auth/domain/user_role.dart';

class Permissions {
  static bool canManageUsers(UserRole? role) {
    return role == UserRole.administrador;
  }

  static bool canManageCadastro(UserRole? role) {
    return role == UserRole.administrador || role == UserRole.financeiroSecretaria;
  }

  static bool canGenerateInvoices(UserRole? role) {
    return role == UserRole.administrador || role == UserRole.financeiroSecretaria;
  }

  static bool canPayInvoices(UserRole? role) {
    return role == UserRole.administrador ||
        role == UserRole.financeiroSecretaria ||
        role == UserRole.tesoureiro;
  }

  static bool canViewMenuSection(UserRole? role, String section) {
    if (role == null) return false;

    switch (section) {
      case 'cadastros':
        return true; // Todos podem ver/ler cadastros
      case 'agua':
        return true; // Todos podem ver água
      case 'financeiro':
        return true; // Todos podem ver faturas
      case 'admin':
        return role == UserRole.administrador; // Só admin vê admin
      case 'development':
        return false; // Nunca mostrar em produção
      default:
        return false;
    }
  }

  static bool canAccessRoute(UserRole? role, String path) {
    if (role == null) return false;

    switch (path) {
      // Cadastros - leitura para todos, escrita para admin + financeiro
      case '/customers':
      case '/addresses':
      case '/categories':
      case '/connections':
      case '/quality':
        return true;

      // Faturas - leitura para todos
      case '/invoices':
      case '/invoices/cobranca':
        return true;

      // Gerar faturas - só admin + financeiro
      case '/invoices/generate':
        return canGenerateInvoices(role);

      // Admin - só admin
      case '/elections':
      case '/documentation':
        return role == UserRole.administrador;

      // Sempre acessível
      case '/dashboard':
      case '/cashbox':
        return true;

      default:
        return false;
    }
  }
}
