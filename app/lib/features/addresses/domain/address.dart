class Address {
  final String? id;
  final String name;
  final bool active;

  const Address({
    this.id,
    required this.name,
    this.active = true,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id']?.toString(),
        name: json['name'] as String,
        active: json['deleted_at'] == null,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
      };

  Address copyWith({String? id, String? name, bool? active}) => Address(
        id: id ?? this.id,
        name: name ?? this.name,
        active: active ?? this.active,
      );
}
