/// A connection eligible for invoicing in a given reference period, as
/// returned by `GET /invoices/eligible` — not persisted yet, just a preview
/// row for the "Gerar Faturas" table.
class InvoiceCandidate {
  final String connectionId;
  final String customerName;
  final String addressName;
  final int number;
  final String? letter;
  final String categoryName;
  final double membershipValue;
  final double waterValue;
  final bool hasWaterMeter;
  final double? previousMeterFinalReading;

  const InvoiceCandidate({
    required this.connectionId,
    required this.customerName,
    required this.addressName,
    required this.number,
    this.letter,
    required this.categoryName,
    required this.membershipValue,
    required this.waterValue,
    required this.hasWaterMeter,
    this.previousMeterFinalReading,
  });

  double get amount => membershipValue + waterValue;

  String get fullAddress => letter != null ? '$addressName, $number$letter' : '$addressName, $number';

  factory InvoiceCandidate.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      try {
        if (value is double) return value;
        if (value is int) return value.toDouble();
        return double.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return InvoiceCandidate(
      connectionId: json['connection_id'].toString(),
      customerName: (json['customer'] as Map<String, dynamic>)['name'] as String,
      addressName: (json['address'] as Map<String, dynamic>)['name'] as String,
      number: json['number'] as int,
      letter: json['letter'] as String?,
      categoryName: (json['category'] as Map<String, dynamic>)['name'] as String,
      membershipValue: parseDouble(json['membership_value'])!,
      waterValue: parseDouble(json['water_value'])!,
      hasWaterMeter: (json['category'] as Map<String, dynamic>)['has_water_meter'] as bool? ?? false,
      previousMeterFinalReading: parseDouble(json['previous_meter_final_reading']),
    );
  }
}
