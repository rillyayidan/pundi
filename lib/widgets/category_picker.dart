import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/category_provider.dart';

class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.type,
    required this.value,
    required this.onChanged,
  });

  final TransactionType type;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().forType(type);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories
          .map((category) {
            final selected = value == category.name;
            return InkWell(
              onTap: () => onChanged(category.name),
              borderRadius: BorderRadius.circular(15),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 190),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : category.color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : category.color.withValues(alpha: .18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category.icon,
                      size: 17,
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : category.color,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      category.name,
                      style: TextStyle(
                        color: selected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
