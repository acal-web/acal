import 'package:flutter/material.dart';

class BoolText extends StatelessWidget {
  const BoolText(this.value, {super.key, this.style});

  final bool value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text(value ? 'Sim' : 'Não', style: style);
}
