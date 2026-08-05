import 'package:acalapp/shared/formatters/month_reference_formatter.dart';
import 'package:acalapp/shared/widgets/blurred_dialog.dart';
import 'package:flutter/material.dart';

typedef QualityPeriod = ({int year, int month});

/// Sentinel popped by the "Todos os períodos" action in [_PeriodPickerDialog]
/// to distinguish "clear the filter" from "cancelled, keep current filter"
/// (both of which would otherwise look like a null result).
const _clearPeriod = Object();

/// The "Filtrar por Período" button shown above the quality analyses table —
/// opens a month/year picker and reports the chosen period, or null for
/// "todos os períodos".
class QualityPeriodFilterButton extends StatelessWidget {
  const QualityPeriodFilterButton({super.key, required this.period, required this.onChanged});

  final QualityPeriod? period;
  final ValueChanged<QualityPeriod?> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = period;
    final label = p == null ? 'Todos os períodos' : '${monthNames[p.month - 1]}/${p.year}';

    return OutlinedButton.icon(
      onPressed: () async {
        final result = await showBlurredDialog<Object?>(
          context: context,
          builder: (context) => _PeriodPickerDialog(initial: period),
        );
        if (result == null) return;
        onChanged(identical(result, _clearPeriod) ? null : result as QualityPeriod);
      },
      icon: const Icon(Icons.calendar_today, size: 18),
      label: Text(label),
    );
  }
}

class _PeriodPickerDialog extends StatefulWidget {
  const _PeriodPickerDialog({required this.initial});

  final QualityPeriod? initial;

  @override
  State<_PeriodPickerDialog> createState() => _PeriodPickerDialogState();
}

class _PeriodPickerDialogState extends State<_PeriodPickerDialog> {
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = widget.initial?.month ?? now.month;
    _year = widget.initial?.year ?? now.year;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = [for (var y = currentYear - 5; y <= currentYear + 1; y++) y];

    return AlertDialog(
      title: const Text('Filtrar por Período'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<int>(
                initialValue: _month,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Mês'),
                items: [
                  for (var m = 1; m <= 12; m++) DropdownMenuItem(value: m, child: Text(monthNames[m - 1])),
                ],
                onChanged: (v) => setState(() => _month = v!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _year,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Ano'),
                items: [for (final y in years) DropdownMenuItem(value: y, child: Text('$y'))],
                onChanged: (v) => setState(() => _year = v!),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_clearPeriod),
          child: const Text('Todos os períodos'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((year: _year, month: _month)),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
