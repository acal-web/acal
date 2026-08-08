import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A field that looks up options by text as the user types (debounced, via
/// [search]) and lets them pick one from a list shown below the field — used
/// for pickers backed by a paginated API (sócio, logradouro, categoria)
/// where a plain dropdown loading the whole table wouldn't scale.
class SearchSelectField<T> extends StatefulWidget {
  const SearchSelectField({
    super.key,
    required this.label,
    required this.search,
    required this.labelBuilder,
    this.subtitleBuilder,
    this.initialValue,
    required this.onSelected,
    this.hintText,
    this.validator,
    this.debounce = const Duration(milliseconds: 300),
    this.minQueryLength = 1,
    this.noResultsText = 'Nenhum resultado encontrado',
  });

  final String label;
  final Future<List<T>> Function(String query) search;
  final String Function(T) labelBuilder;
  final String Function(T)? subtitleBuilder;
  final T? initialValue;
  final ValueChanged<T?> onSelected;
  final String? hintText;
  final FormFieldValidator<T>? validator;
  final Duration debounce;
  final int minQueryLength;
  final String noResultsText;

  @override
  State<SearchSelectField<T>> createState() => _SearchSelectFieldState<T>();
}

class _SearchSelectFieldState<T> extends State<SearchSelectField<T>> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Cancel-and-reschedule debounce: only the timer that survives until it
  // fires ever calls `search` — a superseded call's Completer is simply
  // abandoned (never completed), which is harmless in Dart.
  Future<Iterable<T>> _filter(String query) {
    final trimmed = query.trim();
    if (trimmed.length < widget.minQueryLength) return Future.value(const []);

    _debounceTimer?.cancel();
    final completer = Completer<Iterable<T>>();
    _debounceTimer = Timer(widget.debounce, () async {
      completer.complete(await widget.search(trimmed));
    });
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return FSelect<T>.searchBuilder(
      label: Text(widget.label),
      hint: widget.hintText,
      format: widget.labelBuilder,
      filter: _filter,
      contentBuilder: (context, query, values) => [
        for (final value in values)
          FSelectItem(
            value: value,
            title: Text(widget.labelBuilder(value)),
            subtitle: widget.subtitleBuilder == null ? null : Text(widget.subtitleBuilder!(value)),
          ),
      ],
      contentEmptyBuilder: (context, style) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(widget.noResultsText),
      ),
      control: FSelectControl.managed(initial: widget.initialValue, onChange: widget.onSelected),
      validator: widget.validator ?? (_) => null,
    );
  }
}
