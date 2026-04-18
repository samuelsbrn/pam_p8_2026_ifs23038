// lib/shared/widgets/bottom_nav_widget.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/route_constants.dart';

class BottomNavWidget extends StatelessWidget {
  const BottomNavWidget({super.key});

  static const _items = [
    _NavItem(
      RouteConstants.home,
      'Home',
      Icons.home_outlined,
      Icons.home_rounded,
    ),
    _NavItem(
      RouteConstants.todos,
      'Todos',
      Icons.task_outlined,
      Icons.task_rounded,
    ),
    _NavItem(
      RouteConstants.profile,
      'Profil',
      Icons.person_outline_rounded,
      Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).matchedLocation;

    var selectedIndex = 0;
    for (var i = 0; i < _items.length; i++) {
      if (location.startsWith(_items[i].route)) {
        selectedIndex = i;
        break;
      }
    }

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              if (index == selectedIndex) return;
              context.go(_items[index].route);
            },
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: _items
                .map(
                  (item) => NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.activeIcon),
                    label: item.label,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.route, this.label, this.icon, this.activeIcon);

  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}
