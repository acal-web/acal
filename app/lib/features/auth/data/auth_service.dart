import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/auth/domain/auth_user.dart';

class AuthService {
  static const _baseUrl = '/session';

  final HttpService _httpService;

  AuthService({HttpService? httpService}) : _httpService = httpService ?? HttpService();

  Future<({String token, AuthUser user})> login(String username, String password) async {
    final response = await _httpService.post(
      _baseUrl,
      {
        'session': {
          'username': username,
          'password': password,
        }
      },
    );

    final token = response['token'] as String;
    final user = AuthUser.fromJson(response['user'] as Map<String, dynamic>);

    return (token: token, user: user);
  }

  Future<void> logout() async {
    try {
      await _httpService.delete(_baseUrl);
    } catch (_) {
      // Ignore errors during logout
    }
  }

  Future<AuthUser> fetchCurrentUser() async {
    final response = await _httpService.get('/me');
    return AuthUser.fromJson(response);
  }
}
