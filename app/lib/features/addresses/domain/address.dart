const addressTypes = ['Avenida', 'Fazenda', 'Praça', 'Rua', 'Travessa'];

class Address {
  final String? id;
  final String type;
  final String name;

  const Address({this.id, required this.type, required this.name});

  String get fullAddress => '$type $name';

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id']?.toString(),
        type: json['address_type'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'address_type': type,
        'name': name,
      };

  Address copyWith({String? id, String? type, String? name}) => Address(
        id: id ?? this.id,
        type: type ?? this.type,
        name: name ?? this.name,
      );
}
