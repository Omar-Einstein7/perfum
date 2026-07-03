import 'src/config/di/injection_container.dart' as di;
import 'src/imports/core_imports.dart';
import 'src/imports/packages_imports.dart';
import 'src/app.dart';

Future<void> main() async {
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await AppConfig.init();
  await di.configureDependencies();

  runApp(const LocalizationWrapper(child: StateWrapper(child: App())));
}
