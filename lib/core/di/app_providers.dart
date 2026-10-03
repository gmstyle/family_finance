import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../features/accounts/data/accounts_repository.dart';
import '../../features/accounts/presentation/accounts_controller.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/budgets/data/budgets_repository.dart';
import '../../features/budgets/presentation/budgets_controller.dart';
import '../../features/categories/data/categories_repository.dart';
import '../../features/categories/presentation/categories_controller.dart';
import '../../features/dashboard/data/stats_repository.dart';
import '../../features/dashboard/presentation/dashboard_controller.dart';
import '../../features/devices/data/devices_repository.dart';
import '../../features/family/presentation/family_controller.dart';
import '../../features/goals/data/goals_repository.dart';
import '../../features/goals/presentation/goals_controller.dart';
import '../../features/notification_ingest/data/account_bindings_repository.dart';
import '../../features/notification_ingest/data/notification_capture_factory.dart';
import '../../features/notification_ingest/domain/notification_capture_service.dart';
import '../../features/notification_ingest/presentation/account_bindings_controller.dart';
import '../../features/notification_ingest/presentation/ingestion_route_tracker.dart';
import '../../features/notification_ingest/presentation/notification_ingest_controller.dart';
import '../../features/receipt_ocr/data/ingestion_repository.dart';
import '../../features/receipt_ocr/data/receipt_ocr_factory.dart';
import '../../features/receipt_ocr/domain/receipt_ocr_service.dart';
import '../../features/receipt_ocr/presentation/ingestion_controller.dart';
import '../../features/transactions/data/transactions_repository.dart';
import '../../features/transactions/presentation/transactions_controller.dart';
import '../locale/locale_controller.dart';

/// Root dependency injection.
List<SingleChildWidget> buildAppProviders({
  required LocaleController localeController,
  required AuthController authController,
  AuthRepository? authRepository,
  FamilyController? familyController,
  AccountsRepository? accountsRepository,
  CategoriesRepository? categoriesRepository,
  TransactionsRepository? transactionsRepository,
  TransactionsController? transactionsController,
  BudgetsRepository? budgetsRepository,
  BudgetsController? budgetsController,
  GoalsRepository? goalsRepository,
  GoalsController? goalsController,
  AccountsController? accountsController,
  CategoriesController? categoriesController,
  StatsRepository? statsRepository,
  DashboardController? dashboardController,
  DevicesRepository? devicesRepository,
  IngestionRepository? ingestionRepository,
  IngestionController? ingestionController,
  ReceiptOcrService? receiptOcrService,
  AccountBindingsRepository? accountBindingsRepository,
  AccountBindingsController? accountBindingsController,
  NotificationCaptureService? notificationCaptureService,
  IngestionRouteTracker? ingestionRouteTracker,
  NotificationIngestController? notificationIngestController,
}) {
  final accounts = accountsRepository ?? AccountsRepository();
  final categories = categoriesRepository ?? CategoriesRepository();
  final transactions = transactionsRepository ?? TransactionsRepository();
  final budgets = budgetsRepository ?? BudgetsRepository();
  final goals = goalsRepository ?? GoalsRepository();
  final stats = statsRepository ?? StatsRepository();
  final devices = devicesRepository ?? DevicesRepository();
  final accountBindings =
      accountBindingsRepository ?? AccountBindingsRepository();
  final ingestion =
      ingestionRepository ??
      IngestionRepository(
        transactions: transactions,
        accountBindings: accountBindings,
      );
  final ocr = receiptOcrService ?? createReceiptOcrService();
  final capture =
      notificationCaptureService ?? createNotificationCaptureService();
  final routeTracker = ingestionRouteTracker ?? IngestionRouteTracker();
  final notificationIngest =
      notificationIngestController ??
      NotificationIngestController(
        auth: authController,
        ingestion: ingestion,
        capture: capture,
        routeTracker: routeTracker,
      );
  final family = familyController ?? FamilyController();
  final authRepo = authRepository ?? AuthRepository();

  return [
    ChangeNotifierProvider<LocaleController>.value(value: localeController),
    Provider<AuthRepository>.value(value: authRepo),
    ChangeNotifierProvider<AuthController>.value(value: authController),
    ChangeNotifierProvider<FamilyController>.value(value: family),
    ChangeNotifierProvider<IngestionRouteTracker>.value(value: routeTracker),
    Provider<AccountsRepository>.value(value: accounts),
    Provider<CategoriesRepository>.value(value: categories),
    Provider<TransactionsRepository>.value(value: transactions),
    Provider<BudgetsRepository>.value(value: budgets),
    Provider<GoalsRepository>.value(value: goals),
    Provider<StatsRepository>.value(value: stats),
    Provider<DevicesRepository>.value(value: devices),
    Provider<AccountBindingsRepository>.value(value: accountBindings),
    Provider<IngestionRepository>.value(value: ingestion),
    Provider<ReceiptOcrService>.value(value: ocr),
    Provider<NotificationCaptureService>.value(value: capture),
    Provider<NotificationIngestController>.value(value: notificationIngest),
    ChangeNotifierProvider<TransactionsController>(
      create: (_) =>
          transactionsController ??
          TransactionsController(repository: transactions),
    ),
    ChangeNotifierProvider<BudgetsController>(
      create: (_) =>
          budgetsController ??
          BudgetsController(
            budgetsRepository: budgets,
            categoriesRepository: categories,
          ),
    ),
    ChangeNotifierProvider<DashboardController>(
      create: (_) =>
          dashboardController ??
          DashboardController(
            statsRepository: stats,
            budgetsRepository: budgets,
            categoriesRepository: categories,
          ),
    ),
    ChangeNotifierProvider<AccountsController>(
      create: (_) =>
          accountsController ??
          AccountsController(accountsRepository: accounts),
    ),
    ChangeNotifierProvider<GoalsController>(
      create: (_) => goalsController ?? GoalsController(goalsRepository: goals),
    ),
    ChangeNotifierProvider<CategoriesController>(
      create: (_) =>
          categoriesController ??
          CategoriesController(categoriesRepository: categories),
    ),
    ChangeNotifierProvider<IngestionController>(
      create: (_) =>
          ingestionController ??
          IngestionController(
            ingestionRepository: ingestion,
            accountsRepository: accounts,
          ),
    ),
    ChangeNotifierProvider<AccountBindingsController>(
      create: (_) =>
          accountBindingsController ??
          AccountBindingsController(
            bindingsRepository: accountBindings,
            accountsRepository: accounts,
          ),
    ),
  ];
}
