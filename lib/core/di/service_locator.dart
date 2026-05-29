import 'package:get_it/get_it.dart';

import '../auth/auth_cubit.dart';
import '../auth/biometric_service.dart';
import '../notifications/notification_service.dart';
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
  sl
    ..registerLazySingleton<LocalCardDataSource>(LocalCardDataSourceImpl.new)
    ..registerLazySingleton<CardRepository>(() => CardRepositoryImpl(sl()))
    ..registerLazySingleton<AddCardUseCase>(() => AddCardUseCase(sl()))
    ..registerLazySingleton<UpdateCardUseCase>(() => UpdateCardUseCase(sl()))
    ..registerLazySingleton<DeleteCardUseCase>(() => DeleteCardUseCase(sl()))
    ..registerLazySingleton<GetSavedCardsUseCase>(
      () => GetSavedCardsUseCase(sl()),
    )
    ..registerLazySingleton<BiometricService>(BiometricService.new)
    ..registerLazySingleton<CardScanService>(CardScanService.new)
    // Auth — singleton so the lock state survives widget rebuilds
    ..registerLazySingleton<AuthCubit>(() => AuthCubit(sl()))
    // AddCard — factory so each screen open gets fresh state
    ..registerFactory<AddCardCubit>(() => AddCardCubit(sl()))
    ..registerFactory(BottomNavigationBloc.new)
    ..registerFactory(
      () => CardOverviewBloc(sl(), sl(), sl(), sl()),
    );
}
