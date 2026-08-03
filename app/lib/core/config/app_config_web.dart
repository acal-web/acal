import 'dart:js_interop';

@JS('API_BASE_URL')
external String? get _apiBaseUrl;

String get apiBaseUrl => _apiBaseUrl ?? 'http://localhost:3000';
