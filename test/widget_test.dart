import 'package:family_finance/core/locale/locale_controller.dart';
import 'package:family_finance/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('locale switch updates settings language labels', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localeController = LocaleController(prefs);

    await tester.pumpWidget(
      ListenableBuilder(
        listenable: localeController,
        builder: (context, _) {
          return MaterialApp(
            locale: localeController.locale,
            supportedLocales: LocaleController.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Scaffold(
                  body: Column(
                    children: [
                      Text(l10n.settingsLanguage),
                      TextButton(
                        onPressed: () =>
                            localeController.setLocale(const Locale('it')),
                        child: Text(l10n.languageItalian),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);

    await tester.tap(find.text('Italian'));
    await tester.pumpAndSettle();

    expect(find.text('Lingua'), findsOneWidget);
  });
}
