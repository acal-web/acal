enum UserRole {
  administrador('administrador'),
  financeiroSecretaria('financeiro_secretaria'),
  tesoureiro('tesoureiro'),
  customer('customer');

  final String value;
  const UserRole(this.value);

  static UserRole? fromValue(String? value) {
    for (final role in UserRole.values) {
      if (role.value == value) return role;
    }
    return null;
  }
}
