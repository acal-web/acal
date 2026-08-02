import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';

class CategoryService {
  CategoryService({HttpService? http}) : _http = http ?? HttpService();

  final HttpService _http;

  Future<PagedResult<Category>> findAll({int page = 0, int size = 10}) async {
    final data = await _http.get('/categories', query: {'page': '$page', 'size': '$size'})
        as Map<String, dynamic>;
    return PagedResult.fromJson(data, Category.fromJson);
  }

  Future<Category> create(Category category) async {
    final data = await _http.post('/categories', category.toJson());
    return Category.fromJson(data as Map<String, dynamic>);
  }

  Future<Category> update(Category category) async {
    final data = await _http.put('/categories/${category.id}', category.toJson());
    return Category.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _http.delete('/categories/$id');
}
