import 'package:acalapp/features/customer_portal/data/portal_http_service.dart';
import 'package:acalapp/features/customer_portal/domain/customer_auth_user.dart';

class CustomerAuthService {
  static const _baseUrl = '/portal/session';

  final PortalHttpService _httpService;

  CustomerAuthService({PortalHttpService? httpService}) : _httpService = httpService ?? PortalHttpService();

  Future<({String token, CustomerAuthUser customer})> login(String document, String customerCode) async {
    final response = await _httpService.post(
      _baseUrl,
      {
        'session': {
          'document': document,
          'customer_code': customerCode,
        }
      },
    );

    final token = response['token'] as String;
    final customer = CustomerAuthUser.fromJson(response['customer'] as Map<String, dynamic>);

    return (token: token, customer: customer);
  }

  Future<void> logout() async {
    try {
      await _httpService.delete(_baseUrl);
    } catch (_) {
      // Ignore errors during logout
    }
  }

  Future<CustomerAuthUser> fetchCurrentCustomer() async {
    final response = await _httpService.get('/portal/me');
    return CustomerAuthUser.fromJson(response as Map<String, dynamic>);
  }
}
