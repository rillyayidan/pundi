import 'package:flutter/material.dart';

import '../models/parsed_bill_model.dart';

class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({super.key, required this.confidence});

  final ConfidenceLevel confidence;

  @override
  Widget build(BuildContext context) {
    final color = switch (confidence) {
      ConfidenceLevel.high => const Color(0xFF15803D),
      ConfidenceLevel.medium => const Color(0xFFD97706),
      ConfidenceLevel.low => Theme.of(context).colorScheme.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        confidence.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
