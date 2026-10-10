import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/presentation/accounts_screens.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/budgets/presentation/budget_editor_screen.dart';
import '../../features/budgets/presentation/budgets_list_screen.dart';
import '../../features/categories/presentation/categories_screens.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/family/presentation/create_family_screen.dart';
import '../../features/family/presentation/family_screens.dart';
import '../../features/goals/presentation/goal_contribute_screen.dart';
import '../../features/goals/presentation/goal_editor_screen.dart';
import '../../features/goals/presentation/goals_list_screen.dart';
import '../../features/notification_ingest/presentation/account_bindings_screen.dart';
import '../../features/notification_ingest/presentation/ingestion_route_tracker.dart';
import '../../features/receipt_ocr/presentation/ingestion_detail_screen.dart';
import '../../features/receipt_ocr/presentation/ingestion_inbox_screen.dart';
import '../../features/receipt_ocr/presentation/receipt_scan_screen.dart';
import '../../features/settings/presentation/privacy_policy_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/transactions/presentation/transaction_editor_screen.dart';
import '../../features/transactions/presentation/transactions_list_screen.dart';
import '../../features/transactions/presentation/transfer_screen.dart';
import '../../l10n/app_localizations.dart';
import '../locale/locale_controller.dart';
import '../theme/app_breakpoints.dart';
import 'listenable_merge.dart';

/// Application routes.
abstract final class AppRoutes {
  static const home = '/';
  static const transactions = '/transactions';
  static const transactionNew = '/transactions/new';
  static const transactionEdit = '/transactions/:id';
  static const accounts = '/accounts';
  static const accountNew = '/accounts/new';
  static const accountEdit = '/accounts/:id';
  static const categories = '/categories';
  static const budgets = '/budgets';
  static const budgetNew = '/budgets/new';
  static const budgetEdit = '/budgets/:id';
  static const goals = '/goals';
  static const goalNew = '/goals/new';
  static const goalEdit = '/goals/:id';
  static const goalContribute = '/goals/:id/contribute';
  static const transferNew = '/transfers/new';
  static const ingestion = '/ingestion';
  static const ingestionDetail = '/ingestion/:id';
  static const receiptScan = '/receipt-scan';
  static const accountBindings = '/account-bindings';
  static const settings = '/settings';
  static const settingsPrivacy = '/settings/privacy';
  static const family = '/family';
  static const signIn = '/sign-in';
  static const forgotPassword = '/forgot-password';
  static const verifyEmail = '/verify-email';
  static const onboardingFamily = '/onboarding/family';
  static const invite = '/invite/:token';

  static String invitePath(String token) => '/invite/$token';
  static String accountEditPath(String id) => '/accounts/$id';
  static String transactionEditPath(String id) => '/transactions/$id';
  static String budgetEditPath(String id) => '/budgets/$id';
  static String goalEditPath(String id) => '/goals/$id';
  static String goalContributePath(String id) => '/goals/$id/contribute';
  static String ingestionDetailPath(String id) => '/ingestion/$id';
}

/// Invite deep link preserved across sign-in / verify (`?next=/invite/...`).
String _initialLocation() {
  if (kIsWeb) {
    final path = Uri.base.path;
    if (path.isNotEmpty && path != '/') {
      final query = Uri.base.hasQuery ? '?${Uri.base.query}' : '';
      return '$path$query';
    }
  }
  return AppRoutes.home;
}

String? pendingInvitePath(GoRouterState state, AuthController auth) {
  final next = state.uri.queryParameters['next'];
  if (next != null &&
      next.startsWith('/invite/') &&
      next.length > '/invite/'.length) {
    return next;
  }
  if (state.matchedLocation.startsWith('/invite/')) {
    return state.matchedLocation;
  }
  final stored = auth.pendingInvitePath;
  if (stored != null &&
      stored.startsWith('/invite/') &&
      stored.length > '/invite/'.length) {
    return stored;
  }
  return null;
}

