import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'biometric_service.dart';

// ─── State ────────────────────────────────────────────────────────────────────

enum AuthPhase { idle, authenticating, authenticated, failed }

class AuthState extends Equatable {
  const AuthState({
    this.phase = AuthPhase.idle,
    this.failureStatus,
  });

  final AuthPhase phase;
  final AuthStatus? failureStatus; // populated only when phase == failed

  bool get isAuthenticated => phase == AuthPhase.authenticated;
  bool get isAuthenticating => phase == AuthPhase.authenticating;

  // Derived helpers reused by LockScreen
  String? get errorText {
    switch (failureStatus) {
      case AuthStatus.cancelled:
        return null;
      case AuthStatus.notEnrolled:
        return 'No fingerprint, face, or screen lock set up.\n'
            'Go to Settings → Security and add one.';
      case AuthStatus.lockedOut:
        return 'Too many failed attempts. Try again in a moment.';
      case AuthStatus.permanentlyLockedOut:
        return 'Authentication locked out. Lock and unlock your phone screen first.';
      case AuthStatus.notAvailable:
        return 'Authentication is not available on this device.';
      case AuthStatus.failure:
        return 'Authentication failed. Please try again.';
      default:
        return null;
    }
  }

  bool get canRetry =>
      failureStatus != AuthStatus.notAvailable &&
      failureStatus != AuthStatus.permanentlyLockedOut;

  @override
  List<Object?> get props => [phase, failureStatus];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._service) : super(const AuthState());

  final BiometricService _service;

  Future<void> authenticate() async {
    if (state.isAuthenticating) return;
    emit(const AuthState(phase: AuthPhase.authenticating));

    final result = await _service.authenticate();

    if (isClosed) return;
    if (result.success) {
      emit(const AuthState(phase: AuthPhase.authenticated));
    } else {
      emit(AuthState(phase: AuthPhase.failed, failureStatus: result.status));
    }
  }

  /// Called when app moves to background — forces re-auth on next foreground.
  void lock() {
    if (!isClosed) emit(const AuthState(phase: AuthPhase.idle));
  }
}
