import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'auth_interceptor.dart';
import 'auth_service.dart';
import 'copy_service.dart';
import 'device_info_service.dart';
import 'dio_service.dart';
import 'hive_service.dart';
import 'internet_connection_service.dart';
import 'location_service.dart';
import 'media_service.dart';
import 'path_service.dart';
import 'permission_service.dart';
import 'secure_storage_service.dart';
import 'storage_service.dart';
import 'url_launcher_service.dart';
import 'version_update_service.dart';

import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/presentation/providers/auth_bloc.dart';
import '../features/auth/presentation/providers/session_bloc.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  await _registerInfrastructure();
  _registerServices();
  _registerAuthFeature();
}

// ─── Infrastructure ───────────────────────────────────────────────────────────

Future<void> _registerInfrastructure() async {
  sl.registerSingleton<Dio>(AppConfig.dio);

  sl.registerSingletonAsync<HiveService>(
    () => HiveService().init(),
  );

  sl.registerSingletonAsync<StorageService>(
    () => StorageService().init(),
  );

  await sl.allReady();
}

// ─── Services ─────────────────────────────────────────────────────────────────

void _registerServices() {
  sl.registerLazySingleton<DioService>(
    () => DioService(sl<Dio>()),
  );

  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );

  final dio = sl<Dio>();
  dio.interceptors.add(AuthInterceptor(sl<SecureStorageService>(), dio));

  sl.registerLazySingleton<AuthService>(
    () => AuthService(sl<Dio>()),
    dispose: (s) => s.dispose(),
  );

  sl.registerLazySingleton<InternetConnectionService>(
    () => InternetConnectionService(),
  );

  sl.registerLazySingleton<PathService>(() => PathService());
  sl.registerLazySingleton<LocationService>(() => LocationService());
  sl.registerLazySingleton<MediaService>(() => MediaService());
  sl.registerLazySingleton<PermissionService>(() => PermissionService());
  sl.registerLazySingleton<DeviceInfoService>(() => DeviceInfoService());
  sl.registerLazySingleton<UrlLauncherService>(() => UrlLauncherService());
  sl.registerLazySingleton<CopyService>(() => CopyService());
  sl.registerLazySingleton<VersionUpdateService>(() => VersionUpdateService());
}

// ─── Auth Feature ─────────────────────────────────────────────────────────────

void _registerAuthFeature() {
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthService>()),
  );

  sl.registerFactory<AuthBloc>(
    () => AuthBloc(repository: sl<AuthRepository>()),
  );

  sl.registerFactory<SessionBloc>(
    () => SessionBloc(repository: sl<AuthRepository>()),
  );
}
