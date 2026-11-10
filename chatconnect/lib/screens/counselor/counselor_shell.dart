import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/counselor_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/clay.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/readable_width.dart';

/// Desktop layout for the Guidance Office web app: a sidebar with Inbox and
/// Chats on the left, the selected page on the right. On narrow windows the
/// sidebar shrinks to icons only.
class CounselorShell extends StatelessWidget {
  const CounselorShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final onChats = location.startsWith('/counselor/chats');
    final service = context.watch<CounselorService>();
    final me = context.watch<AuthService>().currentUser;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                child: Clay(
                  borderRadius: 28,
                  padding: EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: wide ? 16 : 10,
                  ),
                  child: SizedBox(
                    width: wide ? 220 : 56,
                    child: Column(
                      crossAxisAlignment: wide
                          ? CrossAxisAlignment.stretch
                          : CrossAxisAlignment.center,
                      children: [
                        _Brand(wide: wide),
                        const SizedBox(height: 28),
                        _NavItem(
                          icon: PhosphorIconsFill.tray,
                          label: 'Inbox',
                          badge: service.inboxBadge,
                          urgent: service.newAlertCount > 0,
                          selected: !onChats,
                          wide: wide,
                          onTap: () => context.go('/counselor'),
                        ),
                        const SizedBox(height: 8),
                        _NavItem(
                          icon: PhosphorIconsFill.chatsCircle,
                          label: 'Chats',
                          badge: service.threadsAwaitingReply,
                          selected: onChats,
                          wide: wide,
                          onTap: () => context.go('/counselor/chats'),
                        ),
                        const Spacer(),
                        if (wide && me != null) ...[
                          Text(
                            me.fullName.isNotEmpty ? me.fullName : 'Counselor',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'Guidance Counselor',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        wide
                            ? OutlinedButton.icon(
                                onPressed: () =>
                                    context.read<AuthService>().signOut(),
                                icon: const Icon(
                                  PhosphorIconsBold.signOut,
                                  size: 18,
                                ),
                                label: const Text('Sign out'),
                              )
                            : IconButton(
                                tooltip: 'Sign out',
                                onPressed: () =>
                                    context.read<AuthService>().signOut(),
                                icon: const Icon(PhosphorIconsBold.signOut),
                                color: AppColors.primary,
                              ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(child: ReadableWidth(maxWidth: 1000, child: child)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (!wide) return Image.asset('assets/logo_icon.png', height: 36);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset('assets/logo.png', height: 36),
        const SizedBox(height: 6),
        const Text(
          'GUIDANCE OFFICE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: AppColors.verified,
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.badge,
    required this.selected,
    required this.wide,
    required this.onTap,
    this.urgent = false,
  });

  final IconData icon;
  final String label;
  final int badge;
  final bool selected;
  final bool wide;
  final bool urgent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.onSurfaceVariant;
    final badgeChip = badge > 0
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: urgent ? AppColors.error : AppColors.tertiary,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              badge > 99 ? '99+' : '$badge',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        : null;

    final tile = Clay(
      borderRadius: 18,
      depth: selected ? 0.6 : 0,
      color: selected ? AppColors.primaryContainer : Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: wide ? 14 : 12, vertical: 12),
      child: Row(
        mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 22),
          if (wide) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: fg, fontWeight: FontWeight.w700),
              ),
            ),
            ?badgeChip,
          ],
        ],
      ),
    );

    return Tooltip(
      message: wide ? '' : label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: wide || badgeChip == null
              ? tile
              : Stack(
                  clipBehavior: Clip.none,
                  children: [
                    tile,
                    Positioned(right: -6, top: -6, child: badgeChip),
                  ],
                ),
        ),
      ),
    );
  }
}
