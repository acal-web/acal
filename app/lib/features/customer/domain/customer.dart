class Customer {
  final String? id;
  final String name;
  final String document;
  final int membershipNumber;
  final bool voter;

  const Customer({
    this.id,
    required this.name,
    required this.document,
    required this.membershipNumber,
    required this.voter,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id']?.toString(),
        name: json['name'] as String,
        document: json['document'] as String,
        membershipNumber: json['membership_number'] as int,
        voter: json['voter'] as bool,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'document': document,
        'membership_number': membershipNumber,
        'voter': voter,
      };

  Customer copyWith({
    String? id,
    String? name,
    String? document,
    int? membershipNumber,
    bool? voter,
  }) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        document: document ?? this.document,
        membershipNumber: membershipNumber ?? this.membershipNumber,
        voter: voter ?? this.voter,
      );
}
