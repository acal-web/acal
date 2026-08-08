import 'package:acalapp/shared/formatters/month_reference_formatter.dart';
import 'package:acalapp/shared/widgets/blurred_dialog.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

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

    return FButton(
      variant: FButtonVariant.outline,
      mainAxisSize: MainAxisSize.min,
      onPress: () async {
        final result = await showBlurredDialog<Object?>(
          context: context,
          builder: (context) => _PeriodPickerDialog(initial: period),
        );
        if (result == null) return;
        onChanged(identical(result, _clearPeriod) ? null : result as QualityPeriod);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [const Icon(Icons.calendar_today, size: 18), const SizedBox(width: 8), Text(label)],
      ),
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

    return FDialog(
      builder: (context, style) => Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filtrar por Período', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FSelect<int>(
                      items: {for (var m = 1; m <= 12; m++) monthNames[m - 1]: m},
                      control: FSelectControl.managed(initial: _month, onChange: (v) => setState(() => _month = v!)),
                      label: const Text('Mês'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FSelect<int>(
                      items: {for (final y in years) '$y': y},
                      control: FSelectControl.managed(initial: _year, onChange: (v) => setState(() => _year = v!)),
                      label: const Text('Ano'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  FButton(
                    variant: FButtonVariant.ghost,
                    mainAxisSize: MainAxisSize.min,
                    onPress: () => Navigator.of(context).pop(_clearPeriod),
                    child: const Text('Todos os períodos'),
                  ),
                  FButton(
                    variant: FButtonVariant.ghost,
                    mainAxisSize: MainAxisSize.min,
                    onPress: () => Navigator.of(context).pop(null),
                    child: const Text('Cancelar'),
                  ),
                  FButton(
                    mainAxisSize: MainAxisSize.min,
                    onPress: () => Navigator.of(context).pop((year: _year, month: _month)),
                    child: const Text('Aplicar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
