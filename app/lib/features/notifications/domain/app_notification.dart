class AppNotification {
  final String? id;
  final String title;
  final String body;
  final int recipientCount;
  final String? status;
  final String? addressName;
  final String? categoryName;
  final String? sentByName;
  final DateTime? createdAt;

  const AppNotification({
    this.id,
    required this.title,
    required this.body,
    this.recipientCount = 0,
    this.status,
    this.addressName,
    this.categoryName,
    this.sentByName,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id']?.toString(),
        title: json['title'] as String,
        body: json['body'] as String,
        recipientCount: json['recipient_count'] as int? ?? 0,
        status: json['status'] as String?,
        addressName: json['address_name'] as String?,
        categoryName: json['category_name'] as String?,
        sentByName: json['sent_by_name'] as String?,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      );
}
