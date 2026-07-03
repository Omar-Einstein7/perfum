import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:perfum_ahmed_gaper/src/services/secure_storage_service.dart';
import 'package:perfum_ahmed_gaper/src/config/app_config.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/bloc/session_bloc.dart';
import 'package:perfum_ahmed_gaper/src/features/auth/presentation/bloc/user_management_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService.instance,
  );

  getIt.registerLazySingleton<Dio>(() {
    final dio = AppConfig.dio;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final storage = getIt<SecureStorageService>();
            final tokenResult = await storage.read('jwt_token');
            final token = tokenResult.fold((_) => null, (val) => val);
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {}
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            try {
              final storage = getIt<SecureStorageService>();
              storage.delete('jwt_token');
            } catch (_) {}
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  });

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: getIt<Dio>()),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      dataSource: getIt<AuthRemoteDataSource>(),
      secureStorage: getIt<SecureStorageService>(),
    ),
  );

  getIt.registerFactory<LoginUseCase>(
    () => LoginUseCase(repository: getIt<AuthRepository>()),
  );

  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: getIt<LoginUseCase>(),
      repository: getIt<AuthRepository>(),
    ),
  );

  getIt.registerFactory<SessionBloc>(
    () => SessionBloc(repository: getIt<AuthRepository>()),
  );

  getIt.registerFactory<UserManagementBloc>(
    () => UserManagementBloc(repository: getIt<AuthRepository>()),
  );

  await getIt.allReady();
}

void resetDependencies() {
  getIt.reset();
}
