import 'package:flutter/material.dart';
import 'package:acalapp/features/customer_portal/presentation/current_customer.dart';

class CurrentCustomerScope extends InheritedNotifier<CurrentCustomer> {
  const CurrentCustomerScope({
    super.key,
    required CurrentCustomer super.notifier,
    required super.child,
  });

  static CurrentCustomer of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CurrentCustomerScope>()!.notifier!;
  }
}
