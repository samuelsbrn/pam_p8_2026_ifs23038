// lib/shared/widgets/top_app_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class TopAppBarMenuItem {
  const TopAppBarMenuItem({
    required this.text,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;
}

class TopAppBarWidget extends StatefulWidget implements PreferredSizeWidget {
  const TopAppBarWidget({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.menuItems = const [],
    this.showThemeToggle = true,
    this.withSearch = false,
    this.onSearchChanged,
    this.searchHint = 'Cari...',
  });

  final String title;
  final bool showBackButton;
  final List<TopAppBarMenuItem> menuItems;
  final bool showThemeToggle;
  final bool withSearch;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<TopAppBarWidget> createState() => _TopAppBarWidgetState();
}

class _TopAppBarWidgetState extends State<TopAppBarWidget> {
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _closeSearch() {
    setState(() => _isSearching = false);
    _searchCtrl.clear();
    widget.onSearchChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _closeSearch,
        ),
        titleSpacing: 0,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.56),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.searchHint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchCtrl.clear();
                        widget.onSearchChanged?.call('');
                        setState(() {});
                      },
                    ),
            ),
            onChanged: (value) {
              widget.onSearchChanged?.call(value);
              setState(() {});
            },
          ),
        ),
      );
    }

    return AppBar(
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      centerTitle: false,
      automaticallyImplyLeading: widget.showBackButton,
      actions: [
        if (widget.withSearch)
          _ActionPill(
            icon: Icons.search_rounded,
            tooltip: 'Cari',
            onTap: () => setState(() => _isSearching = true),
          ),
        if (widget.showThemeToggle)
          _ActionPill(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
            onTap: themeProvider.toggleTheme,
          ),
        if (widget.menuItems.isNotEmpty)
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_horiz_rounded),
            tooltip: 'Menu',
            position: PopupMenuPosition.under,
            onSelected: (index) => widget.menuItems[index].onTap(),
            itemBuilder: (_) => List.generate(
              widget.menuItems.length,
              (index) => PopupMenuItem<int>(
                value: index,
                child: Row(
                  children: [
                    Icon(
                      widget.menuItems[index].icon,
                      size: 20,
                      color: widget.menuItems[index].isDestructive
                          ? colorScheme.error
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.menuItems[index].text,
                      style: TextStyle(
                        color: widget.menuItems[index].isDestructive
                            ? colorScheme.error
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(width: 6),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Tooltip(
            message: tooltip,
            child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 20)),
          ),
        ),
      ),
    );
  }
}
