import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

class CategorySelectField extends StatefulWidget {
  const CategorySelectField({
    super.key,
    required this.categoryService,
    this.initialValue,
    required this.onSelected,
    this.label = 'Categoria',
    this.validator,
  });

  final CategoryService categoryService;
  final Category? initialValue;
  final ValueChanged<Category?> onSelected;
  final String label;
  final FormFieldValidator<Category>? validator;

  @override
  State<CategorySelectField> createState() => _CategorySelectFieldState();
}

class _CategorySelectFieldState extends State<CategorySelectField> {
  late final Future<List<Category>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.categoryService.findAll(size: 500).then((r) => r.data);
  }

  List<FSelectItemMixin> _sections(List<Category> categories) {
    final sorted = [...categories]..sort((a, b) {
        final byGroup = groups.indexOf(a.group).compareTo(groups.indexOf(b.group));
        return byGroup != 0 ? byGroup : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final byGroup = <String, List<Category>>{};
    for (final category in sorted) {
      byGroup.putIfAbsent(category.group, () => []).add(category);
    }

    return [
      for (final entry in byGroup.entries)
        FSelectSection<Category>(
          label: Text(groupLabel(entry.key)),
          items: {for (final category in entry.value) category.name: category},
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Category>>(
      future: _future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;

        return FSelect<Category>.rich(
          format: (c) => '${groupLabel(c.group)} - ${c.name}',
          control: FSelectControl.managed(initial: widget.initialValue, onChange: widget.onSelected),
          label: Text(widget.label),
          hint: loading ? 'Carregando...' : 'Selecione a categoria',
          enabled: !loading,
          validator: widget.validator ?? (_) => null,
          children: loading ? const [] : _sections(snapshot.data!),
        );
      },
    );
  }
}
