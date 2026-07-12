import 'package:local_auth/local_auth.dart';

enum AuthStatus {
  success,
  cancelled, // user dismissed — just show retry, no error text
  notEnrolled, // no biometrics/PIN set up on device
  lockedOut,
  permanentlyLockedOut,
  notAvailable,
  failure,
}

class AuthResult {
  const AuthResult._(this.status, [this.debugMessage]);
  final AuthStatus status;
  final String? debugMessage; // dev-facing, not shown to user

  bool get success => status == AuthStatus.success;
}

class BiometricService {
  final _auth = LocalAuthentication();

  Future<AuthResult> authenticate() async {
    try {
      // Kill any zombie session first. An interrupted attempt (e.g. the
      // device-credential screen taking over the activity) can leave the
      // previous session stuck "in progress", which would make every later
      // attempt fail instantly and the Try Again button appear dead.
      await _stopStaleSession();

      final granted = await _auth.authenticate(
        localizedReason: 'Unlock to access your saved cards',
        biometricOnly: false, // fingerprint + face + PIN/pattern fallback
        // The PIN/pattern screen backgrounds the app on many devices; this
        // tells the plugin to resume authentication on foregrounding instead
        // of failing the attempt.
        persistAcrossBackgrounding: true,
      );
      // In 3.x `false` means the user failed the challenge (cancel throws).
      return granted
          ? const AuthResult._(AuthStatus.success)
          : const AuthResult._(AuthStatus.failure);
    } on LocalAuthException catch (e) {
      // A stuck session must be cleared so the next attempt can show a prompt.
      if (e.code == LocalAuthExceptionCode.authInProgress) {
        await _stopStaleSession();
      }
      return AuthResult._(_codeToStatus(e.code), e.description);
    } catch (e) {
      return AuthResult._(AuthStatus.failure, e.toString());
    }
  }

  /// Best-effort cancel of a previous in-flight prompt (Android only; no-op
  /// elsewhere). Never throws — a failure to stop must not block a new try.
  Future<void> _stopStaleSession() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }

  AuthStatus _codeToStatus(LocalAuthExceptionCode code) {
    switch (code) {
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.systemCanceled:
      case LocalAuthExceptionCode.timeout:
        return AuthStatus.cancelled;
      case LocalAuthExceptionCode.noCredentialsSet:
      case LocalAuthExceptionCode.noBiometricsEnrolled:
        return AuthStatus.notEnrolled;
      case LocalAuthExceptionCode.temporaryLockout:
        return AuthStatus.lockedOut;
      case LocalAuthExceptionCode.biometricLockout:
        return AuthStatus.permanentlyLockedOut;
      case LocalAuthExceptionCode.noBiometricHardware:
        return AuthStatus.notAvailable;
      // authInProgress, uiUnavailable, userRequestedFallback, deviceError,
      // unknownError, and any codes added in future plugin versions — all
      // retryable.
      default:
        return AuthStatus.failure;
    }
  }
}
