import 'dart:io';

import 'package:flutter/material.dart';

import '../services/receipt_image_editor_service.dart';
import '../utils/constants.dart';

class ReceiptImageEditorScreen extends StatefulWidget {
  const ReceiptImageEditorScreen({super.key, required this.sourcePath});

  final String sourcePath;

  @override
  State<ReceiptImageEditorScreen> createState() =>
      _ReceiptImageEditorScreenState();
}

class _ReceiptImageEditorScreenState extends State<ReceiptImageEditorScreen> {
  final _editor = ReceiptImageEditorService();
  late String _path;
  bool _busy = false;
  bool _enhanced = false;

  @override
  void initState() {
    super.initState();
    _path = widget.sourcePath;
  }

  Future<void> _run(Future<String?> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await action();
      if (result != null && mounted) setState(() => _path = result);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengedit gambar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Rapikan struk'),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, _path),
          child: const Text('Baca OCR'),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.file(
                File(_path),
                key: ValueKey(_path),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.broken_image_outlined, color: Colors.white),
                ),
              ),
            ),
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 3),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Potong area di luar struk, luruskan orientasi, lalu tingkatkan kontras bila tulisan terlihat pudar.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(() => _editor.crop(context, _path)),
                        icon: const Icon(Icons.crop_rotate_rounded),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Potong', maxLines: 1, softWrap: false),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(() => _editor.rotateClockwise(_path)),
                        icon: const Icon(Icons.rotate_90_degrees_cw_rounded),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Putar', maxLines: 1, softWrap: false),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _busy || _enhanced
                            ? null
                            : () => _run(() async {
                                final result = await _editor.enhance(_path);
                                if (mounted) setState(() => _enhanced = true);
                                return result;
                              }),
                        icon: const Icon(Icons.auto_fix_high_rounded),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _enhanced ? 'Tajam' : 'Perjelas',
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          foregroundColor: pundiViolet,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
