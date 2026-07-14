import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/parsed_bill_model.dart';
import '../services/bill_parser_service.dart';
import '../services/ocr_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/confidence_badge.dart';
import 'add_transaction_screen.dart';
import 'receipt_image_editor_screen.dart';

class ScanBillScreen extends StatefulWidget {
  const ScanBillScreen({super.key});

  @override
  State<ScanBillScreen> createState() => _ScanBillScreenState();
}

class _ScanBillScreenState extends State<ScanBillScreen> {
  final _picker = ImagePicker();
  final _parser = BillParserService();
  late final OcrService _ocr;
  ParsedBillModel? _result;
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ocr = OcrService();
  }

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _scan(ImageSource source) async {
    setState(() {
      _error = null;
      _result = null;
    });
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 2200,
    );
    if (image == null) {
      return;
    }
    if (!mounted) return;
    final editedPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptImageEditorScreen(sourcePath: image.path),
      ),
    );
    if (editedPath == null || !mounted) return;
    setState(() => _processing = true);
    try {
      final text = await _ocr.recognize(editedPath);
      if (text.trim().isEmpty) {
        throw const FormatException(
          'Tidak ada teks yang terdeteksi. Coba foto dengan cahaya lebih terang.',
        );
      }
      final parsed = _parser.parse(text, sourceImagePath: editedPath);
      if (mounted) {
        setState(() => _result = parsed);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('FormatException: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _continue() async {
    final result = _result;
    if (result == null) {
      return;
    }
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(parsedBill: result),
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        _result = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi hasil pindai tersimpan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
      children: [
        const Text(
          'SMART SCAN',
          style: TextStyle(
            color: pundiCoral,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Struk masuk, beres.',
          style: TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 17),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [pundiViolet, pundiVioletDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            children: [
              Icon(Icons.document_scanner_rounded, size: 66, color: pundiAmber),
              const SizedBox(height: 14),
              const Text(
                'Foto struk, biar Pundi yang membaca',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pemrosesan OCR berjalan di perangkat. Hasilnya selalu bisa kamu koreksi sebelum disimpan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _processing ? null : () => _scan(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Kamera'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _processing
                    ? null
                    : () => _scan(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galeri'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
              ),
            ),
          ],
        ),
        if (_processing) ...[
          const SizedBox(height: 32),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 12),
          const Center(child: Text('Membaca struk...')),
        ],
        if (_error != null) ...[
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_error!)),
                ],
              ),
            ),
          ),
        ],
        if (_result != null) ...[
          const SizedBox(height: 26),
          Text(
            'Hasil pembacaan',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _ResultRow(
                    label: 'Jumlah',
                    value: _result!.amount == null
                        ? 'Tidak ditemukan'
                        : formatRupiah(_result!.amount!),
                    confidence: _result!.amountConfidence,
                  ),
                  if (_result!.lineItems.isNotEmpty) ...[
                    const Divider(height: 26),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_result!.lineItems.length} item terdeteksi',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._result!.lineItems
                        .take(5)
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  formatRupiah(item.amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                  const Divider(height: 26),
                  _ResultRow(
                    label: 'Merchant',
                    value: _result!.merchant ?? 'Tidak ditemukan',
                    confidence: _result!.merchantConfidence,
                  ),
                  const Divider(height: 26),
                  _ResultRow(
                    label: 'Tanggal',
                    value: _result!.date == null
                        ? 'Tidak ditemukan'
                        : formatDate(_result!.date!),
                    confidence: _result!.dateConfidence,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _continue,
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Periksa & lanjutkan'),
          ),
          TextButton.icon(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (_) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: SingleChildScrollView(
                    child: SelectableText(_result!.rawText),
                  ),
                ),
              ),
            ),
            icon: const Icon(Icons.text_snippet_outlined),
            label: const Text('Lihat teks mentah'),
          ),
        ],
      ],
    ),
  );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    required this.confidence,
  });
  final String label;
  final String value;
  final ConfidenceLevel confidence;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      ConfidenceBadge(confidence: confidence),
    ],
  );
}
