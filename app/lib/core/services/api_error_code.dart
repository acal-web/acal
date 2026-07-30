/// Mirrors the standardized `{"code": Integer, "message": String}` error
/// payload the Rails API renders for [ApiError] subclasses (see
/// `app/errors/` in the api project). Codes are the contract with the
/// backend — descriptions here are the pt-BR text shown in the UI.
enum ApiErrorCode {
  duplicateResource(1001, 'Já existe um registro com esses dados.');

  const ApiErrorCode(this.code, this.description);

  final int code;
  final String description;

  static ApiErrorCode? fromCode(int? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}
