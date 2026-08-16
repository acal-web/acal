import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/users/domain/user_model.dart';

class UsersService {
  final HttpService _httpService;

  UsersService({HttpService? httpService}) : _httpService = httpService ?? HttpService();

  Future<Map<String, dynamic>> listUsers({int page = 0, int size = 10}) async {
    final response = await _httpService.get(
      '/users',
      query: {'page': page.toString(), 'size': size.toString()},
    );
    return response;
  }

  Future<UserModel> getUser(String id) async {
    final response = await _httpService.get('/users/$id');
    return UserModel.fromJson(response);
  }

  Future<UserModel> createUser({
    required String username,
    required String name,
    required String password,
    required String role,
  }) async {
    final response = await _httpService.post(
      '/users',
      {
        'user': {
          'username': username,
          'name': name,
          'password': password,
          'role': role,
        }
      },
    );
    return UserModel.fromJson(response);
  }

  Future<UserModel> updateUser(
    String id, {
    required String name,
    required String role,
    String? password,
  }) async {
    final data = {
      'user': {
        'name': name,
        'role': role,
        if (password != null && password.isNotEmpty) 'password': password,
      }
    };
    final response = await _httpService.patch('/users/$id', data);
    return UserModel.fromJson(response);
  }

  Future<void> deleteUser(String id) async {
    await _httpService.delete('/users/$id');
  }

  Future<UserModel> restoreUser(String id) async {
    final response = await _httpService.patch('/users/$id/restore', {});
    return UserModel.fromJson(response);
  }
}
