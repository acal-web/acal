/// An atomic permission unit ("module:feature:action"), e.g. `invoices:payment:execute`.
/// The server is still the source of truth for enforcement — this is only used
/// to drive client-side UI (menu visibility, buttons, route access).
class PermissionCode {
  const PermissionCode(this.module, this.feature, this.action);

  final String module;
  final String feature;
  final String action;

  String get code => '$module:$feature:$action';

  @override
  bool operator ==(Object other) => other is PermissionCode && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}
