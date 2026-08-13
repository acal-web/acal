/// A connection eligible for invoicing in a given reference period, as
/// returned by `GET /invoices/eligible` — not persisted yet, just a preview
/// row for the "Gerar Faturas" table.
class InvoiceCandidate {
  final String connectionId;
  final String customerName;
  final String addressName;
  final String categoryName;
  final double membershipValue;
  final double waterValue;

  const InvoiceCandidate({
    required this.connectionId,
    required this.customerName,
    required this.addressName,
    required this.categoryName,
    required this.membershipValue,
    required this.waterValue,
  });

  double get amount => membershipValue + waterValue;

  factory InvoiceCandidate.fromJson(Map<String, dynamic> json) => InvoiceCandidate(
        connectionId: json['connection_id'].toString(),
        customerName: (json['customer'] as Map<String, dynamic>)['name'] as String,
        addressName: (json['address'] as Map<String, dynamic>)['name'] as String,
        categoryName: (json['category'] as Map<String, dynamic>)['name'] as String,
        membershipValue: double.parse(json['membership_value'].toString()),
        waterValue: double.parse(json['water_value'].toString()),
      );
}
