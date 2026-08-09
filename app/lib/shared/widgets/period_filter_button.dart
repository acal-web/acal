import 'package:acalapp/shared/formatters/month_reference_formatter.dart';
import 'package:acalapp/shared/widgets/blurred_dialog.dart';
// `YearPicker` clashes with Flutter's own Material calendar year picker —
// hidden here so the one exported by month_year_picker's pickers.dart wins.
import 'package:flutter/material.dart' hide YearPicker;
import 'package:forui/forui.dart';
// Only `MonthPicker`/`YearPicker` (the grid widgets) are reused from this
// package — its own `showMonthYearPicker`/`MonthYearPickerDialog` wrap them
// in a Material date-picker chrome (a colored header band) that doesn't fit
// this app's look and has no option to turn off, so we drive the grids
// ourselves inside our own `FDialog`. `src/pickers.dart` isn't re-exported
// by the package's public library file, hence the `src/` import.
// ignore: implementation_imports
import 'package:month_year_picker/src/pickers.dart';

typedef MonthYear = ({int year, int month});

/// Sentinel popped by the "Todos os períodos" action in [_MonthYearPickerDialog]
/// to distinguish "clear the filter" from "cancelled, keep current value"
/// (both of which would otherwise look like a null result).
const _clearPeriod = Object();

DateTime _firstSelectableDate() => DateTime(DateTime.now().year - 20);
DateTime _lastSelectableDate() => DateTime(DateTime.now().year + 3, 12);

/// Opens the month/year picker dialog and resolves to the chosen period, or
/// null if the user cancels. Used directly by pages that always need a
/// period (e.g. a "reference month" field) — pages that also want a "clear
/// the filter" action should use [PeriodFilterButton] instead.
Future<MonthYear?> pickMonthYear(BuildContext context, {MonthYear? initial}) async {
  final result = await showBlurredDialog<Object?>(
    context: context,
    builder: (context) => _MonthYearPickerDialog(initial: initial, allowClear: false),
  );
  return result as MonthYear?;
}

/// A "Filtrar por Período" button — opens the month/year picker and reports
/// the chosen period, or null for "todos os períodos".
class PeriodFilterButton extends StatelessWidget {
  const PeriodFilterButton({super.key, required this.period, required this.onChanged});

  final MonthYear? period;
  final ValueChanged<MonthYear?> onChanged;

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
          builder: (context) => _MonthYearPickerDialog(initial: period, allowClear: true),
        );
        if (result == null) return;
        onChanged(identical(result, _clearPeriod) ? null : result as MonthYear);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [const Icon(Icons.calendar_today, size: 18), const SizedBox(width: 8), Text(label)],
      ),
    );
  }
}

class _MonthYearPickerDialog extends StatefulWidget {
  const _MonthYearPickerDialog({required this.initial, required this.allowClear});

  final MonthYear? initial;
  final bool allowClear;

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  final _monthPickerKey = GlobalKey<MonthPickerState>();
  final _yearPickerKey = GlobalKey<YearPickerState>();
  final _firstDate = _firstSelectableDate();
  final _lastDate = _lastSelectableDate();
  late DateTime _selected;
  bool _showingYear = false;
  bool _canGoPrevious = false;
  bool _canGoNext = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = widget.initial == null
        ? DateTime(now.year, now.month)
        : DateTime(widget.initial!.year, widget.initial!.month);
    // Both pickers are always mounted (see build()), so their state is
    // available on this very first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(_updatePaginators));
  }

  void _updatePaginators() {
    _canGoNext = _showingYear ? _yearPickerKey.currentState!.canGoUp : _monthPickerKey.currentState!.canGoUp;
    _canGoPrevious = _showingYear ? _yearPickerKey.currentState!.canGoDown : _monthPickerKey.currentState!.canGoDown;
  }

  Future<void> _goPrevious() =>
      _showingYear ? _yearPickerKey.currentState!.goDown() : _monthPickerKey.currentState!.goDown();

  Future<void> _goNext() =>
      _showingYear ? _yearPickerKey.currentState!.goUp() : _monthPickerKey.currentState!.goUp();

  void _toggleShowingYear() => setState(() {
    _showingYear = !_showingYear;
    _updatePaginators();
  });

  void _onYearSelected(DateTime date) => setState(() {
    _selected = DateTime(date.year, _selected.month);
    _showingYear = false;
    _monthPickerKey.currentState?.goToYear(year: _selected.year);
    _updatePaginators();
  });

  void _onMonthSelected(DateTime date) => setState(() => _selected = DateTime(date.year, date.month));

  void _onPageChanged(DateTime date) => setState(() {
    _selected = DateTime(date.year, date.month);
    _updatePaginators();
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FDialog(
      builder: (context, style) => Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TextButton(
                    onPressed: _toggleShowingYear,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${_selected.year}', style: theme.textTheme.titleMedium),
                        AnimatedRotation(
                          turns: _showingYear ? 0.5 : 0,
                          duration: const Duration(milliseconds: 150),
                          child: const Icon(Icons.arrow_drop_down),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: _canGoPrevious ? _goPrevious : null),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: _canGoNext ? _goNext : null),
                ],
              ),
              SizedBox(
                height: 280,
                child: IndexedStack(
                  index: _showingYear ? 1 : 0,
                  children: [
                    MonthPicker(
                      key: _monthPickerKey,
                      initialDate: _selected,
                      firstDate: _firstDate,
                      lastDate: _lastDate,
                      selectedDate: _selected,
                      onMonthSelected: _onMonthSelected,
                      onPageChanged: _onPageChanged,
                    ),
                    YearPicker(
                      key: _yearPickerKey,
                      initialDate: _selected,
                      firstDate: _firstDate,
                      lastDate: _lastDate,
                      selectedDate: _selected,
                      onYearSelected: _onYearSelected,
                      onPageChanged: _onPageChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.allowClear)
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
                    onPress: () => Navigator.of(context).pop((year: _selected.year, month: _selected.month)),
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
