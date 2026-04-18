// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/todo_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => TodoProvider()),
      ],
      child: const DelcomTodosApp(),
    ),
  );
}

class DelcomTodosApp extends StatefulWidget {
  const DelcomTodosApp({super.key});

  @override
  State<DelcomTodosApp> createState() => _DelcomTodosAppState();
}

class _DelcomTodosAppState extends State<DelcomTodosApp> {
  late final _router = buildRouter(context);

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;

    return MaterialApp.router(
      title: 'Delcom Todos',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      routerConfig: _router,
    );
  }
}

ThemeData _buildLightTheme() {
  const baseSeed = Color(0xFF2667FF);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: baseSeed,
    brightness: Brightness.light,
    primary: const Color(0xFF2667FF),
    secondary: const Color(0xFF00A896),
    tertiary: const Color(0xFFFF9F1C),
    surface: const Color(0xFFF8FAFF),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFFF8FAFF),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: Typography.blackMountainView.copyWith(
      headlineMedium: const TextStyle(fontWeight: FontWeight.w800),
      headlineSmall: const TextStyle(fontWeight: FontWeight.w700),
      titleLarge: const TextStyle(fontWeight: FontWeight.w700),
      titleMedium: const TextStyle(fontWeight: FontWeight.w700),
      bodyMedium: const TextStyle(height: 1.35),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      color: Colors.white.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.86),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
      ),
      prefixIconColor: colorScheme.primary,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: Colors.white.withValues(alpha: 0.92),
      indicatorColor: colorScheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      side: BorderSide(color: colorScheme.outlineVariant),
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.primary,
      labelStyle: TextStyle(color: colorScheme.onSurface),
      secondaryLabelStyle: TextStyle(color: colorScheme.primary),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.primary.withValues(alpha: 0.16),
      circularTrackColor: colorScheme.primary.withValues(alpha: 0.2),
    ),
    dividerTheme: DividerThemeData(color: colorScheme.outlineVariant),
  );
}

ThemeData _buildDarkTheme() {
  const baseSeed = Color(0xFF4CC9F0);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: baseSeed,
    brightness: Brightness.dark,
    primary: const Color(0xFF70A8FF),
    secondary: const Color(0xFF59D4C5),
    tertiary: const Color(0xFFFFB95A),
    surface: const Color(0xFF121826),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFF0E1420),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: Typography.whiteMountainView.copyWith(
      headlineMedium: const TextStyle(fontWeight: FontWeight.w800),
      headlineSmall: const TextStyle(fontWeight: FontWeight.w700),
      titleLarge: const TextStyle(fontWeight: FontWeight.w700),
      titleMedium: const TextStyle(fontWeight: FontWeight.w700),
      bodyMedium: const TextStyle(height: 1.35),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      color: const Color(0xFF182234).withValues(alpha: 0.86),
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A2437).withValues(alpha: 0.85),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
      ),
      prefixIconColor: colorScheme.primary,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: const Color(0xFF152033).withValues(alpha: 0.96),
      indicatorColor: const Color(0xFF2A3E5D),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      side: BorderSide(color: colorScheme.outlineVariant),
      selectedColor: const Color(0xFF2A3E5D),
      checkmarkColor: colorScheme.primary,
      labelStyle: TextStyle(color: colorScheme.onSurface),
      secondaryLabelStyle: TextStyle(color: colorScheme.primary),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.primary.withValues(alpha: 0.16),
      circularTrackColor: colorScheme.primary.withValues(alpha: 0.2),
    ),
    dividerTheme: DividerThemeData(color: colorScheme.outlineVariant),
  );
}
