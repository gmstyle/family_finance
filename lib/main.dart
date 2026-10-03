import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/di/app_providers.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/locale/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/devices/data/devices_repository.dart';
import 'features/notification_ingest/data/account_bindings_repository.dart';
import 'features/notification_ingest/data/notification_capture_factory.dart';
import 'features/notification_ingest/domain/notification_capture_service.dart';
import 'features/notification_ingest/presentation/ingestion_route_tracker.dart';
import 'features/notification_ingest/presentation/notification_ingest_controller.dart';
import 'features/receipt_ocr/data/ingestion_repository.dart';
import 'features/transactions/data/transactions_repository.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  final localeController = await LocaleController.create();
  final authRepository = AuthRepository();
  final authController = AuthController(repository: authRepository);
  final fcm = FcmRegistration(auth: FirebaseAuth.instance)..start();

  final routeTracker = IngestionRouteTracker();
  final capture = createNotificationCaptureService();
  final transactions = TransactionsRepository();
  final accountBindings = AccountBindingsRepository();
  final ingestion = IngestionRepository(
    transactions: transactions,
    accountBindings: accountBindings,
  );
  final notificationIngest = NotificationIngestController(
    auth: authController,
    ingestion: ingestion,
    capture: capture,
    routeTracker: routeTracker,
  )..start();

  runApp(
    FamilyFinanceApp(
      localeController: localeController,
      authController: authController,
      authRepository: authRepository,
      fcmRegistration: fcm,
      ingestionRouteTracker: routeTracker,
      notificationIngestController: notificationIngest,
      ingestionRepository: ingestion,
      transactionsRepository: transactions,
      accountBindingsRepository: accountBindings,
      notificationCaptureService: capture,
    ),
  );
}

class FamilyFinanceApp extends StatefulWidget {
  const FamilyFinanceApp({
    super.key,
    required this.localeController,
    required this.authController,
    this.fcmRegistration,
    this.ingestionRouteTracker,
    this.notificationIngestController,
    this.ingestionRepository,
    this.transactionsRepository,
    this.accountBindingsRepository,
    this.notificationCaptureService,
    this.authRepository,
  });

  final LocaleController localeController;
  final AuthController authController;
  final AuthRepository? authRepository;
  final FcmRegistration? fcmRegistration;
  final IngestionRouteTracker? ingestionRouteTracker;
  final NotificationIngestController? notificationIngestController;
  final IngestionRepository? ingestionRepository;
  final TransactionsRepository? transactionsRepository;
  final AccountBindingsRepository? accountBindingsRepository;
  final NotificationCaptureService? notificationCaptureService;

  @override
  State<FamilyFinanceApp> createState() => _FamilyFinanceAppState();
}

class _FamilyFinanceAppState extends State<FamilyFinanceApp> {
  late final _routeTracker =
      widget.ingestionRouteTracker ?? IngestionRouteTracker();

  late final _router = createAppRouter(
    localeController: widget.localeController,
    authController: widget.authController,
    ingestionRouteTracker: _routeTracker,
  );

  @override
  void dispose() {
    widget.fcmRegistration?.dispose();
    widget.notificationIngestController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildAppProviders(
        localeController: widget.localeController,
        authController: widget.authController,
        authRepository: widget.authRepository,
        ingestionRepository: widget.ingestionRepository,
        transactionsRepository: widget.transactionsRepository,
        accountBindingsRepository: widget.accountBindingsRepository,
        ingestionRouteTracker: _routeTracker,
        notificationIngestController: widget.notificationIngestController,
        notificationCaptureService: widget.notificationCaptureService,
      ),
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
            builder: (context, child) {
              final l10n = AppLocalizations.of(context);
              final ingest = widget.notificationIngestController;
              if (l10n != null && ingest != null) {
                ingest.titleForCount = l10n.notificationDraftAlertTitle;
                ingest.bodyForCount = (_) => l10n.notificationDraftAlertBody;
                ingest.onOpenInbox = () => _router.go(AppRoutes.ingestion);
              }
              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
