class Customer {

  final String? id;
  final String name;
  final String document;
  final int? membershipNumber;
  final bool voter;
  final bool active;
  final List<String> tags;

  const Customer({
    this.id,
    required this.name,
    required this.document,
    this.membershipNumber,
    required this.voter,
    this.active = true,
    this.tags = const [],
  });

  bool get hasInvalidData => tags.contains('invalid data');

  factory Customer.fromJson(Map<String, dynamic> json) {
    final tags = (json['tags'] as List<dynamic>?)?.cast<String>() ?? [];
    return Customer(
      id: json['id']?.toString(),
      name: json['name'] as String,
      document: json['document'] as String,
      membershipNumber: json['membership_number'] as int?,
      voter: json['voter'] as bool,
      active: json['deleted_at'] == null,
      tags: tags,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'document': document,
        'membership_number': membershipNumber,
        'voter': voter,
        'tags': tags,
      };

  Customer copyWith({
    String? id,
    String? name,
    String? document,
    int? membershipNumber,
    bool? voter,
    bool? active,
    List<String>? tags,
  }) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        document: document ?? this.document,
        membershipNumber: membershipNumber ?? this.membershipNumber,
        voter: voter ?? this.voter,
        active: active ?? this.active,
        tags: tags ?? this.tags,
      );
}
