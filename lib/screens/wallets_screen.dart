import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/wallet_model.dart';
import '../providers/wallet_provider.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import 'wallet_transfers_screen.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet & akun')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: pundiCoral,
        foregroundColor: Colors.white,
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => const _WalletEditor(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Wallet baru'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: pundiViolet,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL SEMUA WALLET',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatRupiah(provider.totalBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletTransfersScreen()),
            ),
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Transfer antar-wallet'),
          ),
          const SizedBox(height: 14),
          ...provider.wallets.map(
            (wallet) => Card(
              margin: const EdgeInsets.only(bottom: 9),
              child: ListTile(
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: wallet.color.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(wallet.icon, color: wallet.color),
                ),
                title: Text(
                  wallet.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  'Saldo awal ${formatRupiah(wallet.initialBalance)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatRupiah(provider.balanceFor(wallet.id!)),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (_) => _WalletEditor(wallet: wallet),
                          );
                        } else {
                          try {
                            await provider.delete(wallet);
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        if (wallet.id != 1)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Hapus'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletEditor extends StatefulWidget {
  const _WalletEditor({this.wallet});
  final WalletModel? wallet;

  @override
  State<_WalletEditor> createState() => _WalletEditorState();
}

class _WalletEditorState extends State<_WalletEditor> {
  static const _colors = [
    pundiViolet,
    pundiCoral,
    successTeal,
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
  ];
  late final TextEditingController _name;
  late final TextEditingController _balance;
  late IconData _icon;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.wallet?.name ?? '');
    _balance = TextEditingController(
      text: widget.wallet == null
          ? ''
          : widget.wallet!.initialBalance.toStringAsFixed(0),
    );
    _icon = widget.wallet?.icon ?? WalletModel.supportedIcons.first;
    _color = widget.wallet?.color ?? _colors.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    await context.read<WalletProvider>().save(
      WalletModel(
        id: widget.wallet?.id,
        name: _name.text.trim(),
        iconCode: _icon.codePoint,
        colorValue: _color.toARGB32(),
        initialBalance: parseRupiahInput(_balance.text) ?? 0,
        createdAt: widget.wallet?.createdAt,
      ),
    );
    if (mounted) Navigator.pop(context);
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
            const Text(
              'Detail wallet',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nama wallet'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _balance,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Saldo awal',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: WalletModel.supportedIcons
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: _colors
                  .map(
                    (color) => GestureDetector(
                      onTap: () => setState(() => _color = color),
                      child: Container(
                        width: 36,
                        height: 36,
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
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Simpan wallet'),
            ),
          ],
        ),
      ),
    ),
  );
}
