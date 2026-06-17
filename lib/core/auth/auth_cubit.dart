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
        return 'Biometrics locked out. Tap Try Again to unlock with your device PIN or pattern.';
      case AuthStatus.notAvailable:
        return 'Authentication is not available on this device.';
      case AuthStatus.failure:
        return 'Authentication failed. Please try again.';
      default:
        return null;
    }
  }

  // permanentlyLockedOut is still retryable: pressing Try Again re-runs
  // authenticate(), which (biometricOnly: false) falls back to device PIN.
  bool get canRetry => failureStatus != AuthStatus.notAvailable;

  @override
  List<Object?> get props => [phase, failureStatus];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._service) : super(const AuthState());

  final BiometricService _service;

  /// Bumped by every lock(). Snapshotted before the biometric await so a
  /// background event that happens mid-authentication invalidates the in-flight
  /// result — a stale success can never silently unlock the vault.
  int _epoch = 0;

  /// Set while a trusted in-app flow (e.g. the camera scanner) deliberately
  /// backgrounds the activity, so returning from the camera doesn't force a
  /// re-auth mid-scan. The brief background hop the camera itself causes is
  /// forgiven; a genuine "user walked away" (interruption longer than
  /// [_trustedGrace]) still re-locks once the flow ends. Keep the window as
  /// small as possible — only around the actual picker/camera call.
  bool _trustedInterruption = false;
  bool _lockDeferred = false;
  DateTime? _interruptionStart;

  /// How long the camera may hold the foreground before a suppressed background
  /// event is treated as a real "left the app" and honoured. Comfortably longer
  /// than capturing a photo, short enough to bound vault exposure.
  static const _trustedGrace = Duration(seconds: 60);

  void beginTrustedInterruption() {
    _trustedInterruption = true;
    _lockDeferred = false;
    _interruptionStart = DateTime.now();
  }

  void endTrustedInterruption() {
    _trustedInterruption = false;
    final start = _interruptionStart;
    _interruptionStart = null;
    // A background event was suppressed during the camera window. Honour it
    // (re-lock) only if the interruption ran long enough to be a genuine
    // departure rather than the camera's own brief foreground hop.
    if (_lockDeferred) {
      _lockDeferred = false;
      if (start == null ||
          DateTime.now().difference(start) > _trustedGrace) {
        lock();
      }
    }
  }

  Future<void> authenticate() async {
    if (state.isAuthenticating) return;
    final epoch = _epoch;
    emit(const AuthState(phase: AuthPhase.authenticating));

    final result = await _service.authenticate();

    if (isClosed || epoch != _epoch) return;
    if (result.success) {
      emit(const AuthState(phase: AuthPhase.authenticated));
    } else {
      emit(AuthState(phase: AuthPhase.failed, failureStatus: result.status));
    }
  }

  /// Called when app moves to background — forces re-auth on next foreground.
  /// During a trusted interruption the lock is deferred (not discarded) and
  /// re-evaluated when the interruption ends, so a genuine backgrounding mid
  /// scan still re-locks the vault.
  void lock() {
    if (_trustedInterruption) {
      _lockDeferred = true;
      return;
    }
    _epoch++;
    if (!isClosed) emit(const AuthState(phase: AuthPhase.idle));
  }
}
