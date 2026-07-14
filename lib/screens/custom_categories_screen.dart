import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/category_provider.dart';
import '../utils/constants.dart';

class CustomCategoriesScreen extends StatelessWidget {
  const CustomCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Kategori buatanmu')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: fintechBlue,
        foregroundColor: Colors.white,
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => const _CategoryEditor(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Kategori baru'),
      ),
      body: provider.customCategories.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(36),
                child: Text(
                  'Belum ada kategori khusus. Buat kategori yang paling cocok dengan kebiasaanmu.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: provider.customCategories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final category = provider.customCategories[index];
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(category.icon, color: category.color),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      category.type == 'expense' ? 'Pengeluaran' : 'Pemasukan',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (_) => _CategoryEditor(category: category),
                          );
                        } else {
                          await provider.delete(category);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({this.category});
  final CategoryModel? category;

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  static const _icons = [
    Icons.pets_rounded,
    Icons.school_rounded,
    Icons.home_rounded,
    Icons.flight_rounded,
    Icons.sports_esports_rounded,
    Icons.card_giftcard_rounded,
    Icons.work_rounded,
    Icons.volunteer_activism_rounded,
  ];
  static const _colors = [
    pundiViolet,
    pundiCoral,
    successTeal,
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
  ];

  late final TextEditingController _name;
  late TransactionType _type;
  late IconData _icon;
  late Color _color;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _name = TextEditingController(text: category?.name ?? '');
    _type = category?.type == 'income'
        ? TransactionType.income
        : TransactionType.expense;
    _icon = category?.icon ?? _icons.first;
    _color = category?.color ?? _colors.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    try {
      await context.read<CategoryProvider>().save(
        CategoryModel(
          id: widget.category?.id,
          name: _name.text.trim(),
          icon: _icon,
          color: _color,
          type: _type.name,
          isCustom: true,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category == null ? 'Kategori baru' : 'Edit kategori',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nama kategori'),
            ),
            const SizedBox(height: 12),
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Pengeluaran'),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Pemasukan'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (value) =>
                  setState(() => _type = value.first),
            ),
            const SizedBox(height: 18),
            const Text('Ikon', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _icons
                  .map(
                    (icon) => IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: _icon == icon ? _color : pundiLilac,
                        foregroundColor: _icon == icon
                            ? Colors.white
                            : pundiViolet,
                      ),
                      onPressed: () => setState(() => _icon = icon),
                      icon: Icon(icon),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            const Text('Warna', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _colors
                  .map(
                    (color) => GestureDetector(
                      onTap: () => setState(() => _color = color),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _color == color
                                ? inkColor
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Simpan kategori'),
            ),
          ],
        ),
      ),
    ),
  );
}
