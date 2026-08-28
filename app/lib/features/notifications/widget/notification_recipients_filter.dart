import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/addresses/widget/address_select_field.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/categories/widget/category_select_field.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

enum RecipientStatus {
  active('Ativos', 'active'),
  inactive('Inativos', 'inactive'),
  all('Todos', 'all');

  const RecipientStatus(this.label, this.value);
  final String label;
  final String value;
}

typedef RecipientFilters = ({String? addressId, String? categoryId, String status});

/// Lets an admin narrow down who receives a broadcast notification by
/// street ("rua") and/or category — the same segmentation already used to
/// filter connections, reused here so "select by rua/categoria" doesn't need
/// a new mechanism.
class NotificationRecipientsFilter extends StatefulWidget {
  const NotificationRecipientsFilter({
    super.key,
    required this.onChanged,
    this.addressService,
    this.categoryService,
  });

  final ValueChanged<RecipientFilters> onChanged;
  final AddressService? addressService;
  final CategoryService? categoryService;

  @override
  State<NotificationRecipientsFilter> createState() => _NotificationRecipientsFilterState();
}

class _NotificationRecipientsFilterState extends State<NotificationRecipientsFilter> {
  late final AddressService _addressService;
  late final CategoryService _categoryService;
  Address? _address;
  Category? _category;
  RecipientStatus _status = RecipientStatus.active;

  @override
  void initState() {
    super.initState();
    _addressService = widget.addressService ?? AddressService();
    _categoryService = widget.categoryService ?? CategoryService();
  }

  void _emit() => widget.onChanged((addressId: _address?.id, categoryId: _category?.id, status: _status.value));

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < LayoutConfig.narrowBreakpoint;

    final addressField = AddressSelectField(
      addressService: _addressService,
      initialValue: _address,
      onSelected: (a) {
        setState(() => _address = a);
        _emit();
      },
    );

    final categoryField = CategorySelectField(
      categoryService: _categoryService,
      initialValue: _category,
      onSelected: (c) {
        setState(() => _category = c);
        _emit();
      },
    );

    final statusField = FSelect<RecipientStatus>(
      items: {for (final status in RecipientStatus.values) status.label: status},
      control: FSelectControl.managed(
        initial: _status,
        onChange: (v) {
          setState(() => _status = v ?? RecipientStatus.active);
          _emit();
        },
      ),
      label: const Text('Situação'),
    );

    return narrow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              addressField,
              const SizedBox(height: 12),
              categoryField,
              const SizedBox(height: 12),
              statusField,
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: addressField),
              const SizedBox(width: 12),
              Expanded(child: categoryField),
              const SizedBox(width: 12),
              Expanded(child: statusField),
            ],
          );
  }
}
