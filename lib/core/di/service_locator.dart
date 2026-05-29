import 'package:get_it/get_it.dart';

import '../auth/biometric_service.dart';
import '../../features/cards/data/datasources/local_card_data_source.dart';
import '../../features/cards/data/repositories/card_repository_impl.dart';
import '../../features/cards/data/services/card_scan_service.dart';
import '../../features/cards/domain/repositories/card_repository.dart';
import '../../features/cards/domain/usecases/add_card_use_case.dart';
import '../../features/cards/domain/usecases/get_saved_cards_use_case.dart';
import '../../features/cards/presentation/bloc/bottom_navigation/bottom_navigation_bloc.dart';
import '../../features/cards/presentation/bloc/card_overview/card_overview_bloc.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  sl
    ..registerLazySingleton<LocalCardDataSource>(LocalCardDataSourceImpl.new)
    ..registerLazySingleton<CardRepository>(() => CardRepositoryImpl(sl()))
    ..registerLazySingleton<AddCardUseCase>(() => AddCardUseCase(sl()))
    ..registerLazySingleton<GetSavedCardsUseCase>(
      () => GetSavedCardsUseCase(sl()),
    )
    ..registerLazySingleton<BiometricService>(BiometricService.new)
    ..registerLazySingleton<CardScanService>(CardScanService.new)
    ..registerFactory(BottomNavigationBloc.new)
    ..registerFactory(() => CardOverviewBloc(sl(), sl()));
}
