import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../features/accounts/data/accounts_repository.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/categories/data/categories_repository.dart';
import '../../features/family/data/family_repository.dart';
import '../../features/transactions/data/transactions_repository.dart';
import '../../features/transactions/presentation/transactions_controller.dart';
import '../locale/locale_controller.dart';

/// Root dependency injection.
List<SingleChildWidget> buildAppProviders({
  required LocaleController localeController,
  required AuthController authController,
  FamilyController? familyController,
  AccountsRepository? accountsRepository,
  CategoriesRepository? categoriesRepository,
  TransactionsRepository? transactionsRepository,
  TransactionsController? transactionsController,
}) {
  final accounts = accountsRepository ?? AccountsRepository();
  final categories = categoriesRepository ?? CategoriesRepository();
  final transactions = transactionsRepository ?? TransactionsRepository();

  return [
    ChangeNotifierProvider<LocaleController>.value(value: localeController),
    ChangeNotifierProvider<AuthController>.value(value: authController),
    ChangeNotifierProvider<FamilyController>.value(
      value: familyController ?? FamilyController(),
    ),
    Provider<AccountsRepository>.value(value: accounts),
    Provider<CategoriesRepository>.value(value: categories),
    Provider<TransactionsRepository>.value(value: transactions),
    ChangeNotifierProvider<TransactionsController>(
      create: (_) =>
          transactionsController ??
          TransactionsController(repository: transactions),
    ),
  ];
}
