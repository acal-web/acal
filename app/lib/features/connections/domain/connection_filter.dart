import 'package:acalapp/core/services/http_service.dart';

/// The filters the connections list can be narrowed by. Grouped into one
/// object so [ConnectionService.findAll] doesn't grow a parameter per filter.
class ConnectionFilter {
  /// Lists show active connections unless asked otherwise — without a status
  /// the API returns inactive and deleted ones too.
  static const defaultStatus = 'active';

  const ConnectionFilter({
    this.customerId,
    this.customerName,
    this.customerDocument,
    this.addressName,
    this.categoryId,
    this.status,
  });

  final String? customerId;
  final String? customerName;
  final String? customerDocument;
  final String? addressName;
  final String? categoryId;
  final String? status;

  Map<String, String> toQuery() => {
        'customer_id': ?blankToNull(customerId),
        'customer_name': ?blankToNull(customerName),
        'customer_document': ?blankToNull(customerDocument),
        'address_name': ?blankToNull(addressName),
        'category_id': ?blankToNull(categoryId),
        'status': ?blankToNull(status),
      };
}
