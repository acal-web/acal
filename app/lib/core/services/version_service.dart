import 'package:acalapp/core/services/http_service.dart';

class VersionService {
  VersionService({HttpService? http}) : _http = http ?? HttpService();

  final HttpService _http;

  Future<String> apiVersion() async {
    final data = await _http.get('/version') as Map<String, dynamic>;
    return data['version'] as String;
  }
}
