import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../features/accounts/data/accounts_repository.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/budgets/data/budgets_repository.dart';
import '../../features/categories/data/categories_repository.dart';
import '../../features/dashboard/data/stats_repository.dart';
import '../../features/devices/data/devices_repository.dart';
import '../../features/family/data/family_repository.dart';
import '../../features/goals/data/goals_repository.dart';
import '../../features/receipt_ocr/data/ingestion_repository.dart';
import '../../features/receipt_ocr/data/receipt_ocr_factory.dart';
import '../../features/receipt_ocr/domain/receipt_ocr_service.dart';
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
  BudgetsRepository? budgetsRepository,
  GoalsRepository? goalsRepository,
  StatsRepository? statsRepository,
  DevicesRepository? devicesRepository,
  IngestionRepository? ingestionRepository,
  ReceiptOcrService? receiptOcrService,
}) {
  final accounts = accountsRepository ?? AccountsRepository();
  final categories = categoriesRepository ?? CategoriesRepository();
  final transactions = transactionsRepository ?? TransactionsRepository();
  final budgets = budgetsRepository ?? BudgetsRepository();
  final goals = goalsRepository ?? GoalsRepository();
  final stats = statsRepository ?? StatsRepository();
  final devices = devicesRepository ?? DevicesRepository();
  final ingestion =
      ingestionRepository ?? IngestionRepository(transactions: transactions);
  final ocr = receiptOcrService ?? createReceiptOcrService();

  return [
    ChangeNotifierProvider<LocaleController>.value(value: localeController),
    ChangeNotifierProvider<AuthController>.value(value: authController),
    ChangeNotifierProvider<FamilyController>.value(
      value: familyController ?? FamilyController(),
    ),
    Provider<AccountsRepository>.value(value: accounts),
    Provider<CategoriesRepository>.value(value: categories),
    Provider<TransactionsRepository>.value(value: transactions),
    Provider<BudgetsRepository>.value(value: budgets),
    Provider<GoalsRepository>.value(value: goals),
    Provider<StatsRepository>.value(value: stats),
    Provider<DevicesRepository>.value(value: devices),
    Provider<IngestionRepository>.value(value: ingestion),
    Provider<ReceiptOcrService>.value(value: ocr),
    ChangeNotifierProvider<TransactionsController>(
      create: (_) =>
          transactionsController ??
          TransactionsController(repository: transactions),
    ),
  ];
}
