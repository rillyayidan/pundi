enum ConfidenceLevel {
  low,
  medium,
  high;

  String get label => switch (this) {
    low => 'Rendah',
    medium => 'Sedang',
    high => 'Tinggi',
  };
}

class ParsedBillModel {
  const ParsedBillModel({
    this.amount,
    this.merchant,
    this.date,
    required this.rawText,
    this.amountConfidence = ConfidenceLevel.low,
    this.merchantConfidence = ConfidenceLevel.low,
    this.dateConfidence = ConfidenceLevel.low,
    this.lineItems = const [],
    this.sourceImagePath,
  });

  final double? amount;
  final String? merchant;
  final DateTime? date;
  final String rawText;
  final ConfidenceLevel amountConfidence;
  final ConfidenceLevel merchantConfidence;
  final ConfidenceLevel dateConfidence;
  final List<ReceiptLineItem> lineItems;
  final String? sourceImagePath;

  bool get hasUsefulData => amount != null || merchant != null || date != null;
}

class ReceiptLineItem {
  const ReceiptLineItem({
    required this.label,
    required this.amount,
    this.suggestedCategory = 'Lainnya',
  });

  final String label;
  final double amount;
  final String suggestedCategory;
}
