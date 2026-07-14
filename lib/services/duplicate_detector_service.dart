import '../models/transaction_model.dart';

class DuplicateDetectorService {
  const DuplicateDetectorService();

  static const Duration _merchantWindow = Duration(hours: 24);
  static const Duration _fallbackWindow = Duration(hours: 2);

  TransactionModel? findMatch(
    TransactionModel candidate,
    Iterable<TransactionModel> existing,
  ) {
    for (final item in existing) {
      if (_isDuplicate(candidate, item)) return item;
    }
    return null;
  }

  bool _isDuplicate(TransactionModel candidate, TransactionModel existing) {
    if (candidate.id != null && candidate.id == existing.id) return false;
    if (candidate.type != existing.type ||
        candidate.walletId != existing.walletId ||
        !_sameAmount(candidate.amount, existing.amount)) {
      return false;
    }

    final difference = candidate.date.difference(existing.date).abs();
    final candidateMerchant = _normalize(candidate.merchant);
    final existingMerchant = _normalize(existing.merchant);
    if (candidateMerchant.isNotEmpty && existingMerchant.isNotEmpty) {
      return difference <= _merchantWindow &&
          (candidateMerchant == existingMerchant ||
              candidateMerchant.contains(existingMerchant) ||
              existingMerchant.contains(candidateMerchant));
    }

    return difference <= _fallbackWindow &&
        candidate.category == existing.category;
  }

  bool _sameAmount(double left, double right) {
    final tolerance = (left.abs() * .001).clamp(1, 1000).toDouble();
    return (left - right).abs() <= tolerance;
  }

  String _normalize(String? value) =>
      (value ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}
