class CustomerAuthUser {
  final String id;
  final String name;
  final String document;

  CustomerAuthUser({
    required this.id,
    required this.name,
    required this.document,
  });

  factory CustomerAuthUser.fromJson(Map<String, dynamic> json) => CustomerAuthUser(
        id: json['id'] as String,
        name: json['name'] as String,
        document: json['document'] as String,
      );
}
