const kinds = ['Avenida', 'Fazenda', 'Praça', 'Rua', 'Travessa'];

class Address {
  final String? id;
  final String kind;
  final String name;
  final bool active;

  const Address({
    this.id,
    required this.kind,
    required this.name,
    this.active = true,
  });

  String get fullAddress => '$kind $name';

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id']?.toString(),
        kind: json['kind'] as String,
        name: json['name'] as String,
        active: json['deleted_at'] == null,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'kind': kind,
        'name': name,
      };

  Address copyWith({String? id, String? kind, String? name, bool? active}) => Address(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        name: name ?? this.name,
        active: active ?? this.active,
      );
}
