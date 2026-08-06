const groups = ['temporario', 'efetivo', 'fundador'];

const _groupLabels = {
  'temporario': 'Temporário',
  'efetivo': 'Efetivo',
  'fundador': 'Fundador',
};

String groupLabel(String group) => _groupLabels[group] ?? group;

class Category {
  final String? id;
  final String name;
  final String? description;
  final String group;
  final bool hasWaterMeter;
  final double waterPrice;
  final double membershipPrice;

  const Category({
    this.id,
    required this.name,
    this.description,
    required this.group,
    required this.hasWaterMeter,
    required this.waterPrice,
    required this.membershipPrice,
  });

  String get fullName => '${groupLabel(group)} $name';

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id']?.toString(),
        name: json['name'] as String,
        description: json['description'] as String?,
        group: json['group'] as String,
        hasWaterMeter: json['has_water_meter'] as bool,
        waterPrice: double.parse(json['water_price'].toString()),
        membershipPrice: double.parse(json['membership_price'].toString()),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'description': description,
        'group': group,
        'has_water_meter': hasWaterMeter,
        'water_price': waterPrice,
        'membership_price': membershipPrice,
      };

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? group,
    bool? hasWaterMeter,
    double? waterPrice,
    double? membershipPrice,
  }) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        group: group ?? this.group,
        hasWaterMeter: hasWaterMeter ?? this.hasWaterMeter,
        waterPrice: waterPrice ?? this.waterPrice,
        membershipPrice: membershipPrice ?? this.membershipPrice,
      );
}
