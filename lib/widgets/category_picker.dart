import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../utils/constants.dart';

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
    final categories = categoriesFor(type);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories
          .map((category) {
            final selected = value == category.name;
            return ChoiceChip(
              selected: selected,
              onSelected: (_) => onChanged(category.name),
              avatar: Icon(
                category.icon,
                size: 17,
                color: selected
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : category.color,
              ),
              label: Text(category.name),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
