import 'package:get_it/get_it.dart';
import 'package:perfum_ahmed_gaper/src/services/secure_storage_service.dart';
import 'package:perfum_ahmed_gaper/src/services/storage_service.dart';
import 'package:perfum_ahmed_gaper/src/services/dio_service.dart';
import 'package:perfum_ahmed_gaper/src/services/auth_service.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/data/datasources/auth_remote_datasource_impl.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/logout_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/check_session_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/providers/session_bloc.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/providers/auth_bloc.dart';
import 'package:perfum_ahmed_gaper/src/features/units/data/datasources/unit_remote_data_source.dart';
import 'package:perfum_ahmed_gaper/src/features/units/data/repositories/unit_repository_impl.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/repositories/unit_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/create_unit_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/delete_unit_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/get_unit_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/list_units_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/units/domain/usecases/update_unit_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/units/presentation/bloc/unit_cubit.dart';

final GetIt sl = GetIt.instance;
const String kJwtTokenKey = 'jwt_token';

Future<void> setupServiceLocator() async {
  try {
    // --- Infrastructure layer (no dependencies) ---
    sl.registerLazySingleton<SecureStorageService>(
      () => SecureStorageService.instance,
    );
    sl.registerLazySingleton<StorageService>(
      () => StorageService.instance,
    );
    sl.registerLazySingleton<DioService>(
      () => DioService.instance,
    );
    sl.registerLazySingleton<AuthService>(
      () => AuthService.instance,
    );

    // --- Data layer ---
    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(dio: sl<DioService>()),
    );
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        dataSource: sl<AuthRemoteDataSource>(),
        secureStorage: sl<SecureStorageService>(),
        authService: sl<AuthService>(),
      ),
    );

    // --- Domain layer ---
    sl.registerLazySingleton<LoginUseCase>(
      () => LoginUseCase(repository: sl<AuthRepository>()),
    );
    sl.registerLazySingleton<LogoutUseCase>(
      () => LogoutUseCase(repository: sl<AuthRepository>()),
    );
    sl.registerLazySingleton<CheckSessionUseCase>(
      () => CheckSessionUseCase(repository: sl<AuthRepository>()),
    );
    sl.registerLazySingleton<SignUpUseCase>(
      () => SignUpUseCase(repository: sl<AuthRepository>()),
    );
    sl.registerLazySingleton<ForgotPasswordUseCase>(
      () => ForgotPasswordUseCase(repository: sl<AuthRepository>()),
    );

    // --- Presentation layer ---
    // SessionBloc: EAGER — starts SessionCheckRequested immediately on construction.
    // Must be registered before appRouter is built.
    sl.registerSingleton<SessionBloc>(
      SessionBloc(
        checkSessionUseCase: sl<CheckSessionUseCase>(),
        logoutUseCase: sl<LogoutUseCase>(),
        repository: sl<AuthRepository>(),
      ),
    );

    sl.registerLazySingleton<AuthBloc>(
      () => AuthBloc(
        loginUseCase: sl<LoginUseCase>(),
        signUpUseCase: sl<SignUpUseCase>(),
        forgotPasswordUseCase: sl<ForgotPasswordUseCase>(),
      ),
    );

    // --- Units module ---
    sl.registerLazySingleton<UnitRemoteDataSource>(
      () => UnitRemoteDataSourceImpl(dio: sl<DioService>()),
    );
    sl.registerLazySingleton<UnitRepository>(
      () => UnitRepositoryImpl(dataSource: sl<UnitRemoteDataSource>()),
    );
    sl.registerFactory<CreateUnitUseCase>(
      () => CreateUnitUseCase(repository: sl<UnitRepository>()),
    );
    sl.registerFactory<GetUnitUseCase>(
      () => GetUnitUseCase(repository: sl<UnitRepository>()),
    );
    sl.registerFactory<UpdateUnitUseCase>(
      () => UpdateUnitUseCase(repository: sl<UnitRepository>()),
    );
    sl.registerFactory<DeleteUnitUseCase>(
      () => DeleteUnitUseCase(repository: sl<UnitRepository>()),
    );
    sl.registerFactory<ListUnitsUseCase>(
      () => ListUnitsUseCase(repository: sl<UnitRepository>()),
    );
    sl.registerFactory<UnitCubit>(
      () => UnitCubit(
        listUnitsUseCase: sl<ListUnitsUseCase>(),
        getUnitUseCase: sl<GetUnitUseCase>(),
        createUnitUseCase: sl<CreateUnitUseCase>(),
        updateUnitUseCase: sl<UpdateUnitUseCase>(),
        deleteUnitUseCase: sl<DeleteUnitUseCase>(),
      ),
    );
  } catch (e, stackTrace) {
    // ignore: avoid_print
    print('[FATAL] setupServiceLocator failed: $e\n$stackTrace');
    rethrow;
  }
}
