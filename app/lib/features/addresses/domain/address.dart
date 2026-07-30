const kinds = ['Avenida', 'Fazenda', 'Praça', 'Rua', 'Travessa'];

class Address {
  final String? id;
  final String kind;
  final String name;

  const Address({this.id, required this.kind, required this.name});

  String get fullAddress => '$kind $name';

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id']?.toString(),
        kind: json['kind'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'kind': kind,
        'name': name,
      };

  Address copyWith({String? id, String? kind, String? name}) => Address(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        name: name ?? this.name,
      );
}
