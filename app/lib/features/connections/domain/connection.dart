import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/customer/domain/customer.dart';

class Connection {
  final String? id;
  final String customerId;
  final String addressId;
  final String categoryId;
  final bool active;
  final DateTime? membershipDate;
  final bool exclusivelyMember;
  final Customer? customer;
  final Address? address;
  final Category? category;

  const Connection({
    this.id,
    required this.customerId,
    required this.addressId,
    required this.categoryId,
    this.active = true,
    this.membershipDate,
    this.exclusivelyMember = false,
    this.customer,
    this.address,
    this.category,
  });

  factory Connection.fromJson(Map<String, dynamic> json) => Connection(
        id: json['id']?.toString(),
        customerId: json['customer_id'].toString(),
        addressId: json['address_id'].toString(),
        categoryId: json['category_id'].toString(),
        active: json['active'] as bool,
        membershipDate: json['membership_date'] != null ? DateTime.parse(json['membership_date'] as String) : null,
        exclusivelyMember: json['exclusively_member'] as bool,
        customer: json['customer'] != null ? Customer.fromJson(json['customer'] as Map<String, dynamic>) : null,
        address: json['address'] != null ? Address.fromJson(json['address'] as Map<String, dynamic>) : null,
        category: json['category'] != null ? Category.fromJson(json['category'] as Map<String, dynamic>) : null,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'customer_id': customerId,
        'address_id': addressId,
        'category_id': categoryId,
        'active': active,
        'membership_date': membershipDate == null ? null : _formatDate(membershipDate!),
        'exclusively_member': exclusivelyMember,
      };

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Connection copyWith({
    String? id,
    String? customerId,
    String? addressId,
    String? categoryId,
    bool? active,
    DateTime? membershipDate,
    bool? exclusivelyMember,
    Customer? customer,
    Address? address,
    Category? category,
  }) =>
      Connection(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        addressId: addressId ?? this.addressId,
        categoryId: categoryId ?? this.categoryId,
        active: active ?? this.active,
        membershipDate: membershipDate ?? this.membershipDate,
        exclusivelyMember: exclusivelyMember ?? this.exclusivelyMember,
        customer: customer ?? this.customer,
        address: address ?? this.address,
        category: category ?? this.category,
      );
}
