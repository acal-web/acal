import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/connections/domain/connection.dart';
import 'package:acalapp/features/connections/domain/connection_filter.dart';

class ConnectionService {
  ConnectionService({HttpService? http}) : _http = http ?? HttpService();

  final HttpService _http;

  Future<PagedResult<Connection>> findAll({
    int page = 0,
    int size = 10,
    ConnectionFilter filter = const ConnectionFilter(),
    String? sortBy,
    String? sortDirection,
  }) async {
    final query = {
      'page': '$page',
      'size': '$size',
      ...filter.toQuery(),
      'sort_by': ?blankToNull(sortBy),
      'sort_direction': ?blankToNull(sortDirection),
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
