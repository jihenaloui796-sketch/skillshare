import 'package:flutter/material.dart';

class RatingBadge extends StatelessWidget {
  final double average;
  final int count;
  final bool dense;

  const RatingBadge({
    super.key,
    required this.average,
    required this.count,
    this.dense = true,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = dense
        ? Theme.of(context).textTheme.labelMedium
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: dense ? 16 : 18, color: const Color(0xFFF59E0B)),
        const SizedBox(width: 4),
        Text(
          average.toStringAsFixed(1),
          style: textStyle?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 6),
        Text(
          '($count)',
          style: textStyle?.copyWith(color: Theme.of(context).hintColor),
        ),
      ],
    );
  }
}
