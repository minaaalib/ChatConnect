import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/clay.dart';
import '../../chat/widgets/sos_overlay.dart';

class DashboardFab extends StatefulWidget {
  const DashboardFab({super.key});

  @override
  State<DashboardFab> createState() => _DashboardFabState();
}

class _DashboardFabState extends State<DashboardFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  bool _open = false;

  static const _actions = [
    (
      label: 'Journal',
      icon: PhosphorIconsFill.notePencil,
      color: AppColors.tertiary,
    ),
    (
      label: 'Crisis Help',
      icon: PhosphorIconsFill.firstAidKit,
      color: AppColors.error,
    ),
    (
      label: 'Book Counselor',
      icon: PhosphorIconsFill.calendarBlank,
      color: AppColors.secondary,
    ),
    (
      label: 'Chat with Kai',
      icon: PhosphorIconsFill.chatCircle,
      color: AppColors.primaryContainer,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _close() {
    if (!_open) return;
    setState(() => _open = false);
    _controller.reverse();
  }

  void _handleAction(int index) {
    _close();
    final label = _actions[index].label;
    if (label == 'Journal') {
      context.push('/journal');
    } else if (label == 'Chat with Kai') {
      context.go('/chat/session-kai-main');
    } else if (label == 'Crisis Help') {
      SosOverlay.show(
        context,
        onConnectCounselor: () => context.go('/chat/session-counselor-1'),
      );
    } else if (label == 'Book Counselor') {
      context.push('/appointment');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        if (_open)
          Positioned(
            top: -1000,
            left: -1000,
            right: -1000,
            bottom: -1000,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: const SizedBox.shrink(),
            ),
          ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < _actions.length; i++)
              _AnimatedFabOption(
                controller: _controller,
                // Staggers each option so they pop in one after another
                // instead of all at once, reading as a single motion.
                interval: Interval(i * 0.08, 1.0, curve: Curves.easeOutBack),
                action: _actions[i],
                onTap: () => _handleAction(i),
              ),
            FloatingActionButton(
              backgroundColor: AppColors.primaryContainer,
              onPressed: _toggle,
              child: AnimatedRotation(
                turns: _open ? 0.125 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  PhosphorIconsBold.plus,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnimatedFabOption extends StatelessWidget {
  const _AnimatedFabOption({
    required this.controller,
    required this.interval,
    required this.action,
    required this.onTap,
  });

  final AnimationController controller;
  final Interval interval;
  final ({String label, IconData icon, Color color}) action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(parent: controller, curve: interval);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: animation.value.clamp(0.0, 1.0),
            alignment: Alignment.centerRight,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _FabOption(
          label: action.label,
          icon: action.icon,
          color: action.color,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _FabOption extends StatelessWidget {
  const _FabOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.only(left: 16, right: 6, top: 6, bottom: 6),
          decoration: BoxDecoration(
            color: AppColors.claySurface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: clayShadows(0.6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundColor: color,
                child: Icon(icon, size: 18, color: AppColors.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
