final _nonDigits = RegExp(r'[^0-9]');

/// Strips every non-digit character. Documents and money are masked on screen
/// but stored, parsed and sent to the API as bare digits.
String onlyDigits(String value) => value.replaceAll(_nonDigits, '');
