class WaterMeter {
  final String? id;
  final String invoiceId;
  final double initialReading;
  final double finalReading;
  final DateTime measuredAt;

  const WaterMeter({
    this.id,
    required this.invoiceId,
    required this.initialReading,
    required this.finalReading,
    required this.measuredAt,
  });

  double get consumption => (finalReading - initialReading) - 10000 > 0
      ? (finalReading - initialReading) - 10000
      : 0;

  double get realConsumption => finalReading - initialReading;

  factory WaterMeter.fromJson(Map<String, dynamic> json) => WaterMeter(
        id: json['id']?.toString(),
        invoiceId: json['invoice_id'].toString(),
        initialReading: double.parse(json['initial_reading'].toString()),
        finalReading: double.parse(json['final_reading'].toString()),
        measuredAt: DateTime.parse(json['measured_at'] as String),
      );
}
