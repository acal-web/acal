import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InvoiceDetailsCard extends StatelessWidget {
  const InvoiceDetailsCard({
    super.key,
    required this.invoice,
  });

  final Invoice invoice;

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatMonthYear(DateTime date) {
    const months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    return '${months[date.month - 1]} de ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final connection = invoice.connection;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ═════ HEADER ═════
            Text(
              'ACAL - Associação Comunitária e Assistencial de Lages',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'CNPJ: 13.228.119/0001-68\nRua Morro do Chapéu, S/N - Lages do Batata - Jacobina BA\nTel: (74) 3674-2165 | Email: acallages@hotmail.com',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Contribuição de serviços assistenciais aos Sócios',
              style: theme.textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const Divider(height: 24),

            // ═════ THREE COLUMN LAYOUT ═════
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                if (isWide) {
                  return _buildThreeColumnLayout(theme, cs, connection);
                } else {
                  return _buildStackedLayout(theme, cs, connection);
                }
              },
            ),

            // ═════ FINANCIAL DETAILS SECTION ═════
            const SizedBox(height: 24),
            _buildFinancialDetailsSection(theme, cs),

            // ═════ STATUS SECTION ═════
            const SizedBox(height: 24),
            _buildStatusSection(theme, cs),

            // ═════ OBSERVATIONS ═════
            const SizedBox(height: 24),
            _buildObservationsSection(theme, cs),
          ],
        ),
      ),
    );
  }

  Widget _buildThreeColumnLayout(ThemeData theme, ColorScheme cs, dynamic connection) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT COLUMN - Member Info (33%)
        Expanded(
          child: _buildMemberSection(theme, cs, connection),
        ),
        const SizedBox(width: 16),
        // CENTER COLUMN - QR Code / Payment Status (33%)
        Expanded(
          child: _buildCenterSection(theme, cs),
        ),
        const SizedBox(width: 16),
        // RIGHT COLUMN - Dates and Values (33%)
        Expanded(
          child: _buildValuesSection(theme, cs),
        ),
      ],
    );
  }

  Widget _buildStackedLayout(ThemeData theme, ColorScheme cs, dynamic connection) {
    return Column(
      children: [
        _buildMemberSection(theme, cs, connection),
        const SizedBox(height: 16),
        _buildCenterSection(theme, cs),
        const SizedBox(height: 16),
        _buildValuesSection(theme, cs),
      ],
    );
  }

  Widget _buildMemberSection(ThemeData theme, ColorScheme cs, dynamic connection) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dados do Sócio',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (connection != null) ...[
            _buildInfoRow(theme, 'Sócio', connection.customer?.name ?? '—'),
            const SizedBox(height: 8),
            _buildInfoRow(theme, 'Endereço', connection.address?.name ?? '—'),
            const SizedBox(height: 8),
            _buildInfoRow(
              theme,
              'Ligação',
              '${connection.number}${connection.letter ?? ''}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(theme, 'Categoria', connection.category?.name ?? '—'),
          ] else ...[
            Text('—', style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _buildCenterSection(ThemeData theme, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (invoice.isPaid)
            Column(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'PAGO',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pago em:',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(invoice.paidAt!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          else
            Column(
              children: [
                QrImageView(
                  data: invoice.number ?? invoice.id ?? 'fatura',
                  version: QrVersions.auto,
                  size: 120,
                  gapless: false,
                  errorCorrectionLevel: QrErrorCorrectLevel.L,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nº Fatura',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  invoice.number ?? invoice.id ?? '—',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildValuesSection(ThemeData theme, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dates
        _buildDetailRow(
          theme,
          'Data de Emissão',
          _formatDate(DateTime.now()),
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          theme,
          'Conta Ref a',
          _formatMonthYear(invoice.referenceDate),
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          theme,
          'Vencimento',
          _formatDate(invoice.dueDate),
          isBold: true,
          highlight: true,
        ),
        const SizedBox(height: 16),
        Divider(color: cs.outlineVariant),
        const SizedBox(height: 16),

        // Values
        _buildDetailRow(
          theme,
          'Valor da Mensalidade',
          formatBRL(invoice.membershipValue),
          isBold: true,
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          theme,
          'Outras Taxas',
          formatBRL(invoice.waterValue),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: cs.outlineVariant, width: 2),
              bottom: BorderSide(color: cs.outlineVariant, width: 2),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _buildDetailRow(
            theme,
            'Valor Total',
            formatBRL(invoice.amount),
            isBold: true,
            highlight: true,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialDetailsSection(ThemeData theme, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalhamento Financeiro',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(theme, 'Taxa de Sócio', formatBRL(invoice.membershipValue)),
          const SizedBox(height: 8),
          _buildDetailRow(theme, 'Valor de Água', formatBRL(invoice.waterValue)),
          const SizedBox(height: 8),
          _buildDetailRow(theme, 'Consumo Incluso', '15.000 litros'),
          const SizedBox(height: 12),
          Divider(color: cs.outlineVariant),
          const SizedBox(height: 12),
          _buildDetailRow(
            theme,
            'Total a Pagar',
            formatBRL(invoice.amount),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(ThemeData theme, ColorScheme cs) {
    final isPaid = invoice.isPaid;
    final statusColor = isPaid ? Colors.green : Colors.orange;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: statusColor),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.schedule,
            color: statusColor,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            isPaid ? 'FATURA PAGA' : 'FATURA PENDENTE',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          if (isPaid)
            Text(
              'Data do pagamento: ${_formatDate(invoice.paidAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
              textAlign: TextAlign.center,
            )
          else
            Text(
              'Vencimento: ${_formatDate(invoice.dueDate)}',
              style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildObservationsSection(ThemeData theme, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Observações Importantes',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Após a data de vencimento será cobrado juros de 1% ao mês;\n'
            '• Multa de 10% será aplicada sobre o valor original da fatura;\n'
            '• Consulte o código de barras para realizar o pagamento;\n'
            '• Em caso de dúvidas, entre em contato com nossa administração.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    String label,
    String value, {
    bool isBold = false,
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: highlight ? theme.colorScheme.primary : null,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: highlight ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