GoRouter createAppRouter({
  required LocaleController localeController,
  required AuthController authController,
  IngestionRouteTracker? ingestionRouteTracker,
}) {
  final refresh = ListenableMerge([localeController, authController]);

  return GoRouter(
    initialLocation: _initialLocation(),
    refreshListenable: refresh,
    redirect: (context, state) {
      ingestionRouteTracker?.updateFromLocation(state.matchedLocation);
      final loc = state.matchedLocation;
      final loggedIn = authController.isSignedIn;
      final profileReady = authController.profileReady;
      final verified = authController.isEmailVerified;
      final hasFamily = authController.hasFamily;

      final isAuthRoute =
          loc == AppRoutes.signIn ||
          loc == AppRoutes.forgotPassword ||
          loc.startsWith('/invite/');
      final isVerify = loc == AppRoutes.verifyEmail;
      final isOnboarding = loc == AppRoutes.onboardingFamily;

      final pendingInvite = pendingInvitePath(state, authController);

      // Wait until we know auth + user doc state (except public auth routes).
      if (loggedIn && !profileReady && !isAuthRoute && pendingInvite == null) {
        return null;
      }

      if (!loggedIn) {
        if (isAuthRoute) return null;
        return AppRoutes.signIn;
      }

      if (!verified) {
        if (isVerify || loc.startsWith('/invite/')) return null;
        if (pendingInvite != null) {
          return '${AppRoutes.verifyEmail}?next=${Uri.encodeComponent(pendingInvite)}';
        }
        return AppRoutes.verifyEmail;
      }

      if (!hasFamily) {
        if (loc.startsWith('/invite/')) return null;
        if (pendingInvite != null) {
          // Stay on verify/sign-in while finishing auth; accept runs globally.
          if (isVerify ||
              loc == AppRoutes.signIn ||
              loc == AppRoutes.forgotPassword) {
            return null;
          }
          return pendingInvite;
        }
        if (isOnboarding) return null;
        if (loc == AppRoutes.signIn ||
            loc == AppRoutes.forgotPassword ||
            loc == AppRoutes.verifyEmail) {
          return AppRoutes.onboardingFamily;
        }
        return AppRoutes.onboardingFamily;
      }

      // Signed in with family: keep auth screens away.
      if (loc == AppRoutes.signIn ||
          loc == AppRoutes.verifyEmail ||
          loc == AppRoutes.onboardingFamily ||
          loc == AppRoutes.forgotPassword) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.signIn,
        name: 'signIn',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        name: 'verifyEmail',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingFamily,
        name: 'onboardingFamily',
        builder: (context, state) => const CreateFamilyScreen(),
      ),
      GoRoute(
        path: AppRoutes.invite,
        name: 'invite',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return AcceptInviteScreen(token: token);
        },
      ),
      GoRoute(
        path: AppRoutes.family,
        name: 'family',
        builder: (context, state) => const FamilyManageScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountNew,
        name: 'accountNew',
        builder: (context, state) => const AccountEditorScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountEdit,
        name: 'accountEdit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AccountEditorScreen(accountId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.transactionNew,
        name: 'transactionNew',
        builder: (context, state) => const TransactionEditorScreen(),
      ),
      GoRoute(
        path: AppRoutes.transactionEdit,
        name: 'transactionEdit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TransactionEditorScreen(transactionId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.transferNew,
        name: 'transferNew',
        builder: (context, state) => const TransferEditorScreen(),
      ),
      GoRoute(
        path: AppRoutes.budgetNew,
        name: 'budgetNew',
        builder: (context, state) => const BudgetEditorScreen(),
      ),
      GoRoute(
        path: AppRoutes.budgetEdit,
        name: 'budgetEdit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BudgetEditorScreen(budgetId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.goalNew,
        name: 'goalNew',
        builder: (context, state) => const GoalEditorScreen(),
      ),
      GoRoute(
        path: AppRoutes.goalEdit,
        name: 'goalEdit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return GoalEditorScreen(goalId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.goalContribute,
        name: 'goalContribute',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return GoalContributeScreen(goalId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.ingestion,
        name: 'ingestion',
        builder: (context, state) => const IngestionInboxScreen(),
      ),
      GoRoute(
        path: AppRoutes.ingestionDetail,
        name: 'ingestionDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return IngestionDetailScreen(dedupKey: id);
        },
      ),
      GoRoute(
        path: AppRoutes.receiptScan,
        name: 'receiptScan',
        builder: (context, state) => const ReceiptScanScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountBindings,
        name: 'accountBindings',
        builder: (context, state) => const AccountBindingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsPrivacy,
        name: 'settingsPrivacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.transactions,
                name: 'transactions',
                builder: (context, state) => const TransactionsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.budgets,
                name: 'budgets',
                builder: (context, state) => const BudgetsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.goals,
                name: 'goals',
                builder: (context, state) => const GoalsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      // Accounts & categories remain reachable (settings / dashboard chips).
      GoRoute(
        path: AppRoutes.accounts,
        name: 'accounts',
        builder: (context, state) => const AccountsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.categories,
        name: 'categories',
        builder: (context, state) => const CategoriesListScreen(),
      ),
    ],
  );
}

/// Responsive shell: bottom nav on mobile/tablet, rail on wide (≥840).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final useRail = AppBreakpoints.useNavigationRail(context);

    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: l10n.navHome,
      ),
      NavigationDestination(
        icon: const Icon(Icons.receipt_long_outlined),
        selectedIcon: const Icon(Icons.receipt_long),
        label: l10n.navTransactions,
      ),
      NavigationDestination(
        icon: const Icon(Icons.pie_chart_outline),
        selectedIcon: const Icon(Icons.pie_chart),
        label: l10n.navBudgets,
      ),
      NavigationDestination(
        icon: const Icon(Icons.flag_outlined),
        selectedIcon: const Icon(Icons.flag),
        label: l10n.navGoals,
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: l10n.navSettings,
      ),
    ];

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: navigationShell.goBranch,
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard),
                  label: Text(l10n.navHome),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.receipt_long_outlined),
                  selectedIcon: const Icon(Icons.receipt_long),
                  label: Text(l10n.navTransactions),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.pie_chart_outline),
                  selectedIcon: const Icon(Icons.pie_chart),
                  label: Text(l10n.navBudgets),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.flag_outlined),
                  selectedIcon: const Icon(Icons.flag),
                  label: Text(l10n.navGoals),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: Text(l10n.navSettings),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: destinations,
      ),
    );
  }
}
