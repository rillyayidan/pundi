import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_features_provider.dart';
import '../utils/constants.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      context.read<AppFeaturesProvider>().lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final features = context.watch<AppFeaturesProvider>();
    if (!features.initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!features.locked) return widget.child;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: pundiLilac,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: pundiViolet,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Pundi terkunci',
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gunakan keamanan perangkat untuk membuka data keuanganmu.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: features.unlock,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Buka Pundi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
