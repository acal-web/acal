import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/notifications/domain/app_notification.dart';

class NotificationService {
  NotificationService({HttpService? http}) : _http = http ?? HttpService();

  final HttpService _http;

  Future<PagedResult<AppNotification>> findAll({int page = 0, int size = 20}) async {
    final query = <String, String>{'page': '$page', 'size': '$size'};
    final data = await _http.get('/notifications', query: query) as Map<String, dynamic>;
    return PagedResult.fromJson(data, AppNotification.fromJson);
  }

  Future<int> recipientsCount({String? addressId, String? categoryId, String? status}) async {
    final query = <String, String>{
      'address_id': ?addressId,
      'category_id': ?categoryId,
      'status': ?status,
    };
    final data = await _http.get('/notifications/recipients_count', query: query) as Map<String, dynamic>;
    return data['count'] as int;
  }

  Future<AppNotification> send({
    required String title,
    required String body,
    String? addressId,
    String? categoryId,
    String? status,
  }) async {
    final data = await _http.post('/notifications', {
      'notification': {
        'title': title,
        'body': body,
        'address_id': addressId,
        'category_id': categoryId,
        'status': status,
      },
    }) as Map<String, dynamic>;
    return AppNotification.fromJson(data);
  }
}
