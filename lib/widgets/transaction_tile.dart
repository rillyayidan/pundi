import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final category = categoryByName(transaction.category);
    final positive = transaction.type == TransactionType.income;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: category.color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(category.icon, color: category.color),
      ),
      title: Text(
        transaction.merchant?.isNotEmpty == true
            ? transaction.merchant!
            : transaction.category,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${transaction.category} · ${formatDate(transaction.date)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${positive ? '+' : '-'}${formatRupiah(transaction.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: positive
                  ? brandGreen
                  : Theme.of(context).colorScheme.error,
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 2),
            IconButton(
              tooltip: 'Hapus',
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: const Icon(Icons.more_vert_rounded, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}
