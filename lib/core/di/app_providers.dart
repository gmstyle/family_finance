import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../locale/locale_controller.dart';

/// Root dependency injection for Phase 1 foundations.
List<SingleChildWidget> buildAppProviders({
  required LocaleController localeController,
}) {
  return [
    ChangeNotifierProvider<LocaleController>.value(value: localeController),
  ];
}
