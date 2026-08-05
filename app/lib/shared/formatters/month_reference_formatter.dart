const monthNames = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

/// Formats a date as its month/year reference, e.g. "08/2026".
String formatMonthReference(DateTime date) =>
    '${date.month.toString().padLeft(2, '0')}/${date.year}';
