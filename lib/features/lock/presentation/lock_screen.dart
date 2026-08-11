import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/auth_cubit.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-trigger auth as soon as the screen is visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthCubit>().authenticate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Mark ────────────────────────────────────────────────
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: scheme.inverseSurface,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'CV',
                    style: text.titleLarge?.copyWith(
                      color: scheme.onInverseSurface,
                      fontFamily: 'PlayfairDisplay',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Card Vault', style: text.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Locked. Unlock to view your cards.',
                  style: text.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // ── Auth UI ─────────────────────────────────────────────
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final canTap = !state.isAuthenticating && state.canRetry;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _UnlockButton(
                          busy: state.isAuthenticating,
                          onTap: canTap
                              ? () =>
                                  context.read<AuthCubit>().authenticate()
                              : null,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          state.isAuthenticating
                              ? 'Unlocking…'
                              : (state.phase == AuthPhase.failed
                                  ? 'Tap to try again'
                                  : 'Tap to unlock'),
                          style: text.bodySmall,
                        ),
                        if (state.errorText != null) ...[
                          const SizedBox(height: 20),
                          _ErrorNote(message: state.errorText!),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Unlock button ────────────────────────────────────────────────────────────

/// The tappable fingerprint circle. Deliberately doesn't say "Face ID" —
/// that's an Apple/iOS term, and this is an Android app where the same
/// biometric prompt could just as easily be a fingerprint sensor.
class _UnlockButton extends StatelessWidget {
  const _UnlockButton({required this.busy, required this.onTap});
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: scheme.shadow.withValues(alpha: 0.15),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 88,
          height: 88,
          child: Center(
            child: busy
                ? SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: scheme.primary,
                    ),
                  )
                : Icon(Icons.fingerprint, size: 40, color: scheme.primary),
          ),
        ),
      ),
    );
  }
}

// ─── Error note ───────────────────────────────────────────────────────────────

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: scheme.onErrorContainer, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
