import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/wallet_transfer_model.dart';
import '../providers/wallet_provider.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class WalletTransfersScreen extends StatelessWidget {
  const WalletTransfersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Transfer antar-wallet')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: fintechBlue,
        foregroundColor: Colors.white,
        onPressed: provider.wallets.length < 2
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransferEditorScreen()),
              ),
        icon: const Icon(Icons.swap_horiz_rounded),
        label: const Text('Transfer'),
      ),
      body: provider.wallets.length < 2
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(38),
                child: Text(
                  'Buat minimal dua wallet sebelum melakukan transfer.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : provider.transfers.isEmpty
          ? const Center(child: Text('Belum ada transfer.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: provider.transfers.length,
              itemBuilder: (context, index) {
                final transfer = provider.transfers[index];
                final from = provider.walletFor(transfer.fromWalletId);
                final to = provider.walletFor(transfer.toWalletId);
                return Card(
                  margin: const EdgeInsets.only(bottom: 9),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: pundiLilac,
                      child: Icon(Icons.swap_horiz_rounded, color: pundiViolet),
                    ),
                    title: Text(
                      '${from.name} → ${to.name}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      '${formatDate(transfer.date)}${transfer.note.isEmpty ? '' : ' · ${transfer.note}'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatRupiah(transfer.amount),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) => value == 'edit'
                              ? Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TransferEditorScreen(
                                      transfer: transfer,
                                    ),
                                  ),
                                )
                              : provider.deleteTransfer(transfer),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Hapus'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class TransferEditorScreen extends StatefulWidget {
  const TransferEditorScreen({super.key, this.transfer});
  final WalletTransferModel? transfer;

  @override
  State<TransferEditorScreen> createState() => _TransferEditorScreenState();
}

class _TransferEditorScreenState extends State<TransferEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late int _fromWalletId;
  late int _toWalletId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final wallets = context.read<WalletProvider>().wallets;
    _fromWalletId = widget.transfer?.fromWalletId ?? wallets.first.id!;
    _toWalletId = widget.transfer?.toWalletId ?? wallets[1].id!;
    _date = widget.transfer?.date ?? DateTime.now();
    _amount = TextEditingController(
      text: widget.transfer == null
          ? ''
          : widget.transfer!.amount.toStringAsFixed(0),
    );
    _note = TextEditingController(text: widget.transfer?.note ?? '');
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<WalletProvider>().saveTransfer(
      WalletTransferModel(
        id: widget.transfer?.id,
        fromWalletId: _fromWalletId,
        toWalletId: _toWalletId,
        amount: parseRupiahInput(_amount.text)!,
        date: _date,
        note: _note.text.trim(),
        createdAt: widget.transfer?.createdAt,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final wallets = context.watch<WalletProvider>().wallets;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transfer == null ? 'Transfer baru' : 'Edit transfer',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            DropdownButtonFormField<int>(
              initialValue: _fromWalletId,
              decoration: const InputDecoration(labelText: 'Dari wallet'),
              items: wallets
                  .map(
                    (wallet) => DropdownMenuItem(
                      value: wallet.id,
                      child: Text(wallet.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _fromWalletId = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _toWalletId,
              decoration: const InputDecoration(labelText: 'Ke wallet'),
              items: wallets
                  .map(
                    (wallet) => DropdownMenuItem(
                      value: wallet.id,
                      child: Text(wallet.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _toWalletId = value!),
              validator: (_) => _fromWalletId == _toWalletId
                  ? 'Wallet tujuan harus berbeda'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
              ),
              validator: (value) => (parseRupiahInput(value ?? '') ?? 0) <= 0
                  ? 'Masukkan nominal lebih dari 0'
                  : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              leading: const Icon(Icons.event_rounded),
              title: const Text('Tanggal'),
              subtitle: Text(formatDate(_date)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Catatan'),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Simpan transfer'),
            ),
          ],
        ),
      ),
    );
  }
}
