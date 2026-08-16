enum UserRole {
  administrador('administrador'),
  financeiroSecretaria('financeiro_secretaria'),
  tesoureiro('tesoureiro');

  final String value;
  const UserRole(this.value);

  static UserRole? fromValue(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.administrador,
    );
  }
}
