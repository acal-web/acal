import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/shared/widgets/async_error_view.dart';
import 'package:acalapp/shared/widgets/table/data_table_card.dart';
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
    this.sortColumn,
    this.sortAscending = true,
    this.onSort,
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
  final String? sortColumn;
  final bool sortAscending;
  final void Function(String sortKey)? onSort;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PagedResult<T>>(
      future: future,
      builder: (context, snapshot) {
        // FutureBuilder keeps the previous snapshot's data while a new
        // future is in flight (only clearing it once the new one settles),
        // so falling through to the still-valid data here — instead of
        // blanking the table for every page/sort/filter change — is what
        // avoids a loading-spinner flash on each interaction.
        if (!snapshot.hasData) {
          if (snapshot.hasError) {
            return AsyncErrorView(message: errorMessage, onRetry: onRetry);
          }
          return const Center(child: CircularProgressIndicator());
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
          sortColumn: sortColumn,
          sortAscending: sortAscending,
          onSort: onSort,
        );
      },
    );
  }
}
