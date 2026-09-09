/// A connection with unpaid, overdue invoices, as returned by
/// `GET /invoices/overdue` — drives the "Cobranças" preview table.
class OverdueConnection {
  final String connectionId;
  final String connectionNumber;
  final String customerName;
  final String addressName;
  final List<OverdueInvoice> invoices;
  final double totalAmount;

  /// Days the connection's *oldest* open invoice is overdue by.
  final int daysOverdue;

  /// Set by the API when [daysOverdue] passed the cutoff threshold — the
  /// service can be shut off, and the letter says so.
  final bool subjectToCutoff;

  const OverdueConnection({
    required this.connectionId,
    required this.connectionNumber,
    required this.customerName,
    required this.addressName,
    required this.invoices,
    required this.totalAmount,
    this.daysOverdue = 0,
    this.subjectToCutoff = false,
  });

  factory OverdueConnection.fromJson(Map<String, dynamic> json) => OverdueConnection(
        connectionId: json['connection_id'].toString(),
        connectionNumber: json['connection_number'] as String,
        customerName: (json['customer'] as Map<String, dynamic>)['name'] as String,
        addressName: (json['address'] as Map<String, dynamic>)['name'] as String,
        invoices: (json['invoices'] as List)
            .map((e) => OverdueInvoice.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalAmount: double.parse(json['total_amount'].toString()),
        daysOverdue: int.tryParse(json['days_overdue'].toString()) ?? 0,
        subjectToCutoff: json['subject_to_cutoff'] == true,
      );
}

class OverdueInvoice {
  final String id;
  final DateTime referenceDate;
  final DateTime dueDate;
  final double membershipValue;
  final double waterValue;

  const OverdueInvoice({
    required this.id,
    required this.referenceDate,
    required this.dueDate,
    required this.membershipValue,
    required this.waterValue,
  });

  double get amount => membershipValue + waterValue;

  factory OverdueInvoice.fromJson(Map<String, dynamic> json) => OverdueInvoice(
        id: json['id'].toString(),
        referenceDate: DateTime.parse(json['reference_date'] as String),
        dueDate: DateTime.parse(json['due_date'] as String),
        membershipValue: double.parse(json['membership_value'].toString()),
        waterValue: double.parse(json['water_value'].toString()),
      );
}
