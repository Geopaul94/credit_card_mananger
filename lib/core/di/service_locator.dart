import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_cubit.dart';
import '../auth/biometric_service.dart';
import '../backup/backup_cubit.dart';
import '../backup/google_drive_service.dart';
import '../encryption/encryption_service.dart';
import '../notifications/notification_service.dart';
import '../storage/secure_card_storage.dart';
import '../../features/cards/presentation/bloc/add_card/add_card_cubit.dart';
import '../../features/cards/data/datasources/local_card_data_source.dart';
import '../../features/cards/data/repositories/card_repository_impl.dart';
import '../../features/cards/data/services/card_scan_service.dart';
import '../../features/cards/domain/repositories/card_repository.dart';
import '../../features/cards/domain/usecases/add_card_use_case.dart';
import '../../features/cards/domain/usecases/delete_card_use_case.dart';
import '../../features/cards/domain/usecases/get_saved_cards_use_case.dart';
import '../../features/cards/domain/usecases/update_card_use_case.dart';
import '../../features/cards/presentation/bloc/bottom_navigation/bottom_navigation_bloc.dart';
import '../../features/cards/presentation/bloc/card_overview/card_overview_bloc.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  await NotificationService.instance.initialize();

  // ── Platform services ─────────────────────────────────────────────────────
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final prefs = await SharedPreferences.getInstance();

  // ── Encryption & storage ──────────────────────────────────────────────────
  sl
    ..registerLazySingleton<EncryptionService>(
        () => EncryptionService(secureStorage))
    ..registerLazySingleton<SecureCardStorage>(
        () => SecureCardStorage(sl(), prefs))

    // ── Data layer ────────────────────────────────────────────────────────────
    ..registerLazySingleton<LocalCardDataSource>(
        () => LocalCardDataSourceImpl(sl()))
    ..registerLazySingleton<CardRepository>(() => CardRepositoryImpl(sl()))
    ..registerLazySingleton<AddCardUseCase>(() => AddCardUseCase(sl()))
    ..registerLazySingleton<UpdateCardUseCase>(() => UpdateCardUseCase(sl()))
    ..registerLazySingleton<DeleteCardUseCase>(() => DeleteCardUseCase(sl()))
    ..registerLazySingleton<GetSavedCardsUseCase>(
        () => GetSavedCardsUseCase(sl()))

    // ── Services ──────────────────────────────────────────────────────────────
    ..registerLazySingleton<BiometricService>(BiometricService.new)
    ..registerLazySingleton<CardScanService>(CardScanService.new,
        dispose: (s) => s.dispose())
    ..registerLazySingleton<GoogleDriveService>(GoogleDriveService.new)

    // ── Auth — singleton so lock state survives widget rebuilds ───────────────
    ..registerLazySingleton<AuthCubit>(() => AuthCubit(sl()))

    // ── Backup — singleton so state survives navigation ───────────────────────
    ..registerLazySingleton<BackupCubit>(
        () => BackupCubit(sl(), sl(), sl(), sl()))

    // ── Presentation factories ────────────────────────────────────────────────
    ..registerFactory<AddCardCubit>(() => AddCardCubit(sl()))
    ..registerFactory(BottomNavigationBloc.new)
    ..registerFactory(
        () => CardOverviewBloc(sl(), sl(), sl(), sl(), sl(), sl()));
}
