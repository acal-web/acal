import 'package:acalapp/features/invoices/domain/invoice.dart';

class CategoryCount {
  final String group;
  final int count;

  const CategoryCount({required this.group, required this.count});

  factory CategoryCount.fromJson(Map<String, dynamic> json) => CategoryCount(
    group: json['group'] as String,
    count: json['count'] as int,
  );
}

class DashboardSummary {
  final double totalReceived;
  final double totalReceivable;
  final int invoicesReceivedCount;
  final int invoicesReceivableCount;
  final List<Invoice> recentInvoices;
  final List<CategoryCount> membersByCategory;

  const DashboardSummary({
    required this.totalReceived,
    required this.totalReceivable,
    required this.invoicesReceivedCount,
    required this.invoicesReceivableCount,
    required this.recentInvoices,
    required this.membersByCategory,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
    totalReceived: double.parse(json['total_received'].toString()),
    totalReceivable: double.parse(json['total_receivable'].toString()),
    invoicesReceivedCount: json['invoices_received_count'] as int,
    invoicesReceivableCount: json['invoices_receivable_count'] as int,
    recentInvoices: (json['recent_invoices'] as List)
        .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
        .toList(),
    membersByCategory: (json['members_by_category'] as List)
        .map((e) => CategoryCount.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
