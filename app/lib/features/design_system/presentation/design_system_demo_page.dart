import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/table/data_table_card.dart';
import 'package:flutter/material.dart' hide FormFieldSetter;
import 'package:forui/forui.dart';

class DesignSystemDemoPage extends StatefulWidget {
  const DesignSystemDemoPage({super.key});

  @override
  State<DesignSystemDemoPage> createState() => _DesignSystemDemoPageState();
}

class _DesignSystemDemoPageState extends State<DesignSystemDemoPage> {
  var _brightness = Brightness.light;

  @override
  Widget build(BuildContext context) {
    final fThemeData = _brightness == Brightness.light ? fThemeLight : fThemeDark;

    return FTheme(
      data: fThemeData,
      child: FToaster(
        child: FTooltipGroup(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: 'Design System',
                  subtitle: 'Catálogo de componentes Forui — avaliação antes da migração.',
                  action: IconButton(
                    tooltip: _brightness == Brightness.light ? 'Tema escuro' : 'Tema claro',
                    icon: Icon(_brightness == Brightness.light ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                    onPressed: () => setState(() {
                      _brightness = _brightness == Brightness.light ? Brightness.dark : Brightness.light;
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                FTabs(
                  children: [
                    FTabEntry(label: const Text('Basic'), child: const _BasicSection()),
                    FTabEntry(label: const Text('Forms'), child: const _FormsSection()),
                    FTabEntry(label: const Text('Data & Feedback'), child: const _DataFeedbackSection()),
                    FTabEntry(label: const Text('Table'), child: const _TableSection()),
                    FTabEntry(label: const Text('Overlays'), child: const _OverlaysSection()),
                    FTabEntry(label: const Text('Navigation'), child: const _NavigationSection()),
                    FTabEntry(label: const Text('Typography'), child: const _TypographySection()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Wrap(spacing: 20, runSpacing: 20, children: tiles),
      );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}

class _BasicSection extends StatelessWidget {
  const _BasicSection();

  @override
  Widget build(BuildContext context) => _Section(tiles: [
        _Tile(label: 'FButton — primary', child: FButton(onPress: () {}, child: const Text('Primary'))),
        _Tile(
          label: 'FButton — secondary',
          child: FButton(variant: FButtonVariant.secondary, onPress: () {}, child: const Text('Secondary')),
        ),
        _Tile(
          label: 'FButton — outline',
          child: FButton(variant: FButtonVariant.outline, onPress: () {}, child: const Text('Outline')),
        ),
        _Tile(
          label: 'FButton — destructive',
          child: FButton(variant: FButtonVariant.destructive, onPress: () {}, child: const Text('Destructive')),
        ),
        _Tile(
          label: 'FButton — ghost',
          child: FButton(variant: FButtonVariant.ghost, onPress: () {}, child: const Text('Ghost')),
        ),
        _Tile(label: 'FButton — disabled', child: FButton(onPress: null, child: const Text('Disabled'))),
        _Tile(label: 'FBadge — primary', child: FBadge(child: const Text('Badge'))),
        _Tile(
          label: 'FBadge — destructive',
          child: FBadge(variant: FBadgeVariant.destructive, child: const Text('Badge')),
        ),
        _Tile(label: 'FAvatar', child: FAvatar.raw(child: const Text('AC'))),
      ]);
}

class _FormsSection extends StatelessWidget {
  const _FormsSection();

  @override
  Widget build(BuildContext context) => _Section(tiles: [
        const _Tile(label: 'FTextField', child: FTextField(hint: 'Digite aqui')),
        _Tile(
          label: 'FSelect',
          child: FSelect<String>(
            items: const {'Água': 'agua', 'Esgoto': 'esgoto'},
            label: const Text('Categoria'),
          ),
        ),
        const _Tile(label: 'FCheckbox — desmarcado', child: FCheckbox()),
        const _Tile(label: 'FCheckbox — marcado', child: FCheckbox(value: true)),
        const _Tile(label: 'FCheckbox — desabilitado', child: FCheckbox(onChange: null)),
        const _Tile(label: 'FRadio — desmarcado', child: FRadio()),
        const _Tile(label: 'FRadio — marcado', child: FRadio(value: true)),
        const _Tile(label: 'FSwitch — desligado', child: FSwitch()),
        const _Tile(label: 'FSwitch — ligado', child: FSwitch(value: true)),
      ]);
}

class _DataFeedbackSection extends StatelessWidget {
  const _DataFeedbackSection();

  @override
  Widget build(BuildContext context) => _Section(tiles: [
        _Tile(
          label: 'FCard',
          child: FCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [Text('Título do card'), SizedBox(height: 4), Text('Conteúdo de exemplo.')],
              ),
            ),
          ),
        ),
        const _Tile(label: 'FAlert — primary', child: FAlert(title: Text('Aviso'), subtitle: Text('Mensagem de exemplo.'))),
        const _Tile(
          label: 'FAlert — destructive',
          child: FAlert(variant: FAlertVariant.destructive, title: Text('Erro'), subtitle: Text('Algo deu errado.')),
        ),
        const _Tile(label: 'FProgress', child: FProgress()),
        const _Tile(label: 'FCircularProgress', child: FCircularProgress()),
      ]);
}

typedef _MockRow = ({String firstName, String lastName, String position, String office, DateTime start, int salary});

String _formatMoney(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return 'R\$ $buffer';
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

const _firstNames = [
  'Airi', 'Angelica', 'Ashton', 'Bradley', 'Brenden', 'Brielle', 'Bruno', 'Caesar', 'Cara', 'Cedric',
  'Diana', 'Elena', 'Felipe', 'Gustavo', 'Helena', 'Igor', 'Julia', 'Kenji', 'Larissa', 'Marcos',
];
const _lastNames = [
  'Satou', 'Ramos', 'Cox', 'Greer', 'Wagner', 'Williamson', 'Nash', 'Vance', 'Stevens', 'Kelly',
  'Ferreira', 'Lima', 'Souza', 'Alves', 'Rocha', 'Barbosa', 'Cardoso', 'Dias', 'Esteves', 'Franco',
];
const _positions = [
  'Accountant', 'Chief Executive Officer (CEO)', 'Junior Technical Author', 'Software Engineer',
  'Integration Specialist', 'Pre-Sales Support', 'Sales Assistant', 'Senior Javascript Developer',
];
const _offices = ['Tokyo', 'London', 'San Francisco', 'New York', 'Edinburgh'];

/// O Forui não tem um componente de tabela — essa aba reaproveita o
/// [DataTableCard] (Material) que já roda em produção em Sócios/Faturas/etc.,
/// pra deixar claro que ele continua sendo peça própria do app mesmo se o
/// resto migrar pro Forui. Dados/colunas espelham o clássico demo do
/// DataTables.net (First name/Last name/Position/Office/Start date/Salary),
/// inclusive com o rodapé repetindo o cabeçalho (via `showFooter: true`).
class _TableSection extends StatefulWidget {
  const _TableSection();

  @override
  State<_TableSection> createState() => _TableSectionState();
}

class _TableSectionState extends State<_TableSection> {
  static final _allRows = List.generate(57, (i) {
    final salaryBase = 60000 + (i * 37) % 20 * 5000 + (i * 12347) % 90000;
    return (
      firstName: _firstNames[i % _firstNames.length],
      lastName: _lastNames[(i * 7) % _lastNames.length],
      position: _positions[i % _positions.length],
      office: _offices[i % _offices.length],
      start: DateTime(2008 + i % 8, i % 12 + 1, i % 27 + 1),
      salary: salaryBase,
    );
  });

  var _page = 0;
  var _pageSize = 10;
  String? _sortColumn;
  var _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final sorted = List.of(_allRows);
    switch (_sortColumn) {
      case 'firstName':
        sorted.sort((a, b) => a.firstName.compareTo(b.firstName));
      case 'lastName':
        sorted.sort((a, b) => a.lastName.compareTo(b.lastName));
      case 'position':
        sorted.sort((a, b) => a.position.compareTo(b.position));
      case 'office':
        sorted.sort((a, b) => a.office.compareTo(b.office));
      case 'start':
        sorted.sort((a, b) => a.start.compareTo(b.start));
      case 'salary':
        sorted.sort((a, b) => a.salary.compareTo(b.salary));
    }
    final ordered = _sortAscending ? sorted : sorted.reversed.toList();

    final totalPages = (ordered.length / _pageSize).ceil();
    final pageItems = ordered.skip(_page * _pageSize).take(_pageSize).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SizedBox(
        height: 560,
        child: DataTableCard<_MockRow>(
          showFooter: true,
          columns: const [
            DataTableColumn('First name', sortable: true, sortKey: 'firstName'),
            DataTableColumn('Last name', sortable: true, sortKey: 'lastName'),
            DataTableColumn('Position', flex: 2, sortable: true, sortKey: 'position'),
            DataTableColumn('Office', sortable: true, sortKey: 'office'),
            DataTableColumn('Start date', sortable: true, sortKey: 'start'),
            DataTableColumn('Salary', sortable: true, sortKey: 'salary'),
          ],
          items: pageItems,
          rowBuilder: (context, row) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              spacing: columnSpacing,
              children: [
                Expanded(child: Text(row.firstName)),
                Expanded(child: Text(row.lastName)),
                Expanded(flex: 2, child: Text(row.position)),
                Expanded(child: Text(row.office)),
                Expanded(child: Text(_formatDate(row.start))),
                Expanded(child: Text(_formatMoney(row.salary))),
              ],
            ),
          ),
          pagination: Pagination(
            number: _page,
            totalPages: totalPages,
            totalElements: ordered.length,
            size: _pageSize,
            first: _page == 0,
            last: _page >= totalPages - 1,
          ),
          onPageChanged: (page) => setState(() => _page = page),
          pageSize: _pageSize,
          onPageSizeChanged: (size) => setState(() {
            _pageSize = size;
            _page = 0;
          }),
          sortColumn: _sortColumn,
          sortAscending: _sortAscending,
          onSort: (key) => setState(() {
            if (_sortColumn == key) {
              _sortAscending = !_sortAscending;
            } else {
              _sortColumn = key;
              _sortAscending = true;
            }
          }),
        ),
      ),
    );
  }
}

class _OverlaysSection extends StatelessWidget {
  const _OverlaysSection();

  @override
  Widget build(BuildContext context) => _Section(tiles: [
        _Tile(
          label: 'FDialog (showFDialog)',
          child: FButton(
            variant: FButtonVariant.outline,
            onPress: () => showFDialog(
              context: context,
              builder: (context, style, animation) => FDialog(
                builder: (context, style) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Diálogo de exemplo'),
                      const SizedBox(height: 8),
                      const Text('Conteúdo de demonstração do FDialog.'),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FButton(onPress: () => Navigator.of(context).pop(), child: const Text('Fechar')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            child: const Text('Abrir diálogo'),
          ),
        ),
        _Tile(
          label: 'FToast (showFToast)',
          child: FButton(
            variant: FButtonVariant.outline,
            onPress: () => showFToast(context: context, title: const Text('Notificação de exemplo')),
            child: const Text('Mostrar toast'),
          ),
        ),
        _Tile(
          label: 'FTooltip',
          child: FTooltip(
            tipBuilder: (context, controller) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text('Dica de exemplo'),
            ),
            child: FButton(variant: FButtonVariant.outline, onPress: () {}, child: const Text('Passe o mouse')),
          ),
        ),
      ]);
}

class _NavigationSection extends StatelessWidget {
  const _NavigationSection();

  @override
  Widget build(BuildContext context) => _Section(tiles: [
        SizedBox(
          width: 460,
          child: _Tile(
            label: 'FBreadcrumb',
            child: FBreadcrumb(
              children: const [
                FBreadcrumbItem(child: Text('Início')),
                FBreadcrumbItem(child: Text('Faturas')),
                FBreadcrumbItem(current: true, child: Text('Gerar')),
              ],
            ),
          ),
        ),
        _Tile(
          label: 'FPagination',
          child: FPagination(control: const FPaginationControl.managed(initial: 1, pages: 5)),
        ),
      ]);
}

class _TypographySection extends StatelessWidget {
  const _TypographySection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Display Large', style: textTheme.displayLarge),
          Text('Display Medium', style: textTheme.displayMedium),
          Text('Headline Medium', style: textTheme.headlineMedium),
          Text('Title Large', style: textTheme.titleLarge),
          Text('Body Medium — texto padrão de parágrafo.', style: textTheme.bodyMedium),
          Text('Label Small', style: textTheme.labelSmall),
        ],
      ),
    );
  }
}
