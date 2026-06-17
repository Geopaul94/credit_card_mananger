import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/auth/auth_cubit.dart';
import 'core/backup/backup_cubit.dart';
import 'core/di/service_locator.dart';
import 'core/theme/theme_cubit.dart';
import 'features/cards/presentation/bloc/bottom_navigation/bottom_navigation_bloc.dart';
import 'features/cards/presentation/bloc/card_overview/card_overview_bloc.dart';
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
        BlocProvider(create: (_) => ThemeCubit()),
        // AuthCubit lives at the root — survives navigator pushes
        BlocProvider(create: (_) => sl<AuthCubit>()),
        // BackupCubit lives at the root so auto-backup can fire after unlock
        BlocProvider(create: (_) => sl<BackupCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'Card Vault',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            home: const _AppGate(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6),
        brightness: brightness,
      ),
      scaffoldBackgroundColor:
          isLight ? const Color(0xFFF3F6FF) : const Color(0xFF0B1220),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: isLight ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: isLight ? Colors.white : const Color(0xFF111A2E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
      child: const BottomNavigationBarWidget(),
    );
  }
}
