import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/currency_formatter.dart';

class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    super.key,
    required this.category,
    required this.spent,
    required this.limit,
    this.onTap,
  });

  final String category;
  final double spent;
  final double limit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = limit <= 0 ? 0.0 : spent / limit;
    final displayRatio = ratio.clamp(0.0, 1.0);
    final color = ratio >= 1
        ? Theme.of(context).colorScheme.error
        : ratio >= .8
        ? const Color(0xFFF59E0B)
        : brandGreen;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  limit <= 0
                      ? 'Atur anggaran'
                      : '${formatRupiah(spent)} / ${formatRupiah(limit)}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: displayRatio,
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: .12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
