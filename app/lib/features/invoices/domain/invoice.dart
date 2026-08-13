import 'package:acalapp/features/connections/domain/connection.dart';

class Invoice {
  final String? id;
  final String connectionId;
  final DateTime referenceDate;
  final DateTime dueDate;
  final double membershipValue;
  final double waterValue;
  final DateTime? paidAt;
  final Connection? connection;

  const Invoice({
    this.id,
    required this.connectionId,
    required this.referenceDate,
    required this.dueDate,
    required this.membershipValue,
    required this.waterValue,
    this.paidAt,
    this.connection,
  });

  bool get isPaid => paidAt != null;

  double get amount => membershipValue + waterValue;

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id']?.toString(),
        connectionId: json['connection_id'].toString(),
        referenceDate: DateTime.parse(json['reference_date'] as String),
        dueDate: DateTime.parse(json['due_date'] as String),
        membershipValue: double.parse(json['membership_value'].toString()),
        waterValue: double.parse(json['water_value'].toString()),
        paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
        connection: json['connection'] != null ? Connection.fromJson(json['connection'] as Map<String, dynamic>) : null,
      );
}
