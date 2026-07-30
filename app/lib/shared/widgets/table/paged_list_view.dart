import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/shared/widgets/async_error_view.dart';
import 'package:acalapp/shared/widgets/data_table_card.dart';
import 'package:flutter/material.dart';

/// Loads a [PagedResult] from [future] and renders the standard
/// loading / error / [DataTableCard] states used across "Cadastros" pages.
class PagedListView<T> extends StatelessWidget {
  const PagedListView({
    super.key,
    required this.future,
    required this.columns,
    required this.rowBuilder,
    required this.onPageChanged,
    required this.errorMessage,
    required this.onRetry,
    required this.pageSize,
    required this.onPageSizeChanged,
    this.emptyMessage = 'Nenhum registro encontrado.',
  });

  final Future<PagedResult<T>> future;
  final List<DataTableColumn> columns;
  final Widget Function(BuildContext context, T item) rowBuilder;
  final void Function(int page) onPageChanged;
  final String errorMessage;
  final VoidCallback onRetry;
  final int pageSize;
  final void Function(int size) onPageSizeChanged;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PagedResult<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return AsyncErrorView(message: errorMessage, onRetry: onRetry);
        }

        final result = snapshot.data!;

        return DataTableCard<T>(
          columns: columns,
          items: result.data,
          emptyMessage: emptyMessage,
          pagination: result.pagination,
          onPageChanged: onPageChanged,
          pageSize: pageSize,
          onPageSizeChanged: onPageSizeChanged,
          rowBuilder: rowBuilder,
        );
      },
    );
  }
}
