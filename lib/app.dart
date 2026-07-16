import 'package:flutter/material.dart';

import 'screens/app_shell.dart';
import 'utils/constants.dart';
import 'widgets/app_lock_gate.dart';

class PundiApp extends StatelessWidget {
  const PundiApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Pundi',
    debugShowCheckedModeBanner: false,
    themeMode: ThemeMode.system,
    theme: _theme(Brightness.light),
    darkTheme: _theme(Brightness.dark),
    home: const AppLockGate(child: AppShell()),
  );

  ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? const Color(0xFF9DB7FF) : fintechBlue;
    final secondary = isDark ? const Color(0xFF5EEAD4) : fintechAccent;
    final error = isDark ? const Color(0xFFFFB2BE) : dangerRed;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: fintechBlue,
          brightness: brightness,
          surface: isDark ? darkCanvas : warmSurface,
        ).copyWith(
          primary: primary,
          onPrimary: isDark ? fintechNavy : Colors.white,
          secondary: secondary,
          onSecondary: isDark ? const Color(0xFF003731) : Colors.white,
          secondaryContainer: isDark
              ? const Color(0xFF124E48)
              : const Color(0xFFD2F5EF),
          onSecondaryContainer: isDark
              ? const Color(0xFFB5EEE6)
              : const Color(0xFF064E46),
          tertiary: isDark ? const Color(0xFFFFD166) : const Color(0xFF7A5900),
          onTertiary: isDark ? const Color(0xFF402D00) : Colors.white,
          tertiaryContainer: isDark
              ? const Color(0xFF5B4300)
              : const Color(0xFFFFE08A),
          onTertiaryContainer: isDark
              ? const Color(0xFFFFE4A3)
              : const Color(0xFF2B1F00),
          error: error,
          onError: isDark ? const Color(0xFF68001F) : Colors.white,
          surface: isDark ? darkCanvas : warmSurface,
        );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'sans-serif',
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FintechPageTransitionBuilder(),
          TargetPlatform.iOS: _FintechPageTransitionBuilder(),
        },
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        bodyColor: isDark ? const Color(0xFFF2EDF7) : inkColor,
        displayColor: isDark ? const Color(0xFFF2EDF7) : inkColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? darkCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: isDark ? .18 : .5),
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkCard : Colors.white,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .55),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: .45),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF1E293B) : fintechNavy,
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: isDark
            ? const Color(0xFF9DB7FF)
            : const Color(0xFFBFD0FF),
        disabledActionTextColor: Colors.white54,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? darkCard : Colors.white,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 14,
          height: 1.4,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? darkCard : Colors.white,
        modalBackgroundColor: isDark ? darkCard : Colors.white,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: scheme.onSurfaceVariant,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? darkCard : Colors.white,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      listTileTheme: ListTileThemeData(
        textColor: scheme.onSurface,
        iconColor: scheme.onSurfaceVariant,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: .3),
        selectionHandleColor: scheme.primary,
      ),
    );
  }
}

class _FintechPageTransitionBuilder extends PageTransitionsBuilder {
  const _FintechPageTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(.025, .015),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
