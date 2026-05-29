import 'package:flutter/material.dart';

import '../../../core/auth/biometric_service.dart';
import '../../../core/di/service_locator.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({required this.onUnlocked, super.key});

  final VoidCallback onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _isAuthenticating = false;
  AuthStatus? _lastStatus;

  final BiometricService _biometricService = sl<BiometricService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _lastStatus = null;
    });
    try {
      final result = await _biometricService.authenticate();
      if (!mounted) return;
      if (result.success) {
        widget.onUnlocked();
      } else {
        setState(() => _lastStatus = result.status);
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  String? get _errorText {
    switch (_lastStatus) {
      case AuthStatus.cancelled:
        return null; // just show the retry button silently
      case AuthStatus.notEnrolled:
        return 'No fingerprint, face, or screen lock set up on this device.\nGo to Settings → Security and add one.';
      case AuthStatus.lockedOut:
        return 'Too many failed attempts. Try again in a moment.';
      case AuthStatus.permanentlyLockedOut:
        return 'Authentication locked out. Lock and unlock your phone screen first, then try again.';
      case AuthStatus.notAvailable:
        return 'Authentication is not available on this device.';
      case AuthStatus.failure:
        return 'Authentication failed. Please try again.';
      default:
        return null;
    }
  }

  bool get _canRetry =>
      _lastStatus != AuthStatus.notAvailable &&
      _lastStatus != AuthStatus.permanentlyLockedOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.credit_card,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Card Vault',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock to access your saved cards',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  if (_isAuthenticating)
                    const CircularProgressIndicator(color: Colors.white)
                  else ...[
                    if (_canRetry)
                      FilledButton.icon(
                        onPressed: _authenticate,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1D4ED8),
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.fingerprint, size: 24),
                        label: Text(
                          _lastStatus == null
                              ? 'Unlock with Biometrics'
                              : 'Try Again',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.white70, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorText!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
