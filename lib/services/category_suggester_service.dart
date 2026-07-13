class CategorySuggesterService {
  static const _keywords = <String, List<String>>{
    'Makanan': [
      'restaurant',
      'restoran',
      'warung',
      'cafe',
      'kopi',
      'coffee',
      'bakery',
      'martabak',
      'ayam',
      'burger',
      'pizza',
      'mcd',
      'kfc',
      'solaria',
      'bakso',
      'gofood',
      'grabfood',
      'shopeefood',
    ],
    'Transportasi': [
      'gojek',
      'grab',
      'maxim',
      'transjakarta',
      'mrt',
      'commuter',
      'kereta',
      'pertamina',
      'shell',
      'bp akr',
      'parkir',
      'tol',
      'taxi',
    ],
    'Tagihan': [
      'pln',
      'pdam',
      'telkom',
      'indihome',
      'internet',
      'wifi',
      'pulsa',
      'token',
      'electricity',
      'listrik',
      'air',
    ],
    'Belanja': [
      'indomaret',
      'alfamart',
      'alfamidi',
      'superindo',
      'hypermart',
      'mall',
      'tokopedia',
      'shopee',
      'lazada',
      'uniqlo',
      'h&m',
      'department store',
    ],
    'Kesehatan': [
      'apotek',
      'pharmacy',
      'kimia farma',
      'guardian',
      'watsons',
      'klinik',
      'hospital',
      'rumah sakit',
      'laboratorium',
    ],
    'Hiburan': [
      'cinema',
      'xxi',
      'cgv',
      'spotify',
      'netflix',
      'youtube',
      'game',
      'playstation',
      'steam',
      'timezone',
    ],
  };

  String suggest(String? merchant, {String rawText = ''}) {
    final haystack = '${merchant ?? ''} $rawText'.toLowerCase();
    var bestCategory = 'Lainnya';
    var bestScore = 0;
    for (final entry in _keywords.entries) {
      final score = entry.value.where(haystack.contains).length;
      if (score > bestScore) {
        bestScore = score;
        bestCategory = entry.key;
      }
    }
    return bestCategory;
  }
}
