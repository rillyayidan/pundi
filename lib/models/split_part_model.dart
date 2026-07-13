class SplitPartModel {
  const SplitPartModel({
    required this.amount,
    required this.category,
    this.label = '',
  });

  final double amount;
  final String category;
  final String label;
}
