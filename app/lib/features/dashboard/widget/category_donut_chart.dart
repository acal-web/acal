import 'dart:math' as math;

import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/dashboard/domain/dashboard_summary.dart';
import 'package:flutter/material.dart';

class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({super.key, required this.membersByCategory});

  final List<CategoryCount> membersByCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final total = membersByCategory.fold<int>(0, (sum, c) => sum + c.count);

    if (total == 0) {
      return Center(
        child: Text(
          'Sem sócios',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: _DonutPainter(membersByCategory: membersByCategory),
        ),
        const SizedBox(height: 16),
        ..._buildLegend(context, membersByCategory),
      ],
    );
  }

  List<Widget> _buildLegend(BuildContext context, List<CategoryCount> items) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final colors = [cs.primary, cs.secondary, cs.outline];

    return items.asMap().entries.map((e) {
      final index = e.key;
      final item = e.value;
      final label = groupLabel(item.group);
      final color = colors[index % colors.length];

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: theme.textTheme.labelMedium),
            ),
            Text(
              item.count.toString(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _DonutPainter extends StatelessWidget {
  const _DonutPainter({required this.membersByCategory});

  final List<CategoryCount> membersByCategory;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = [cs.primary, cs.secondary, cs.outline];
    final total = membersByCategory.fold<int>(0, (sum, c) => sum + c.count);

    return SizedBox.expand(
      child: CustomPaint(
        painter: _DonutChartPainter(
          membersByCategory: membersByCategory,
          colors: colors,
          total: total,
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<CategoryCount> membersByCategory;
  final List<Color> colors;
  final int total;

  _DonutChartPainter({
    required this.membersByCategory,
    required this.colors,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0 || size.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2.8;
    final innerRadius = outerRadius * 0.6;

    var startAngle = -math.pi / 2;

    for (var i = 0; i < membersByCategory.length; i++) {
      final item = membersByCategory[i];
      final fraction = item.count / total;
      final sweepAngle = fraction * 2 * math.pi;

      final path = Path();

      // Outer arc
      path.arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        false,
      );

      // Line to inner circle
      final endAngle = startAngle + sweepAngle;
      final innerEnd = Offset(
        center.dx + innerRadius * math.cos(endAngle),
        center.dy + innerRadius * math.sin(endAngle),
      );
      path.lineTo(innerEnd.dx, innerEnd.dy);

      // Inner arc (reverse)
      path.arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        endAngle,
        -sweepAngle,
        false,
      );

      path.close();

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) => false;
}
