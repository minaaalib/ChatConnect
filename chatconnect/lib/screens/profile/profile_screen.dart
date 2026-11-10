import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
            children: [
              GlassCard(
                borderRadius: 32,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.avatarUrl != null
                          ? NetworkImage(user!.avatarUrl!)
                          : null,
                      child: user?.avatarUrl == null
                          ? const Icon(
                              PhosphorIconsFill.user,
                              size: 40,
                              color: AppColors.onSurfaceVariant,
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.fullName ?? 'User',
                      style: textTheme.headlineMedium,
                    ),
                    Text(user?.studentId ?? '', style: textTheme.labelMedium),
                    Text(user?.course ?? '', style: textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            PhosphorIconsFill.robot,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user?.kaiCompanionActive == true
                                ? '🤖 KAI COMPANION: ACTIVE'
                                : '🤖 KAI COMPANION: OFF',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('Edit Profile'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GlassCard(
                borderColor: AppColors.primary.withValues(alpha: 0.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          PhosphorIconsFill.robot,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Kai Companion Settings',
                          style: textTheme.headlineSmall?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Kai Chat'),
                      value: user?.kaiCompanionActive ?? true,
                      activeThumbColor: AppColors.primary,
                      onChanged: auth.toggleKaiCompanion,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('AI Mood Insights'),
                      value: true,
                      activeThumbColor: AppColors.primary,
                      onChanged: (_) {},
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('AI Crisis Detection'),
                      value: true,
                      activeThumbColor: AppColors.primary,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SettingsGroup(
                title: 'Account',
                items: const [
                  _SettingsItem(
                    icon: PhosphorIconsFill.gearSix,
                    label: 'Account Settings',
                  ),
                  _SettingsItem(
                    icon: PhosphorIconsFill.shield,
                    label: 'Privacy Controls',
                  ),
                  _SettingsItem(
                    icon: PhosphorIconsFill.bell,
                    label: 'Notification Preferences',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsGroup(
                title: 'Therapy',
                items: const [
                  _SettingsItem(
                    icon: PhosphorIconsFill.heart,
                    label: 'Therapy Preferences',
                  ),
                  _SettingsItem(
                    icon: PhosphorIconsFill.phoneCall,
                    label: 'Emergency Contact',
                  ),
                  _SettingsItem(
                    icon: PhosphorIconsFill.warning,
                    label: 'Crisis Resources',
                    danger: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsGroup(
                title: 'AI Features',
                items: const [
                  _SettingsItem(
                    icon: PhosphorIconsFill.brain,
                    label: 'Kai Chat History',
                  ),
                  _SettingsItem(
                    icon: PhosphorIconsFill.heartbeat,
                    label: 'AI Mood Analysis',
                  ),
                  _SettingsItem(
                    icon: PhosphorIconsFill.lightbulb,
                    label: 'AI Recommendations',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsGroup(
                title: 'Support',
                items: const [
                  _SettingsItem(
                    icon: PhosphorIconsFill.question,
                    label: 'Help & Support',
                  ),
                  _SettingsItem(
                    icon: PhosphorIconsFill.info,
                    label: 'About ChatConnect',
                  ),
                  _SettingsItem(
                    icon: PhosphorIconsFill.lockKey,
                    label: 'AI Privacy Policy',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'DANGER ZONE',
                style: textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.5,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 8),
              GlassCard(
                padding: EdgeInsets.zero,
                borderRadius: 16,
                child: Column(
                  children: [
                    _DangerTile(
                      icon: PhosphorIconsFill.signOut,
                      label: 'Log Out',
                      onTap: () => context.read<AuthService>().signOut(),
                    ),
                    _DangerTile(
                      icon: PhosphorIconsFill.trash,
                      label: 'Delete Account',
                      onTap: () {},
                    ),
                    _DangerTile(
                      icon: PhosphorIconsFill.database,
                      label: 'Clear AI Data',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.items});

  final String title;
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: textTheme.labelMedium?.copyWith(letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              borderRadius: 16,
              padding: EdgeInsets.zero,
              borderColor: item.danger
                  ? AppColors.tertiaryFixedDim.withValues(alpha: 0.4)
                  : null,
              child: ListTile(
                leading: Icon(
                  item.icon,
                  color: item.danger ? AppColors.tertiary : AppColors.primary,
                ),
                title: Text(
                  item.label,
                  style: TextStyle(
                    color: item.danger ? AppColors.tertiary : null,
                  ),
                ),
                trailing: Icon(
                  PhosphorIconsBold.caretRight,
                  color: item.danger ? AppColors.tertiary : AppColors.outline,
                ),
                onTap: () {},
              ),
            ),
          ),
      ],
    );
  }
}

class _DangerTile extends StatelessWidget {
  const _DangerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.error),
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
