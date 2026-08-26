import 'dart:typed_data';

import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/features/customer_portal/data/portal_http_service.dart';
import 'package:acalapp/features/invoices/domain/invoice.dart';

/// Fetches only the authenticated customer's own invoices — the backend
/// (`Portal::InvoicesController`) scopes every query to the token's
/// `customer_id`, so there's no `customerId` param to pass here.
class CustomerInvoiceService {
  CustomerInvoiceService({PortalHttpService? http}) : _http = http ?? PortalHttpService();

  final PortalHttpService _http;

  Future<PagedResult<Invoice>> findAll({int page = 0, int size = 10}) async {
    final query = {'page': '$page', 'size': '$size'};
    final data = await _http.get('/portal/invoices', query: query) as Map<String, dynamic>;
    return PagedResult.fromJson(data, Invoice.fromJson);
  }

  Future<Invoice> getById(String invoiceId) async {
    final data = await _http.get('/portal/invoices/$invoiceId') as Map<String, dynamic>;
    return Invoice.fromJson(data);
  }

  Future<Uint8List> pdf(String invoiceId) => _http.getBytes('/portal/invoices/$invoiceId/pdf');
}
