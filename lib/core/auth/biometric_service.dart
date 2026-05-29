import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum AuthStatus {
  success,
  cancelled,  // user dismissed — just show retry, no error text
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
      final granted = await _auth.authenticate(
        localizedReason: 'Unlock to access your saved cards',
        options: const AuthenticationOptions(
          biometricOnly: false,  // shows fingerprint + face + PIN/pattern
          stickyAuth: false,     // false avoids re-triggering issues
          useErrorDialogs: true,
        ),
      );
      return granted
          ? const AuthResult._(AuthStatus.success)
          : const AuthResult._(AuthStatus.cancelled);
    } on PlatformException catch (e) {
      return AuthResult._(_codeToStatus(e.code), e.message);
    } catch (e) {
      return AuthResult._(AuthStatus.failure, e.toString());
    }
  }

  AuthStatus _codeToStatus(String code) {
    switch (code) {
      case 'NotEnrolled':
      case 'not_enrolled':
      case 'NotAvailable':
        return AuthStatus.notEnrolled;
      case 'LockedOut':
      case 'locked_out':
        return AuthStatus.lockedOut;
      case 'PermanentlyLockedOut':
      case 'permanently_locked_out':
        return AuthStatus.permanentlyLockedOut;
      case 'otherOperatingSystem':
        return AuthStatus.notAvailable;
      default:
        return AuthStatus.failure;
    }
  }
}
