import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/connections/domain/connection.dart';

class ConnectionService {
  ConnectionService({HttpService? http}) : _http = http ?? HttpService();

  final HttpService _http;

  Future<PagedResult<Connection>> findAll({
    int page = 0,
    int size = 10,
    String? customerId,
    String? customerName,
    String? customerDocument,
    String? addressName,
    String? categoryId,
    bool? active,
    String? sortBy,
    String? sortDirection,
  }) async {
    final query = {
      'page': '$page',
      'size': '$size',
      if (customerId != null && customerId.isNotEmpty) 'customer_id': customerId,
      if (customerName != null && customerName.isNotEmpty) 'customer_name': customerName,
      if (customerDocument != null && customerDocument.isNotEmpty) 'customer_document': customerDocument,
      if (addressName != null && addressName.isNotEmpty) 'address_name': addressName,
      if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
      if (active != null) 'active': '$active',
      if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
      if (sortDirection != null && sortDirection.isNotEmpty) 'sort_direction': sortDirection,
    };
    final data = await _http.get('/connections', query: query) as Map<String, dynamic>;
    return PagedResult.fromJson(data, Connection.fromJson);
  }

  Future<Connection> create(Connection connection) async {
    final data = await _http.post('/connections', connection.toJson());
    return Connection.fromJson(data as Map<String, dynamic>);
  }

  Future<Connection> update(Connection connection) async {
    final data = await _http.put('/connections/${connection.id}', connection.toJson());
    return Connection.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _http.delete('/connections/$id');
}
