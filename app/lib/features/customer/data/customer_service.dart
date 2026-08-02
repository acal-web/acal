import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';

class CustomerService {
  CustomerService({HttpService? http}) : _http = http ?? HttpService();

  final HttpService _http;

  Future<PagedResult<Customer>> findAll({int page = 0, int size = 10, String? name, String? document}) async {
    final query = {
      'page': '$page',
      'size': '$size',
      if (name != null && name.isNotEmpty) 'name': name,
      if (document != null && document.isNotEmpty) 'document': document,
    };
    final data = await _http.get('/customers', query: query) as Map<String, dynamic>;
    return PagedResult.fromJson(data, Customer.fromJson);
  }

  Future<Customer> create(Customer customer) async {
    final data = await _http.post('/customers', customer.toJson());
    return Customer.fromJson(data as Map<String, dynamic>);
  }

  Future<Customer> update(Customer customer) async {
    final data = await _http.put('/customers/${customer.id}', customer.toJson());
    return Customer.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _http.delete('/customers/$id');
}
