/// The single message every required field shows when left blank.
const requiredFieldMessage = 'Obrigatório';

/// Validator for required text fields — whitespace alone doesn't count as filled.
String? validateRequired(String? value) =>
    (value == null || value.trim().isEmpty) ? requiredFieldMessage : null;
