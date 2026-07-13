import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_features_provider.dart';
import '../utils/constants.dart';
import '../screens/onboarding_screen.dart';
import '../screens/recurring_screen.dart';
import '../screens/settings_screen.dart';
import '../services/notification_service.dart';

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
    NotificationService.tappedPayload.addListener(_handlePayload);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.tappedPayload.removeListener(_handlePayload);
    super.dispose();
  }

  void _handlePayload() {
    final payload = NotificationService.tappedPayload.value;
    if (payload == null || !mounted) return;
    final features = context.read<AppFeaturesProvider>();
    if (!features.initialized || features.locked || !features.onboardingSeen) {
      return;
    }
    NotificationService.tappedPayload.value = null;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => payload.startsWith('recurring:')
            ? const RecurringScreen()
            : const SettingsScreen(),
      ),
    );
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
    if (!features.onboardingSeen) return const OnboardingScreen();
    if (!features.locked) {
      final payload = NotificationService.tappedPayload.value;
      if (payload != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _handlePayload());
      }
      return widget.child;
    }
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
