import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';

class CategoryService {
  CategoryService({HttpService? http}) : _http = http ?? HttpService();

  final HttpService _http;

  Future<PagedResult<Category>> findAll({
    int page = 0,
    int size = 10,
    String? name,
    bool? active = true,
    String? sort,
    bool sortAscending = true,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'size': '$size',
      'active': active == null ? 'all' : '$active',
      if (name?.isNotEmpty ?? false) 'name': name!,
      if (sort != null) 'sort': sort,
      if (sort != null) 'direction': sortAscending ? 'asc' : 'desc',
    };
    final data = await _http.get('/categories', query: query) as Map<String, dynamic>;
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
