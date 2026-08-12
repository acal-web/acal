import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/dashboard/domain/dashboard_summary.dart';

class DashboardService {
  DashboardService({HttpService? http}) : _http = http ?? HttpService();

  final HttpService _http;

  Future<DashboardSummary> summary({int? year, int? month}) async {
    final query = {
      if (year != null) 'year': '$year',
      if (month != null) 'month': '$month',
    };
    final data = await _http.get('/dashboard/summary', query: query) as Map<String, dynamic>;
    return DashboardSummary.fromJson(data);
  }
}
