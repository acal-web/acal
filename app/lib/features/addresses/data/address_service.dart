import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';

class AddressService {
  AddressService({HttpService? http}) : _http = http ?? HttpService();

  final HttpService _http;

  Future<PagedResult<Address>> findAll({
    int page = 0,
    int size = 10,
    String? name,
    String? kind,
    bool? active = true,
  }) async {
    final query = {
      'page': '$page',
      'size': '$size',
      if (name != null && name.isNotEmpty) 'name': name,
      if (kind != null && kind.isNotEmpty) 'kind': kind,
      'active': active == null ? 'all' : '$active',
    };
    final data = await _http.get('/addresses', query: query) as Map<String, dynamic>;
    return PagedResult.fromJson(data, Address.fromJson);
  }

  Future<Address> create(Address address) async {
    final data = await _http.post('/addresses', address.toJson());
    return Address.fromJson(data as Map<String, dynamic>);
  }

  Future<Address> update(Address address) async {
    final data = await _http.put('/addresses/${address.id}', address.toJson());
    return Address.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _http.delete('/addresses/$id');
}
