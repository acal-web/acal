const qualityAnalysisParamNames = [
  'Cloro Residual',
  'Coliformes Totais',
  'Cor Aparente',
  'Escherichia Coli',
  'Turbidez',
];

class QualityAnalysis {
  final String? id;
  final DateTime referenceDate;
  final String paramName;
  final int required;
  final int analyzed;
  final int compliant;

  const QualityAnalysis({
    this.id,
    required this.referenceDate,
    required this.paramName,
    required this.required,
    required this.analyzed,
    required this.compliant,
  });

  factory QualityAnalysis.fromJson(Map<String, dynamic> json) => QualityAnalysis(
        id: json['id']?.toString(),
        referenceDate: DateTime.parse(json['reference_date'] as String),
        paramName: json['param_name'] as String,
        required: json['required'] as int,
        analyzed: json['analyzed'] as int,
        compliant: json['compliant'] as int,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'reference_date': _formatDate(referenceDate),
        'param_name': paramName,
        'required': required,
        'analyzed': analyzed,
        'compliant': compliant,
      };

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-01';

  QualityAnalysis copyWith({
    String? id,
    DateTime? referenceDate,
    String? paramName,
    int? required,
    int? analyzed,
    int? compliant,
  }) =>
      QualityAnalysis(
        id: id ?? this.id,
        referenceDate: referenceDate ?? this.referenceDate,
        paramName: paramName ?? this.paramName,
        required: required ?? this.required,
        analyzed: analyzed ?? this.analyzed,
        compliant: compliant ?? this.compliant,
      );
}
