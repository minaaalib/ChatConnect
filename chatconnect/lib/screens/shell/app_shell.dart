import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../theme/app_colors.dart';
import '../../widgets/clay.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _NavTab(path: '/dashboard', icon: PhosphorIconsFill.house),
    _NavTab(path: '/chat', icon: PhosphorIconsFill.chatCircle),
    _NavTab(path: '/insights', icon: PhosphorIconsFill.chartLineUp),
    _NavTab(path: '/kai-hub', iconAsset: 'assets/pfp.png'),
    _NavTab(path: '/profile', icon: PhosphorIconsFill.user),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/chat/')) return 1;
    final index = _tabs.indexWhere((t) => t.path == location);
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Clay(
          borderRadius: 32,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < _tabs.length; i++)
                _NavIcon(
                  icon: _tabs[i].icon,
                  iconAsset: _tabs[i].iconAsset,
                  selected: i == currentIndex,
                  onTap: () => context.go(_tabs[i].path),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({required this.path, this.icon, this.iconAsset})
    : assert(icon != null || iconAsset != null);

  final String path;
  final IconData? icon;
  final String? iconAsset;
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    this.icon,
    this.iconAsset,
    required this.selected,
    required this.onTap,
  });

  final IconData? icon;
  final String? iconAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.onPrimaryContainer
        : AppColors.onSurfaceVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: selected ? 1.08 : 1,
        child: Clay(
          shape: BoxShape.circle,
          depth: selected ? 0.6 : 0,
          color: selected ? AppColors.primaryContainer : Colors.transparent,
          padding: const EdgeInsets.all(12),
          child: iconAsset != null
              ? ClipOval(
                  child: Image.asset(
                    iconAsset!,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(icon, color: color),
        ),
      ),
    );
  }
}
