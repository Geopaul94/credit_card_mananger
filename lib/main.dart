import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThemeCubit(),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'Card Vault',
            themeMode: themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF3B82F6),
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: const Color(0xFFF3F6FF),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                backgroundColor: Colors.transparent,
                foregroundColor: Color(0xFF0F172A),
                elevation: 0,
                scrolledUnderElevation: 0,
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF3B82F6),
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF0B1220),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
              ),
              cardTheme: CardThemeData(
                color: const Color(0xFF111A2E),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            home: const _AppGate(),
          );
        },
      ),
    );
  }
}

/// Handles biometric lock. Re-locks when app goes to background.
class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> with WidgetsBindingObserver {
  bool _isUnlocked = false;

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      setState(() => _isUnlocked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return LockScreen(onUnlocked: () => setState(() => _isUnlocked = true));
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<BottomNavigationBloc>(
          create: (_) => sl<BottomNavigationBloc>(),
        ),
        BlocProvider<CardOverviewBloc>(
          create: (_) => sl<CardOverviewBloc>(),
        ),
      ],
      child: const BottomNavigationBarWidget(),
    );
  }
}
