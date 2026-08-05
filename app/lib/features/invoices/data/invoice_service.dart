import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/features/invoices/domain/invoice_candidate.dart';

class InvoiceService {
  InvoiceService({HttpService? http}) : _http = http ?? HttpService();

  final HttpService _http;

  Future<PagedResult<Invoice>> findAll({
    int page = 0,
    int size = 10,
    int? year,
    int? month,
  }) async {
    final query = {
      'page': '$page',
      'size': '$size',
      if (year != null) 'year': '$year',
      if (month != null) 'month': '$month',
    };
    final data = await _http.get('/invoices', query: query) as Map<String, dynamic>;
    return PagedResult.fromJson(data, Invoice.fromJson);
  }

  Future<List<InvoiceCandidate>> eligible({
    required DateTime reference,
    bool? hasWaterMeter,
    String? addressId,
  }) async {
    final query = {
      'reference_date': _formatDate(reference),
      if (hasWaterMeter != null) 'has_water_meter': '$hasWaterMeter',
      'address_id': ?addressId,
    };
    final data = await _http.get('/invoices/eligible', query: query) as List;
    return data.map((e) => InvoiceCandidate.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Invoice>> generate({
    required List<String> connectionIds,
    required DateTime reference,
    required DateTime dueDate,
  }) async {
    final data = await _http.post('/invoices/generate', {
      'connection_ids': connectionIds,
      'reference_date': _formatDate(reference),
      'due_date': _formatDate(dueDate),
    }) as List;
    return data.map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
