import '../models/parsed_bill_model.dart';

class BillParserService {
  static final _amountPattern = RegExp(
    r'(?:(?:rp|idr)\.?\s*)?(\d{1,3}(?:[.\s]\d{3})+(?:,\d{2})?|\d{4,9})(?:[,.]\d{2})?',
    caseSensitive: false,
  );
  static final _datePattern = RegExp(
    r'\b(\d{1,2})[\-/.](\d{1,2})[\-/.](\d{2,4})\b',
  );
  static final _monthNamePattern = RegExp(
    r'\b(\d{1,2})\s+(jan(?:uari)?|feb(?:ruari)?|mar(?:et)?|apr(?:il)?|mei|jun(?:i)?|jul(?:i)?|agu(?:stus)?|sep(?:tember)?|okt(?:ober)?|nov(?:ember)?|des(?:ember)?)\s+(\d{2,4})\b',
    caseSensitive: false,
  );
  static const _totalKeywords = [
    'grand total',
    'total bayar',
    'total belanja',
    'jumlah bayar',
    'amount due',
    'total',
    'jumlah',
  ];
  static const _negativeAmountKeywords = [
    'subtotal',
    'sub total',
    'tunai',
    'cash',
    'kembali',
    'change',
    'diskon',
    'discount',
    'pajak',
    'tax',
    'ppn',
  ];
  static const _merchantNoise = [
    'struk',
    'receipt',
    'invoice',
    'nota',
    'terima kasih',
    'thank you',
    'tanggal',
    'date',
    'kasir',
    'cashier',
    'telp',
    'phone',
    'www.',
  ];

  ParsedBillModel parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    final amountResult = _extractAmount(lines);
    final merchantResult = _extractMerchant(lines);
    final dateResult = _extractDate(lines);
    return ParsedBillModel(
      amount: amountResult?.value,
      amountConfidence: amountResult?.confidence ?? ConfidenceLevel.low,
      merchant: merchantResult?.value,
      merchantConfidence: merchantResult?.confidence ?? ConfidenceLevel.low,
      date: dateResult?.value,
      dateConfidence: dateResult?.confidence ?? ConfidenceLevel.low,
      rawText: rawText,
    );
  }

  _Result<double>? _extractAmount(List<String> lines) {
    final candidates = <_AmountCandidate>[];
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final lower = line.toLowerCase();
      final totalIndex = _totalKeywords.indexWhere(lower.contains);
      final hasNegativeKeyword = _negativeAmountKeywords.any(lower.contains);
      for (final match in _amountPattern.allMatches(line)) {
        final value = _parseAmount(match.group(1)!);
        if (value == null || value < 100) continue;
        var score = 0;
        if (totalIndex >= 0) score += 100 - totalIndex * 5;
        if (lower.contains('rp') || lower.contains('idr')) score += 12;
        if (hasNegativeKeyword) score -= 45;
        score += (index / (lines.isEmpty ? 1 : lines.length) * 8).round();
        candidates.add(_AmountCandidate(value, score));
      }
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final scoreOrder = b.score.compareTo(a.score);
      return scoreOrder != 0 ? scoreOrder : b.value.compareTo(a.value);
    });
    final best = candidates.first;
    final confidence = best.score >= 80
        ? ConfidenceLevel.high
        : best.score >= 15
        ? ConfidenceLevel.medium
        : ConfidenceLevel.low;
    if (confidence == ConfidenceLevel.low) {
      final largest = candidates.reduce((a, b) => a.value >= b.value ? a : b);
      return _Result(largest.value, confidence);
    }
    return _Result(best.value, confidence);
  }

  double? _parseAmount(String source) {
    var normalized = source.replaceAll(' ', '');
    if (normalized.contains('.')) {
      normalized = normalized.replaceAll('.', '');
    }
    if (normalized.contains(',')) {
      final parts = normalized.split(',');
      normalized = parts.last.length == 2
          ? '${parts.take(parts.length - 1).join()}.${parts.last}'
          : parts.join();
    }
    return double.tryParse(normalized);
  }

  _Result<String>? _extractMerchant(List<String> lines) {
    for (var index = 0; index < lines.length && index < 8; index++) {
      final line = lines[index];
      final lower = line.toLowerCase();
      final letters = RegExp(r'[a-zA-Z]').allMatches(line).length;
      final digits = RegExp(r'\d').allMatches(line).length;
      if (letters < 3 || digits > letters) continue;
      if (_merchantNoise.any(lower.contains)) continue;
      if (_totalKeywords.any(lower.contains)) continue;
      return _Result(
        _titleCase(line),
        index <= 2 ? ConfidenceLevel.high : ConfidenceLevel.medium,
      );
    }
    return null;
  }

  _Result<DateTime>? _extractDate(List<String> lines) {
    final currentYear = DateTime.now().year;
    for (final line in lines) {
      final numeric = _datePattern.firstMatch(line);
      if (numeric != null) {
        final day = int.parse(numeric.group(1)!);
        final month = int.parse(numeric.group(2)!);
        var year = int.parse(numeric.group(3)!);
        if (year < 100) year += 2000;
        final date = _validDate(year, month, day, currentYear);
        if (date != null) {
          final explicit =
              line.toLowerCase().contains('tanggal') ||
              line.toLowerCase().contains('date');
          return _Result(
            date,
            explicit ? ConfidenceLevel.high : ConfidenceLevel.medium,
          );
        }
      }
      final named = _monthNamePattern.firstMatch(line);
      if (named != null) {
        final day = int.parse(named.group(1)!);
        final month = _monthNumber(named.group(2)!);
        var year = int.parse(named.group(3)!);
        if (year < 100) year += 2000;
        final date = _validDate(year, month, day, currentYear);
        if (date != null) return _Result(date, ConfidenceLevel.high);
      }
    }
    return null;
  }

  DateTime? _validDate(int year, int month, int day, int currentYear) {
    if (year < 2000 || year > currentYear + 1) return null;
    final candidate = DateTime(year, month, day);
    return candidate.year == year &&
            candidate.month == month &&
            candidate.day == day
        ? candidate
        : null;
  }

  int _monthNumber(String value) {
    const months = [
      'jan',
      'feb',
      'mar',
      'apr',
      'mei',
      'jun',
      'jul',
      'agu',
      'sep',
      'okt',
      'nov',
      'des',
    ];
    return months.indexWhere(value.toLowerCase().startsWith) + 1;
  }

  String _titleCase(String value) => value
      .toLowerCase()
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

class _Result<T> {
  const _Result(this.value, this.confidence);
  final T value;
  final ConfidenceLevel confidence;
}

class _AmountCandidate {
  const _AmountCandidate(this.value, this.score);
  final double value;
  final int score;
}
