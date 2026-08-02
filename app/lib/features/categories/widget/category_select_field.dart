import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/shared/widgets/labeled_field.dart';
import 'package:flutter/material.dart';

class CategorySelectField extends FormField<Category> {
  CategorySelectField({
    super.key,
    required this.categoryService,
    super.initialValue,
    required this.onSelected,
    this.label = 'Categoria',
    super.validator,
  }) : super(builder: (field) => (field as _CategorySelectFieldState)._build(field.context));

  final CategoryService categoryService;
  final ValueChanged<Category?> onSelected;
  final String label;

  @override
  FormFieldState<Category> createState() => _CategorySelectFieldState();
}

class _CategorySelectFieldState extends FormFieldState<Category> {
  late final Future<List<Category>> _future;

  @override
  CategorySelectField get widget => super.widget as CategorySelectField;

  @override
  void initState() {
    super.initState();
    _future = widget.categoryService.findAll(size: 500).then((r) => r.data);
  }

  DropdownMenuEntry<Category> _headerEntry(BuildContext context, String group) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return DropdownMenuEntry(
      value: Category(name: groupLabel(group), group: group, hasWaterMeter: false, waterPrice: 0, membershipPrice: 0),
      label: groupLabel(group),
      enabled: false,
      labelWidget: Text(groupLabel(group), style: style),
      style: MenuItemButton.styleFrom(
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  List<DropdownMenuEntry<Category>> _entries(BuildContext context, List<Category> categories) {
    final sorted = [...categories]..sort((a, b) {
        final byGroup = groups.indexOf(a.group).compareTo(groups.indexOf(b.group));
        return byGroup != 0 ? byGroup : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    String? currentGroup;
    return [
      for (final category in sorted) ...[
        if (category.group != currentGroup) _headerEntry(context, currentGroup = category.group),
        DropdownMenuEntry(
          value: category,
          // The list row just shows the name (it's already under its group
          // header), but `label` is what fills the field once selected —
          // show the group there too so the closed field isn't ambiguous.
          label: '${groupLabel(category.group)} - ${category.name}',
          labelWidget: Text(category.name),
        ),
      ],
    ];
  }

  Widget _build(BuildContext context) {
    return FutureBuilder<List<Category>>(
      future: _future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final entries = loading ? const <DropdownMenuEntry<Category>>[] : _entries(context, snapshot.data!);

        return LabeledField(
          label: widget.label,
          child: DropdownMenu<Category>(
            enabled: !loading,
            initialSelection: value,
            expandedInsets: EdgeInsets.zero,
            selectOnly: true,
            hintText: loading ? 'Carregando...' : 'Selecione a categoria',
            errorText: hasError ? errorText : null,
            dropdownMenuEntries: entries,
            onSelected: (category) {
              didChange(category);
              widget.onSelected(category);
            },
          ),
        );
      },
    );
  }
}
