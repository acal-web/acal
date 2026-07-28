import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';

class AddressService {
  AddressService({HttpService? http}) : _http = http ?? HttpService();

  final HttpService _http;

  Future<PagedResult<Address>> findAll({int page = 0}) async {
    final data = await _http.get('/addresses', query: {'page': '$page'}) as Map<String, dynamic>;
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

  Future<void> delete(int id) => _http.delete('/addresses/$id');
}
