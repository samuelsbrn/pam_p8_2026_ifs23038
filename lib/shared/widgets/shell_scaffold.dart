// lib/shared/widgets/shell_scaffold.dart

import 'package:flutter/material.dart';
import 'app_background.dart';
import 'bottom_nav_widget.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false, // Ubah ke false agar konten tidak tertutup Navigation Bar
      body: AppBackground(showTopGlow: false, child: child),
      bottomNavigationBar: const BottomNavWidget(),
    );
  }
}