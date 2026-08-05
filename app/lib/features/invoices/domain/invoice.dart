import 'package:acalapp/features/connections/domain/connection.dart';

class Invoice {
  final String? id;
  final String connectionId;
  final DateTime referenceDate;
  final DateTime dueDate;
  final double amount;
  final Connection? connection;

  const Invoice({
    this.id,
    required this.connectionId,
    required this.referenceDate,
    required this.dueDate,
    required this.amount,
    this.connection,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id']?.toString(),
        connectionId: json['connection_id'].toString(),
        referenceDate: DateTime.parse(json['reference_date'] as String),
        dueDate: DateTime.parse(json['due_date'] as String),
        amount: double.parse(json['amount'].toString()),
        connection: json['connection'] != null ? Connection.fromJson(json['connection'] as Map<String, dynamic>) : null,
      );
}
