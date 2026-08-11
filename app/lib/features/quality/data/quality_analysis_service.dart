import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/quality/domain/quality_analysis.dart';

class QualityAnalysisService {
  QualityAnalysisService({HttpService? http}) : _http = http ?? HttpService();

  final HttpService _http;

  Future<PagedResult<QualityAnalysis>> findAll({
    int page = 0,
    int size = 10,
    int? year,
    int? month,
    String? sort,
    bool sortAscending = true,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'size': '$size',
      if (year != null) 'year': '$year',
      if (month != null) 'month': '$month',
      if (sort != null) 'sort': sort,
      if (sort != null) 'direction': sortAscending ? 'asc' : 'desc',
    };
    final data = await _http.get('/quality_analyses', query: query) as Map<String, dynamic>;
    return PagedResult.fromJson(data, QualityAnalysis.fromJson);
  }

  Future<QualityAnalysis> create(QualityAnalysis analysis) async {
    final data = await _http.post('/quality_analyses', analysis.toJson());
    return QualityAnalysis.fromJson(data as Map<String, dynamic>);
  }

  Future<QualityAnalysis> update(QualityAnalysis analysis) async {
    final data = await _http.put('/quality_analyses/${analysis.id}', analysis.toJson());
    return QualityAnalysis.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _http.delete('/quality_analyses/$id');
}
