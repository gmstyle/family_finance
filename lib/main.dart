import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/di/app_providers.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/locale/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  final localeController = await LocaleController.create();
  runApp(FamilyFinanceApp(localeController: localeController));
}

class FamilyFinanceApp extends StatefulWidget {
  const FamilyFinanceApp({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  State<FamilyFinanceApp> createState() => _FamilyFinanceAppState();
}

class _FamilyFinanceAppState extends State<FamilyFinanceApp> {
  late final _router = createAppRouter(
    localeController: widget.localeController,
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildAppProviders(localeController: widget.localeController),
      child: ListenableBuilder(
        listenable: widget.localeController,
        builder: (context, _) {
          return MaterialApp.router(
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)?.appTitle ?? 'Family Finance',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            locale: widget.localeController.locale,
            supportedLocales: LocaleController.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
