/// The filters the invoices list can be narrowed by. Grouped into one object
/// so [InvoiceService.findAll] doesn't grow a parameter per filter.
class InvoiceFilter {
  const InvoiceFilter({
    this.year,
    this.month,
    this.customerId,
    this.addressId,
    this.status,
  });

  final int? year;
  final int? month;
  final String? customerId;
  final String? addressId;
  final String? status;

  Map<String, String> toQuery() => {
        'year': ?year?.toString(),
        'month': ?month?.toString(),
        'customer_id': ?customerId,
        'address_id': ?addressId,
        'status': ?status,
      };
}
