import 'dart:async';

import 'package:acalapp/shared/widgets/labeled_field.dart';
import 'package:flutter/material.dart';

/// A [FormField] that looks up options by text as the user types (debounced,
/// via [search]) and lets them pick one from a list shown below the field —
/// used for pickers backed by a paginated API (sócio, logradouro, categoria)
/// where a plain dropdown loading the whole table wouldn't scale.
class SearchSelectField<T> extends FormField<T> {
  SearchSelectField({
    super.key,
    required this.label,
    required this.search,
    required this.labelBuilder,
    this.subtitleBuilder,
    super.initialValue,
    required this.onSelected,
    this.hintText,
    super.validator,
    this.debounce = const Duration(milliseconds: 300),
    this.minQueryLength = 1,
    this.noResultsText = 'Nenhum resultado encontrado',
  }) : super(builder: (field) => (field as _SearchSelectFieldState<T>)._build(field.context));

  final String label;
  final Future<List<T>> Function(String query) search;
  final String Function(T) labelBuilder;
  final String Function(T)? subtitleBuilder;
  final ValueChanged<T?> onSelected;
  final String? hintText;
  final Duration debounce;
  final int minQueryLength;
  final String noResultsText;

  @override
  FormFieldState<T> createState() => _SearchSelectFieldState<T>();
}

class _SearchSelectFieldState<T> extends FormFieldState<T> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;
  int _searchGeneration = 0;
  List<T> _options = [];
  bool _loading = false;
  bool _searched = false;

  @override
  SearchSelectField<T> get widget => super.widget as SearchSelectField<T>;

  @override
  void initState() {
    super.initState();
    final initial = value;
    _controller = TextEditingController(text: initial != null ? widget.labelBuilder(initial) : '');
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    final current = value;
    // TextEditingController listeners fire on *any* text change, including
    // the one we make ourselves in `_select` below — ignore that echo
    // instead of treating it as the user clearing their selection.
    if (current != null && query == widget.labelBuilder(current)) return;

    if (current != null) {
      didChange(null);
      widget.onSelected(null);
    }

    _debounceTimer?.cancel();
    final generation = ++_searchGeneration;

    final trimmed = query.trim();
    if (trimmed.length < widget.minQueryLength) {
      setState(() {
        _options = [];
        _loading = false;
        _searched = false;
      });
      return;
    }

    setState(() => _loading = true);
    _debounceTimer = Timer(widget.debounce, () async {
      final results = await widget.search(trimmed);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _options = results;
        _loading = false;
        _searched = true;
      });
    });
  }

  void _select(T option) {
    didChange(option);
    widget.onSelected(option);
    _controller.text = widget.labelBuilder(option);
    _debounceTimer?.cancel();
    _searchGeneration++;
    setState(() {
      _options = [];
      _loading = false;
      _searched = false;
    });
    FocusScope.of(context).unfocus();
  }

  Widget _build(BuildContext context) {
    final theme = Theme.of(context);

    return LabeledField(
      label: widget.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: widget.hintText,
              errorText: hasError ? errorText : null,
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            onChanged: _onQueryChanged,
          ),
          if (_options.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _options.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final option = _options[i];
                  final subtitle = widget.subtitleBuilder?.call(option);
                  return ListTile(
                    dense: true,
                    title: Text(widget.labelBuilder(option)),
                    subtitle: subtitle != null ? Text(subtitle) : null,
                    onTap: () => _select(option),
                  );
                },
              ),
            )
          else if (!_loading && _searched)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.noResultsText,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}
