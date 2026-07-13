import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/split_part_model.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';

class SplitReceiptScreen extends StatefulWidget {
  const SplitReceiptScreen({
    super.key,
    required this.total,
    required this.initialCategory,
    this.initialParts = const [],
  });

  final double total;
  final String initialCategory;
  final List<SplitPartModel> initialParts;

  @override
  State<SplitReceiptScreen> createState() => _SplitReceiptScreenState();
}

class _SplitReceiptScreenState extends State<SplitReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  late final List<_EditablePart> _parts;

  double get _allocated => _parts.fold(
    0,
    (sum, part) => sum + (parseRupiahInput(part.controller.text) ?? 0),
  );
  double get _remaining => widget.total - _allocated;

  @override
  void initState() {
    super.initState();
    _parts = widget.initialParts.isEmpty
        ? [
            _EditablePart(
              category: widget.initialCategory,
              amount: widget.total,
              label: '',
            ),
          ]
        : widget.initialParts
              .map(
                (part) => _EditablePart(
                  category: part.category,
                  amount: part.amount,
                  label: part.label,
                ),
              )
              .toList();
  }

  @override
  void dispose() {
    for (final part in _parts) {
      part.controller.dispose();
      part.labelController.dispose();
    }
    super.dispose();
  }

  void _addPart() {
    final amount = _remaining > 0 ? _remaining : 0.0;
    setState(
      () => _parts.add(
        _EditablePart(
          category: expenseCategories.first.name,
          amount: amount,
          label: '',
        ),
      ),
    );
  }

  void _removePart(int index) {
    final part = _parts.removeAt(index);
    part.controller.dispose();
    part.labelController.dispose();
    setState(() {});
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_parts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal dua bagian.')),
      );
      return;
    }
    if (_remaining.abs() > .5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _remaining > 0
                ? 'Masih ada ${formatRupiah(_remaining)} yang belum dibagi.'
                : 'Pembagian melebihi total sebesar ${formatRupiah(-_remaining)}.',
          ),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      _parts
          .map(
            (part) => SplitPartModel(
              amount: parseRupiahInput(part.controller.text)!,
              category: part.category,
              label: part.labelController.text.trim(),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bagi transaksi')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: pundiLilac,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(Icons.call_split_rounded, color: pundiViolet),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total transaksi',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        formatRupiah(widget.total),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _remaining.abs() <= .5
                      ? 'Pas'
                      : 'Sisa ${formatRupiah(_remaining)}',
                  style: TextStyle(
                    color: _remaining.abs() <= .5 ? successTeal : pundiCoral,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(_parts.length, (index) {
            final part = _parts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: pundiViolet,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: part.labelController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Nama item (opsional)',
                            ),
                          ),
                          const SizedBox(height: 9),
                          TextFormField(
                            controller: part.controller,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Nominal',
                              prefixText: 'Rp ',
                            ),
                            validator: (value) =>
                                (parseRupiahInput(value ?? '') ?? 0) <= 0
                                ? 'Nominal wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 9),
                          DropdownButtonFormField<String>(
                            initialValue: part.category,
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                            ),
                            items: expenseCategories
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category.name,
                                    child: Text(category.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(
                              () => part.category = value ?? part.category,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_parts.length > 1)
                      IconButton(
                        onPressed: () => _removePart(index),
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: _addPart,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah bagian'),
          ),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Gunakan pembagian'),
        ),
      ),
    ),
  );
}

class _EditablePart {
  _EditablePart({
    required this.category,
    required double amount,
    required String label,
  }) : labelController = TextEditingController(text: label),
       controller = TextEditingController(
         text: amount <= 0 ? '' : amount.toStringAsFixed(0),
       );

  String category;
  final TextEditingController controller;
  final TextEditingController labelController;
}
