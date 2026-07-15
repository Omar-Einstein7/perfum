import 'package:perfum_ahmed_gaper/src/imports/core_imports.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final current = _buildCupertinoApp(context);
    return ScreenUtilWrapper(child: current);
  }

  Widget _buildCupertinoApp(BuildContext context) {
    return CupertinoApp.router(
      title: 'perfume_ahmed_gaber',
      debugShowCheckedModeBanner: false,
      theme: buildCupertinoTheme(primaryColorHex: '#a3b9f6'),
      routerConfig: appRouter,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) {
        Widget current = child!;
        current = SkeletonWrapper(child: current);
        current = SessionListenerWrapper(child: current);
        
        // Ensure Material themes (tokens, widget styles like dialogs/buttons/inputs) 
        // are available even in Cupertino mode, as many apps use a mix of both.
        current = Theme(
          data: (MediaQuery.of(context).platformBrightness == Brightness.dark)
              ? buildDarkTheme(primaryColorHex: '#a3b9f6')
              : buildLightTheme(primaryColorHex: '#a3b9f6'),
          child: current,
        );
        
        return current;
      },
    );
  }
}