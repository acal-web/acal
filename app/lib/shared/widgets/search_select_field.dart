import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// A field that looks up options by text as the user types (debounced, via
/// [search]) and lets them pick one from a list shown below the field — used
/// for pickers backed by a paginated API (sócio, logradouro, categoria)
/// where a plain dropdown loading the whole table wouldn't scale.
class SearchSelectField<T extends Object> extends StatefulWidget {
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

// Represents a "no results found" state in the autocomplete options.
class _NoResults {
  const _NoResults();
}

class _SearchSelectFieldState<T extends Object> extends State<SearchSelectField<T>> {
  Timer? _debounceTimer;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue == null ? '' : widget.labelBuilder(widget.initialValue as T),
    );
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<Iterable<Object>> _optionsBuilder(TextEditingValue value) {
    final trimmed = value.text.trim();
    if (trimmed.length < widget.minQueryLength) return Future.value(const []);

    _debounceTimer?.cancel();
    final completer = Completer<Iterable<Object>>();
    _debounceTimer = Timer(widget.debounce, () async {
      final results = await widget.search(trimmed);
      if (results.isEmpty) {
        completer.complete([const _NoResults()]);
      } else {
        completer.complete(results);
      }
    });
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: widget.initialValue,
      validator: widget.validator ?? (_) => null,
      builder: (formFieldState) {
        return RawAutocomplete<Object>(
          textEditingController: _controller,
          focusNode: _focusNode,
          onSelected: (value) {
            if (value is! _NoResults) {
              final typedValue = value as T;
              _controller.text = widget.labelBuilder(typedValue);
              formFieldState.didChange(typedValue);
              widget.onSelected(typedValue);
            }
          },
          optionsBuilder: _optionsBuilder,
          displayStringForOption: (option) {
            if (option is _NoResults) return '';
            return widget.labelBuilder(option as T);
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) =>
              FTextField(
                label: Text(widget.label),
                hint: widget.hintText,
                control: FTextFieldControl.managed(controller: textEditingController),
                focusNode: focusNode,
                prefixBuilder: (context, style, variants) => const Icon(Icons.search, size: 20),
                error: formFieldState.errorText == null ? null : Text(formFieldState.errorText!),
              ),
          optionsViewBuilder: (context, onSelected, options) {
            return Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      if (option is _NoResults) {
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(widget.noResultsText),
                        );
                      }
                      final typedOption = option as T;
                      return ListTile(
                        title: Text(widget.labelBuilder(typedOption)),
                        subtitle: widget.subtitleBuilder == null ? null : Text(widget.subtitleBuilder!(typedOption)),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
