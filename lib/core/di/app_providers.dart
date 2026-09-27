import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/family/data/family_repository.dart';
import '../locale/locale_controller.dart';

/// Root dependency injection.
List<SingleChildWidget> buildAppProviders({
  required LocaleController localeController,
  required AuthController authController,
  FamilyController? familyController,
}) {
  return [
    ChangeNotifierProvider<LocaleController>.value(value: localeController),
    ChangeNotifierProvider<AuthController>.value(value: authController),
    ChangeNotifierProvider<FamilyController>.value(
      value: familyController ?? FamilyController(),
    ),
  ];
}
