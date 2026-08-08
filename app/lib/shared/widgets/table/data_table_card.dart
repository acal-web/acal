import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:flutter/material.dart';

/// Horizontal gap between columns, used both by [DataTableCard]'s own header
/// and grid lines and by every feature page's row-builder [Row] — keeping
/// all three in lockstep is what keeps column boundaries aligned.
const columnSpacing = 12.0;

/// Minimum width given to a single flex unit when computing the table's
/// minimum content width — below this, cell text starts wrapping/overflowing
/// instead of just feeling cramped, which is what pushes the table into
/// horizontal scrolling on narrow (mobile) viewports.
const _flexUnitMinWidth = 80.0;

/// Matches the `EdgeInsets.symmetric(horizontal: 12)` used by [_Header],
/// [_ColumnGridLines], and every feature page's row [Padding].
const _horizontalContentPadding = 24.0;

/// The narrowest the table's columns are allowed to get before the table
/// switches from "shrink columns to fit" to "keep natural width and scroll
/// horizontally instead".
double _minContentWidth(List<DataTableColumn> columns) {
  final columnsWidth = columns.fold<double>(0, (sum, c) => sum + (c.width ?? c.flex * _flexUnitMinWidth));
  final spacing = columnSpacing * (columns.length - 1);
  return columnsWidth + spacing + _horizontalContentPadding;
}

class DataTableColumn {
  const DataTableColumn(this.label, {this.flex = 1, this.width, this.sortable = false, this.sortKey});

  final String label;
  final int flex;
  final double? width;
  final bool sortable;

  /// Field name sent to the server when this column is sorted, e.g. `'name'`.
  final String? sortKey;
}

/// The standard listing shell used across "Cadastros" pages: an entries-per-page
/// control, a sortable column header, a paginated list of rows, and a numbered
/// pagination bar — e.g. Logradouros, Sócios, Categorias.
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
    this.sortColumn,
    this.sortAscending = true,
    this.onSort,
    this.showFooter = false,
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

  /// [DataTableColumn.sortKey] of the currently active sort column, if any.
  final String? sortColumn;
  final bool sortAscending;

  /// Called with a sortable column's [DataTableColumn.sortKey] when its
  /// header is tapped. Toggling asc/desc for the active column is the
  /// caller's responsibility.
  final void Function(String sortKey)? onSort;

  /// Repeats the column labels as a footer row at the bottom of the table
  /// body, above the pagination bar — mirrors the classic DataTables.net
  /// layout. Defaults to off since most listing pages don't need it.
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardShape = Theme.of(context).cardTheme.shape;
    final borderRadius = cardShape is RoundedRectangleBorder ? cardShape.borderRadius : BorderRadius.zero;

    return Card(
      // Table rows zebra-stripe against the page ground, not the card fill —
      // override the card's default surface color to make that visible.
      color: Theme.of(context).scaffoldBackgroundColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = _minContentWidth(columns).clamp(constraints.maxWidth, double.infinity);

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  // No-op when width == constraints.maxWidth (the common desktop
                  // case) — only scrolls once columns hit their minimum width.
                  child: SizedBox(
                    width: width,
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            const Divider(height: 1),
                            _Header(
                              columns: columns,
                              sortColumn: sortColumn,
                              sortAscending: sortAscending,
                              onSort: onSort,
                            ),
                            const Divider(height: 1),
                            if (items.isEmpty)
                              Expanded(child: Center(child: Text(emptyMessage)))
                            else
                              Expanded(
                                child: ListView.builder(
                                  itemCount: items.length,
                                  itemBuilder: (context, i) => Column(
                                    children: [
                                      _HoverableRow(
                                        baseColor: i.isEven ? cs.surfaceContainerHigh.withValues(alpha: 0.35) : Colors.transparent,
                                        child: rowBuilder(context, items[i]),
                                      ),
                                      const Divider(height: 1),
                                    ],
                                  ),
                                ),
                              ),
                            // Pinned to the bottom, right above the pagination bar, so it
                            // stays put regardless of how many rows the current page has —
                            // rather than hugging the last row and jumping around per page.
                            if (showFooter) ...[
                              const Divider(height: 1),
                              _Footer(columns: columns),
                            ],
                          ],
                        ),
                        Positioned.fill(
                          child: IgnorePointer(child: _ColumnGridLines(columns: columns)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            color: cs.surface,
            child: _PaginationBar(
              pagination: pagination,
              itemCount: items.length,
              onPageChanged: onPageChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical separator lines between columns, overlaid across the header and
/// every row. Reuses each [DataTableColumn]'s flex/width exactly as
/// [_HeaderCell] does, so the lines land precisely on the cell boundaries
/// that the header and row builders already align to by convention.
class _ColumnGridLines extends StatelessWidget {
  const _ColumnGridLines({required this.columns});

  final List<DataTableColumn> columns;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: columnSpacing,
        children: [
          for (var i = 0; i < columns.length; i++) _cell(columns[i], color, isLast: i == columns.length - 1),
        ],
      ),
    );
  }

  Widget _cell(DataTableColumn column, Color color, {required bool isLast}) {
    final line = DecoratedBox(
      decoration: BoxDecoration(border: isLast ? null : Border(right: BorderSide(color: color))),
    );
    return column.width != null
        ? SizedBox(width: column.width, child: line)
        : Expanded(flex: column.flex, child: line);
  }
}

