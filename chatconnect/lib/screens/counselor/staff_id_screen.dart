import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/backend_config.dart';
import '../../services/mock_auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';

/// Second sign-in step for counselors: their WVSU staff school ID.
class StaffIdScreen extends StatefulWidget {
  const StaffIdScreen({super.key});

  @override
  State<StaffIdScreen> createState() => _StaffIdScreenState();
}

class _StaffIdScreenState extends State<StaffIdScreen> {
  final _idController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final staffId = _idController.text.trim();
    if (staffId.length < 3) {
      setState(() => _error = 'Enter your staff school ID.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().verifyStaffId(staffId);
    } catch (e) {
      if (mounted) {
        _idController.clear();
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final who = context.watch<AuthService>().pendingStaffIdUser;
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.verifiedContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        PhosphorIconsFill.identificationCard,
                        color: AppColors.verified,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Enter your staff school ID',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            who == null
                                ? 'Step 2 of 2'
                                : 'Step 2 of 2 · signing in as ${who.email}',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _idController,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            maxLength: 20,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9-]'),
                              ),
                            ],
                            style: const TextStyle(
                              fontSize: 24,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w700,
                            ),
                            onSubmitted: (_) => _submitting ? null : _submit(),
                            decoration: const InputDecoration(
                              counterText: '',
                              hintText: 'Staff ID',
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ],
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            child: _submitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Verify'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _submitting
                                ? null
                                : () => context.read<AuthService>().signOut(),
                            child: const Text('Not you? Sign in again'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      BackendConfig.supabaseEnabled
                          ? 'Staff ID not accepted? Ask the system administrator '
                                'to check the ID on file.'
                          : 'Offline demo: the staff school ID is '
                                '${MockAuthService.demoStaffSchoolId}.',
                      textAlign: TextAlign.center,
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
