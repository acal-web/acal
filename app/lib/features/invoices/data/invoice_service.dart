import 'dart:typed_data';

import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/features/invoices/domain/invoice_candidate.dart';
import 'package:acalapp/features/invoices/domain/overdue_connection.dart';

class InvoiceService {
  InvoiceService({HttpService? http}) : _http = http ?? HttpService();

  final HttpService _http;

  Future<PagedResult<Invoice>> findAll({
    int page = 0,
    int size = 10,
    int? year,
    int? month,
    String? customerId,
    String? addressId,
    String? status,
    String? sortBy,
    bool? sortAscending,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'size': '$size',
      if (year != null) 'year': '$year',
      if (month != null) 'month': '$month',
      'customer_id': ?customerId,
      'address_id': ?addressId,
      'status': ?status,
      if (sortBy != null) 'sort_by': sortBy,
      if (sortAscending != null) 'sort_ascending': '$sortAscending',
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

  Future<Uint8List> pdf(String invoiceId) => _http.getBytes('/invoices/$invoiceId/pdf');

  Future<Invoice> markPaid(String invoiceId) async {
    final data = await _http.patch('/invoices/$invoiceId/pay', {}) as Map<String, dynamic>;
    return Invoice.fromJson(data);
  }

  Future<List<OverdueConnection>> overdue({int? days}) async {
    final query = {if (days != null) 'days': '$days'};
    final data = await _http.get('/invoices/overdue', query: query) as List;
    return data.map((e) => OverdueConnection.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Uint8List> cobrancaPdf({String? connectionId, int? days}) => _http.getBytes(
        '/invoices/cobranca_pdf',
        query: {
          'connection_id': ?connectionId,
          if (days != null) 'days': '$days',
        },
      );

  Future<Uint8List> printFiltered({
    int? year,
    int? month,
    String? customerId,
    String? addressId,
    String? status,
  }) => _http.getBytes(
        '/invoices/print_filtered',
        query: {
          if (year != null) 'year': '$year',
          if (month != null) 'month': '$month',
          'customer_id': ?customerId,
          'address_id': ?addressId,
          'status': ?status,
        },
      );

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
