// lib/features/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/todo_provider.dart';
import '../../shared/widgets/app_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().authToken;
      if (token != null) {
        context.read<TodoProvider>().loadTodos(authToken: token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.watch<AuthProvider>().user;
    final provider = context.watch<TodoProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    final totalTodos = provider.totalTodos;
    final doneTodos = provider.doneTodos;
    final pendingTodos = provider.pendingTodos;

    final totalRatio = totalTodos == 0 ? 0.0 : 1.0;
    final doneRatio = totalTodos == 0 ? 0.0 : doneTodos / totalTodos;
    final pendingRatio = totalTodos == 0 ? 0.0 : pendingTodos / totalTodos;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, ${user?.name ?? '-'}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Kelola todo hari ini',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            onPressed: themeProvider.toggleTheme,
            icon: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            ),
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppBackground(
        showTopGlow: false,
        child: RefreshIndicator(
          onRefresh: () async {
            final token = context.read<AuthProvider>().authToken;
            if (token != null) {
              await context.read<TodoProvider>().loadTodos(authToken: token);
            }
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: [
              _HomeHero(
                totalTodos: totalTodos,
                doneTodos: doneTodos,
                pendingTodos: pendingTodos,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StatCard(
                    label: 'Total',
                    value: totalTodos,
                    ratio: totalRatio,
                    percentageText: totalTodos == 0 ? '0%' : '100%',
                    color: colorScheme.primary,
                    icon: Icons.list_alt_rounded,
                  ),
                  _StatCard(
                    label: 'Selesai',
                    value: doneTodos,
                    ratio: doneRatio,
                    percentageText: '${(doneRatio * 100).toStringAsFixed(0)}%',
                    color: const Color(0xFF10B981),
                    icon: Icons.check_circle_rounded,
                  ),
                  _StatCard(
                    label: 'Belum',
                    value: pendingTodos,
                    ratio: pendingRatio,
                    percentageText:
                        '${(pendingRatio * 100).toStringAsFixed(0)}%',
                    color: const Color(0xFFFF9F1C),
                    icon: Icons.pending_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Akses Cepat',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              _QuickAccessCard(
                icon: Icons.checklist_rounded,
                title: 'Daftar Todo',
                subtitle: 'Lihat dan kelola semua todo',
                color: colorScheme.primary,
                onTap: () => context.go(RouteConstants.todos),
              ),
              const SizedBox(height: 10),
              _QuickAccessCard(
                icon: Icons.add_task_rounded,
                title: 'Todo Baru',
                subtitle: 'Tambahkan todo baru',
                color: colorScheme.secondary,
                onTap: () => context.push(RouteConstants.todosAdd),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.totalTodos,
    required this.doneTodos,
    required this.pendingTodos,
  });

  final int totalTodos;
  final int doneTodos;
  final int pendingTodos;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Produktivitas Hari Ini',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Selesaikan prioritas penting, satu per satu.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniBadge(
                icon: Icons.list_alt_rounded,
                label: '$totalTodos tugas',
              ),
              const SizedBox(width: 8),
              _MiniBadge(
                icon: Icons.check_circle_rounded,
                label: '$doneTodos selesai',
              ),
              const SizedBox(width: 8),
              _MiniBadge(
                icon: Icons.pending_rounded,
                label: '$pendingTodos belum',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.ratio,
    required this.percentageText,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final double ratio;
  final String percentageText;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cardWidth = (MediaQuery.of(context).size.width - 44) / 2;
    return SizedBox(
      width: cardWidth,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withValues(alpha: 0.16),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 10),
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 4),
                  Text(
                    '($percentageText)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                borderRadius: BorderRadius.circular(999),
                color: color,
                backgroundColor: color.withValues(alpha: 0.18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: color.withValues(alpha: 0.16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
