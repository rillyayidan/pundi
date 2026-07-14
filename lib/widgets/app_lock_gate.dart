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

class _AppLockGateState extends State<AppLockGate> {
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    NotificationService.tappedPayload.addListener(_handlePayload);
  }

  @override
  void dispose() {
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

  Future<void> _unlock() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    await context.read<AppFeaturesProvider>().unlock();
    if (mounted) setState(() => _authenticating = false);
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: dark
                ? const [darkCanvas, Color(0xFF0D2341)]
                : const [Color(0xFFEAF1FF), warmSurface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [fintechNavy, fintechBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: fintechBlue.withValues(alpha: .22),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Verifikasi perangkat',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.8,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'Cukup sekali setelah HP dinyalakan ulang. Membuka kamera atau berpindah aplikasi tidak akan meminta verifikasi lagi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 26),
                        FilledButton(
                          onPressed: _authenticating ? null : _unlock,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: _authenticating
                                ? const SizedBox.square(
                                    key: ValueKey('loading'),
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    key: ValueKey('action'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.fingerprint_rounded),
                                      SizedBox(width: 9),
                                      Text('Verifikasi dan buka'),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 14,
                              color: fintechAccent,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Data tetap tersimpan offline',
                              style: TextStyle(
                                color: fintechAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
