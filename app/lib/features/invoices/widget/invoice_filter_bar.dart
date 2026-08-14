import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/shared/widgets/period_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class InvoiceFilterBar extends StatefulWidget {
  const InvoiceFilterBar({super.key, required this.onSearch});

  final void Function({MonthYear? period}) onSearch;

  @override
  State<InvoiceFilterBar> createState() => _InvoiceFilterBarState();
}

class _InvoiceFilterBarState extends State<InvoiceFilterBar> {
  MonthYear? _period;
  bool _expanded = false;

  void _search() => widget.onSearch(period: _period);

  void _clear() {
    setState(() => _period = null);
    widget.onSearch(period: null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < LayoutConfig.narrowBreakpoint;

        final periodField = FSelect<MonthYear?>(
          items: {
            'Todos os períodos': null,
            ...Map.fromEntries(
              List.generate(12, (i) {
                final now = DateTime.now();
                final month = now.month - i;
                final year = now.year - (month <= 0 ? 1 : 0);
                final adjustedMonth = month <= 0 ? month + 12 : month;
                final period = (month: adjustedMonth, year: year);
                return MapEntry(
                  _formatMonthYear(period),
                  period,
                );
              }).reversed,
            ),
          },
          control: FSelectControl.managed(
            initial: _period,
            onChange: (v) => setState(() => _period = v),
          ),
          label: const Text('Período'),
        );

        final searchButtonNarrow = Expanded(
          child: FButton(
            onPress: _search,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.search, size: 18), SizedBox(width: 8), Text('Consultar')],
            ),
          ),
        );

        final clearButtonNarrow = Expanded(
          child: FButton(
            variant: FButtonVariant.outline,
            onPress: _clear,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.clear, size: 18), SizedBox(width: 8), Text('Limpar')],
            ),
          ),
        );

        final searchButtonWide = SizedBox(
          child: FButton(
            onPress: _search,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.search, size: 18), SizedBox(width: 8), Text('Consultar')],
            ),
          ),
        );

        final clearButtonWide = SizedBox(
          child: FButton(
            variant: FButtonVariant.outline,
            onPress: _clear,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.clear, size: 18), SizedBox(width: 8), Text('Limpar')],
            ),
          ),
        );

        final fields = narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  periodField,
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      clearButtonNarrow,
                      const SizedBox(width: 8),
                      searchButtonNarrow,
                    ],
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: periodField),
                      const SizedBox(width: 8),
                      const Spacer(flex: 6),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  Row(
                    children: [
                      const Spacer(),
                      Expanded(flex: 2, child: clearButtonWide),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: searchButtonWide),
                    ],
                  ),
                ],
              );

        final cs = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColoredBox(
              color: cs.surfaceContainerHigh,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: const Icon(Icons.expand_more, size: 20),
                      ),
                      const SizedBox(width: 4),
                      Text('Filtros', style: Theme.of(context).textTheme.labelLarge),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: !_expanded
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Card(
                          elevation: 1,
                          margin: EdgeInsets.zero,
                          color: cs.surfaceContainerHigh,
                          surfaceTintColor: Colors.transparent,
                          child: Padding(
                            padding: LayoutConfig.pagePadding(narrow),
                            child: fields,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  String _formatMonthYear(MonthYear period) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${months[period.month - 1]} de ${period.year}';
  }
}
