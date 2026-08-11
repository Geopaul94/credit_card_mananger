import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/auth/auth_cubit.dart';
import 'core/notifications/notification_service.dart';
import 'core/backup/backup_cubit.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/warm_theme.dart';
import 'features/cards/presentation/bloc/bottom_navigation/bottom_navigation_bloc.dart';
import 'features/cards/presentation/bloc/card_overview/card_overview_bloc.dart';
import 'features/cards/presentation/bloc/card_overview/card_overview_event.dart';
import 'features/cards/presentation/widgets/bottom_navigation_bar.dart';
import 'features/lock/presentation/lock_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const MyApp());
}

// ─── Root app ─────────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ThemeCubit>()),
        // AuthCubit lives at the root — survives navigator pushes
        BlocProvider(create: (_) => sl<AuthCubit>()),
        // BackupCubit lives at the root so auto-backup can fire after unlock
        BlocProvider(create: (_) => sl<BackupCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          final isWarm = themeState.variant == AppThemeVariant.warm;
          return MaterialApp(
            title: 'Card Vault',
            debugShowCheckedModeBanner: false,
            themeMode: themeState.mode,
            theme: isWarm ? WarmTheme.light : AppTheme.light,
            darkTheme: isWarm ? WarmTheme.dark : AppTheme.dark,
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                // Respect the user's font-size setting, but bound it. Card
                // faces are fixed-height graphics with the number, holder and
                // expiry laid out like a real card; unbounded scaling
                // overflows them. This still honours a genuine accessibility
                // need while keeping every screen intact.
                data: media.copyWith(
                  textScaler: media.textScaler.clamp(
                    minScaleFactor: 0.9,
                    maxScaleFactor: 1.3,
                  ),
                ),
                // Tapping anywhere outside a text field dismisses the
                // keyboard, app-wide.
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: child,
                ),
              );
            },
            home: const _AppGate(),
          );
        },
      ),
    );
  }
}

// ─── App gate — shows lock or main shell based on AuthCubit ──────────────────

class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-lock whenever the app leaves the foreground, so card data is never
  /// reachable without re-auth. Covers paused/hidden/detached (but not the
  /// transient `inactive` the iOS biometric sheet itself triggers).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      context.read<AuthCubit>().lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      // Only rebuild when the authenticated flag actually flips —
      // avoids spurious rebuilds while the spinner shows.
      buildWhen: (prev, curr) => prev.isAuthenticated != curr.isAuthenticated,
      builder: (context, authState) {
        if (authState.isAuthenticated) return const _MainShell();
        return const LockScreen();
      },
    );
  }
}

// ─── Main shell — provides card BLoCs ────────────────────────────────────────

class _MainShell extends StatelessWidget {
  const _MainShell();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<BottomNavigationBloc>()),
        BlocProvider(create: (_) => sl<CardOverviewBloc>()),
      ],
      child: const _NotificationActionListener(
        child: BottomNavigationBarWidget(),
      ),
    );
  }
}

/// Reloads cards when a notification button is tapped while the app is open.
///
/// Those buttons write paid state straight to storage — they have to, because
/// they usually run with the app closed — so a running app would otherwise sit
/// on a stale list showing a bill as unpaid after the user just paid it.
class _NotificationActionListener extends StatefulWidget {
  const _NotificationActionListener({required this.child});
  final Widget child;

  @override
  State<_NotificationActionListener> createState() =>
      _NotificationActionListenerState();
}

class _NotificationActionListenerState
    extends State<_NotificationActionListener> {
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = NotificationService.instance.onActionApplied.listen((_) {
      if (mounted) {
        context.read<CardOverviewBloc>().add(const LoadCardsRequested());
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
