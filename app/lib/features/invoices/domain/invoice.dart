import 'package:acalapp/features/connections/domain/connection.dart';
import 'package:acalapp/features/invoices/domain/water_meter.dart';
import 'package:acalapp/features/quality/domain/quality_analysis.dart';

class Invoice {
  final String? id;
  final String? number;
  final String connectionId;
  final DateTime referenceDate;
  final DateTime dueDate;
  final double membershipValue;
  final double waterValue;
  final double? waterConsumedValue;
  final DateTime? paidAt;
  final Connection? connection;
  final WaterMeter? waterMeter;
  final List<QualityAnalysis>? qualityAnalyses;

  const Invoice({
    this.id,
    this.number,
    required this.connectionId,
    required this.referenceDate,
    required this.dueDate,
    required this.membershipValue,
    required this.waterValue,
    this.waterConsumedValue,
    this.paidAt,
    this.connection,
    this.waterMeter,
    this.qualityAnalyses,
  });

  bool get isPaid => paidAt != null;

  double get amount => membershipValue + waterValue + (waterConsumedValue ?? 0);

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id']?.toString(),
        number: json['number']?.toString(),
        connectionId: json['connection_id'].toString(),
        referenceDate: DateTime.parse(json['reference_date'] as String),
        dueDate: DateTime.parse(json['due_date'] as String),
        membershipValue: double.parse(json['membership_value'].toString()),
        waterValue: double.parse(json['water_value'].toString()),
        waterConsumedValue:
            json['water_consumed_value'] != null ? double.parse(json['water_consumed_value'].toString()) : null,
        paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
        connection: json['connection'] != null ? Connection.fromJson(json['connection'] as Map<String, dynamic>) : null,
        waterMeter: json['water_meter'] != null ? WaterMeter.fromJson(json['water_meter'] as Map<String, dynamic>) : null,
        qualityAnalyses: json['quality_analyses'] != null
            ? (json['quality_analyses'] as List).map((e) => QualityAnalysis.fromJson(e as Map<String, dynamic>)).toList()
            : null,
      );
}
