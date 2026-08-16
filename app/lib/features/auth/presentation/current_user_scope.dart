import 'package:flutter/material.dart';
import 'package:acalapp/features/auth/presentation/current_user.dart';

class CurrentUserScope extends InheritedNotifier<CurrentUser> {
  const CurrentUserScope({
    super.key,
    required CurrentUser super.notifier,
    required super.child,
  });

  static CurrentUser of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CurrentUserScope>()!.notifier!;
  }
}
