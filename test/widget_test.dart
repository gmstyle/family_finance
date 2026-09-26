import 'package:family_finance/core/locale/locale_controller.dart';
import 'package:family_finance/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows home placeholder and settings language options', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localeController = LocaleController(prefs);

    await tester.pumpWidget(
      FamilyFinanceApp(localeController: localeController),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Italian'), findsOneWidget);

    await tester.tap(find.text('Italian'));
    await tester.pumpAndSettle();

    expect(find.text('Lingua'), findsOneWidget);
    expect(find.text('Italiano'), findsOneWidget);
  });
}
