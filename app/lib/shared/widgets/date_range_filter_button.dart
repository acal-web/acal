import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// A "Filtrar por Período" button for an arbitrary date range — opens the
/// native Material date range picker and reports the chosen range, or null
/// for "todos os períodos". Mirrors `PeriodFilterButton`, but for a start/end
/// range instead of a closed month/year.
class DateRangeFilterButton extends StatelessWidget {
  const DateRangeFilterButton({super.key, required this.range, required this.onChanged});

  final DateTimeRange? range;
  final ValueChanged<DateTimeRange?> onChanged;

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final r = range;
    final label = r == null ? 'Todos os períodos' : '${_formatDate(r.start)} - ${_formatDate(r.end)}';

    return FButton(
      variant: FButtonVariant.outline,
      mainAxisSize: MainAxisSize.min,
      onPress: () async {
        final now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          initialDateRange: r,
          firstDate: DateTime(now.year - 20),
          lastDate: DateTime(now.year + 3, 12),
        );
        if (picked != null) onChanged(picked);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [const Icon(Icons.calendar_today, size: 18), const SizedBox(width: 8), Text(label)],
      ),
    );
  }
}
