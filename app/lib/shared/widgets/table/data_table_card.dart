import 'package:acalapp/core/models/pagination.dart';
import 'package:flutter/material.dart';

class DataTableColumn {
  const DataTableColumn(this.label, {this.flex = 1, this.width, this.sortable = false});

  final String label;
  final int flex;
  final double? width;
  final bool sortable;
}

/// The standard listing shell used across "Cadastros" pages: an entries-per-page
/// control, a sortable column header, a paginated list of rows, a footer that
/// mirrors the header, and a numbered pagination bar — e.g. Logradouros,
/// Sócios, Categorias.
class DataTableCard<T> extends StatelessWidget {
  const DataTableCard({
    super.key,
    required this.columns,
    required this.items,
    required this.rowBuilder,
    required this.pagination,
    required this.onPageChanged,
    required this.pageSize,
    required this.onPageSizeChanged,
    this.pageSizeOptions = const [10, 25, 50, 100],
    this.emptyMessage = 'Nenhum registro encontrado.',
  });

  final List<DataTableColumn> columns;
  final List<T> items;
  final Widget Function(BuildContext context, T item) rowBuilder;
  final Pagination pagination;
  final void Function(int page) onPageChanged;
  final int pageSize;
  final void Function(int size) onPageSizeChanged;
  final List<int> pageSizeOptions;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      // Table rows zebra-stripe against the page ground, not the card fill —
      // override the card's default surface color to make that visible.
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _EntriesPerPage(
            value: pageSize,
            options: pageSizeOptions,
            onChanged: onPageSizeChanged,
          ),
          const Divider(height: 1),
          _Header(columns: columns),
          const Divider(height: 1),
          if (items.isEmpty)
            Expanded(child: Center(child: Text(emptyMessage)))
          else
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) => Container(
                  color: i.isEven ? cs.surface : Colors.transparent,
                  child: rowBuilder(context, items[i]),
                ),
              ),
            ),
          const Divider(height: 1),
          _Footer(columns: columns),
          const Divider(height: 1),
          _PaginationBar(
            pagination: pagination,
            itemCount: items.length,
            onPageChanged: onPageChanged,
          ),
        ],
      ),
    );
  }
}

class _EntriesPerPage extends StatelessWidget {
  const _EntriesPerPage({required this.value, required this.options, required this.onChanged});

  final int value;
  final List<int> options;
  final void Function(int size) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              items: [
                for (final size in options)
                  DropdownMenuItem(value: size, child: Text('$size')),
              ],
              onChanged: (size) {
                if (size != null) onChanged(size);
              },
              borderRadius: BorderRadius.zero,
              style: theme.textTheme.bodyMedium,
              icon: Icon(Icons.arrow_drop_down, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          Text('registros por página', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.columns});

  final List<DataTableColumn> columns;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Small caps of the body face, per the design system's .table th rule.
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onSecondary,
          letterSpacing: 0.88,
        );
    return Container(
      color: cs.secondary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (final column in columns)
            _HeaderCell(column: column, style: style, iconColor: cs.onSecondary),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.column, this.style, required this.iconColor});

  final DataTableColumn column;
  final TextStyle? style;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final text = column.label.toUpperCase();
    final label = column.sortable
        ? _SortableLabel(text, style: style, iconColor: iconColor)
        : Text(text, style: style);

    return column.width != null
        ? SizedBox(width: column.width, child: label)
        : Expanded(flex: column.flex, child: label);
  }
}

class _SortableLabel extends StatelessWidget {
  const _SortableLabel(this.label, {this.style, required this.iconColor});

  final String label;
  final TextStyle? style;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: style),
        const SizedBox(width: 4),
        _SortArrows(color: iconColor),
      ],
    );
  }
}

/// Stacked up/down carets, mirroring the DataTables-style sort indicator.
class _SortArrows extends StatelessWidget {
  const _SortArrows({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 14,
      child: Stack(
        children: [
          Positioned(top: -3, child: Icon(Icons.arrow_drop_up, size: 16, color: color)),
          Positioned(bottom: -3, child: Icon(Icons.arrow_drop_down, size: 16, color: color)),
        ],
      ),
    );
  }
}

/// Repeats the column labels below the rows, per the reference table's footer.
class _Footer extends StatelessWidget {
  const _Footer({required this.columns});

  final List<DataTableColumn> columns;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (final column in columns)
            column.width != null
                ? SizedBox(width: column.width, child: Text(column.label, style: style))
                : Expanded(flex: column.flex, child: Text(column.label, style: style)),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.pagination,
    required this.itemCount,
    required this.onPageChanged,
  });

  final Pagination pagination;
  final int itemCount;
  final void Function(int) onPageChanged;

  /// A sliding window of page indices to render, with `null` marking an
  /// elided gap — keeps the bar from growing unbounded on large result sets.
  List<int?> _window(int totalPages, int current) {
    if (totalPages <= 7) return List.generate(totalPages, (i) => i);

    final pages = <int>{0, totalPages - 1};
    for (var p = current - 1; p <= current + 1; p++) {
      if (p >= 0 && p < totalPages) pages.add(p);
    }
    final sorted = pages.toList()..sort();

    final result = <int?>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) result.add(null);
      result.add(sorted[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final p = pagination;

    final start = itemCount == 0 ? 0 : p.number * p.size + 1;
    final end = p.number * p.size + itemCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Mostrando $start a $end de ${p.totalElements} registros',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const Spacer(),
          _PageArrow(
            icon: Icons.keyboard_double_arrow_left,
            onPressed: p.first ? null : () => onPageChanged(0),
          ),
          _PageArrow(
            icon: Icons.chevron_left,
            onPressed: p.prevPage != null ? () => onPageChanged(p.prevPage!) : null,
          ),
          for (final page in _window(p.totalPages, p.number))
            page == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('…', style: theme.textTheme.bodySmall),
                  )
                : _PageNumber(
                    number: page + 1,
                    selected: page == p.number,
                    onTap: () => onPageChanged(page),
                  ),
          _PageArrow(
            icon: Icons.chevron_right,
            onPressed: p.nextPage != null ? () => onPageChanged(p.nextPage!) : null,
          ),
          _PageArrow(
            icon: Icons.keyboard_double_arrow_right,
            onPressed: p.last ? null : () => onPageChanged(p.totalPages - 1),
          ),
        ],
      ),
    );
  }
}

class _PageArrow extends StatelessWidget {
  const _PageArrow({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}

class _PageNumber extends StatelessWidget {
  const _PageNumber({required this.number, required this.selected, required this.onTap});

  final int number;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: selected ? null : onTap,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          color: selected ? cs.primary : Colors.transparent,
          child: Text(
            '$number',
            style: theme.textTheme.bodySmall?.copyWith(
              color: selected ? cs.onPrimary : cs.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