/// Highlights a row on mouse hover, blending a tint over its zebra-stripe
/// [baseColor] instead of replacing it, so the stripe stays visible through
/// the highlight.
class _HoverableRow extends StatefulWidget {
  const _HoverableRow({required this.baseColor, required this.child});

  final Color baseColor;
  final Widget child;

  @override
  State<_HoverableRow> createState() => _HoverableRowState();
}

class _HoverableRowState extends State<_HoverableRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovering ? Color.alphaBlend(cs.primary.withValues(alpha: 0.06), widget.baseColor) : widget.baseColor,
        child: widget.child,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.columns, this.sortColumn, this.sortAscending = true, this.onSort});

  final List<DataTableColumn> columns;
  final String? sortColumn;
  final bool sortAscending;
  final void Function(String sortKey)? onSort;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelLarge;
    return ColoredBox(
      color: cs.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          spacing: columnSpacing,
          children: [
            for (final column in columns)
              _HeaderCell(
                column: column,
                style: style,
                iconColor: cs.onSurfaceVariant,
                active: column.sortKey != null && column.sortKey == sortColumn,
                ascending: sortAscending,
                onSort: onSort,
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.column,
    this.style,
    required this.iconColor,
    required this.active,
    required this.ascending,
    this.onSort,
  });

  final DataTableColumn column;
  final TextStyle? style;
  final Color iconColor;
  final bool active;
  final bool ascending;
  final void Function(String sortKey)? onSort;

  @override
  Widget build(BuildContext context) {
    final label = column.sortable
        ? _SortableLabel(
            column.label,
            style: style,
            iconColor: iconColor,
            direction: active ? (ascending ? SortDirection.ascending : SortDirection.descending) : null,
            onTap: onSort == null || column.sortKey == null ? null : () => onSort!(column.sortKey!),
          )
        : Text(column.label, style: style);

    // Align so a sortable label's InkWell hugs just the text + arrows
    // instead of the whole (flex-stretched) cell — otherwise clicking
    // anywhere across the column's width, not just the label, triggers sort.
    final cell = Align(alignment: Alignment.centerLeft, child: label);

    return column.width != null
        ? SizedBox(width: column.width, child: cell)
        : Expanded(flex: column.flex, child: cell);
  }
}

/// Non-interactive repeat of [_Header]'s labels, used as the table's footer
/// when [DataTableCard.showFooter] is set — same flex/width per column as
/// [_HeaderCell] so it lines up with the grid lines and rows above it.
class _Footer extends StatelessWidget {
  const _Footer({required this.columns});

  final List<DataTableColumn> columns;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelLarge;
    return ColoredBox(
      color: cs.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          spacing: columnSpacing,
          children: [
            for (final column in columns)
              column.width != null
                  ? SizedBox(width: column.width, child: Text(column.label, style: style))
                  : Expanded(flex: column.flex, child: Text(column.label, style: style)),
          ],
        ),
      ),
    );
  }
}

enum SortDirection { ascending, descending }

class _SortableLabel extends StatelessWidget {
  const _SortableLabel(this.label, {this.style, required this.iconColor, this.direction, this.onTap});

  final String label;
  final TextStyle? style;
  final Color iconColor;

  /// Null when this column isn't the active sort column.
  final SortDirection? direction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: style),
        const SizedBox(width: 4),
        _SortArrows(color: iconColor, direction: direction),
      ],
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, mouseCursor: SystemMouseCursors.click, child: row);
  }
}

/// Stacked up/down carets, mirroring the DataTables-style sort indicator.
/// When [direction] names this column's active sort, the matching caret is
/// highlighted and the other dims; otherwise both render as a neutral hint.
class _SortArrows extends StatelessWidget {
  const _SortArrows({required this.color, this.direction});

  final Color color;
  final SortDirection? direction;

  @override
  Widget build(BuildContext context) {
    final upColor = direction == SortDirection.ascending ? color : color.withValues(alpha: 0.35);
    final downColor = direction == SortDirection.descending ? color : color.withValues(alpha: 0.35);

    return SizedBox(
      width: 10,
      height: 14,
      child: Stack(
        children: [
          Positioned(top: -3, child: Icon(Icons.arrow_drop_up, size: 16, color: upColor)),
          Positioned(bottom: -3, child: Icon(Icons.arrow_drop_down, size: 16, color: downColor)),
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

    final summary = Text(
      'Mostrando $start a $end de ${p.totalElements} registros',
      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
    );

    final controls = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
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
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < LayoutConfig.narrowBreakpoint) {
            return Column(
              children: [
                summary,
                const SizedBox(height: 8),
                controls,
              ],
            );
          }

          return Row(
            children: [
              summary,
              const Spacer(),
              controls,
            ],
          );
        },
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
