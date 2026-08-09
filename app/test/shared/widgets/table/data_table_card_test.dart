import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/shared/widgets/table/data_table_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _items = ['Alexandre', 'Zeca'];

const _pagination = Pagination(
  number: 0,
  totalPages: 1,
  totalElements: 2,
  size: 10,
  first: true,
  last: true,
);

const _columns = [
  DataTableColumn('Nome', flex: 6, sortable: true, sortKey: 'name'),
  DataTableColumn('Documento', flex: 2),
  DataTableColumn('Ações', width: 88),
];

Widget _row(String item) => Row(
      children: [
        Expanded(flex: 6, child: Text(item)),
        const Expanded(flex: 2, child: Text('116.748.190-99')),
        const SizedBox(width: 88, child: Text('edit')),
      ],
    );

/// Pumps a [DataTableCard] matching the "Sócios" table's column shape
/// (one sortable column plus two non-sortable ones) and returns the
/// sortKey captured by [onSort], if any.
class _Capture {
  String? sortKey;
}

Future<_Capture> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final capture = _Capture();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DataTableCard<String>(
          columns: _columns,
          items: _items,
          rowBuilder: (context, item) => _row(item),
          pagination: _pagination,
          onPageChanged: (_) {},
          pageSize: 10,
          onPageSizeChanged: (_) {},
          onSort: (sortKey) => capture.sortKey = sortKey,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return capture;
}

void main() {
  testWidgets('tapping the "Nome" header sorts by it', (tester) async {
    final capture = await _pump(tester);

    await tester.tap(find.text('Nome'));
    await tester.pump();

    expect(capture.sortKey, 'name');
  });

  testWidgets('tapping the "Documento" header does not sort', (tester) async {
    final capture = await _pump(tester);

    await tester.tap(find.text('Documento').first);
    await tester.pump();

    expect(capture.sortKey, isNull, reason: 'tapping a non-sortable header must not sort');
  });

  testWidgets('tapping a data row does not sort', (tester) async {
    final capture = await _pump(tester);

    // Tap the row's own "Alexandre" name cell — not the header.
    await tester.tap(find.text('Alexandre'));
    await tester.pump();

    expect(capture.sortKey, isNull, reason: 'tapping a data row must not sort');
  });

  testWidgets('tapping the "Nome" column far from its label still sorts', (tester) async {
    final capture = await _pump(tester);

    // The "Nome" header cell is flex 6 (the widest column) — tap its far
    // right edge, well clear of the "Nome" label and sort arrows, to confirm
    // the InkWell is stretched to fill the whole flexed cell rather than
    // hugging just the label.
    final headerRect = tester.getRect(find.text('Nome'));
    final farRight = Offset(headerRect.right + 200, headerRect.center.dy);
    await tester.tapAt(farRight);
    await tester.pump();

    expect(capture.sortKey, 'name', reason: 'tapping anywhere in the Nome header cell must sort');
  });
}
