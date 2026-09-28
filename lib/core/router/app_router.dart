import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/presentation/accounts_screens.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/categories/presentation/categories_screens.dart';
import '../../features/family/presentation/create_family_screen.dart';
import '../../features/family/presentation/family_screens.dart';
import '../../features/ledger/presentation/ledger_home_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/transactions/presentation/transactions_screens.dart';
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
  static const transferNew = '/transfers/new';
  static const settings = '/settings';
  static const family = '/family';
  static const signIn = '/sign-in';
  static const forgotPassword = '/forgot-password';
  static const verifyEmail = '/verify-email';
  static const onboardingFamily = '/onboarding/family';
  static const invite = '/invite/:token';

  static String invitePath(String token) => '/invite/$token';
  static String accountEditPath(String id) => '/accounts/$id';
  static String transactionEditPath(String id) => '/transactions/$id';
}

GoRouter createAppRouter({
  required LocaleController localeController,
  required AuthController authController,
}) {
  final refresh = ListenableMerge([localeController, authController]);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
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

      // Wait until we know auth + user doc state (except public auth routes).
      if (loggedIn && !profileReady && !isAuthRoute) {
        return null;
      }

      if (!loggedIn) {
        if (isAuthRoute) return null;
        return AppRoutes.signIn;
      }

      if (!verified) {
        if (isVerify || loc.startsWith('/invite/')) return null;
        return AppRoutes.verifyEmail;
      }

      if (!hasFamily) {
        if (isOnboarding || loc.startsWith('/invite/')) return null;
        if (isAuthRoute) return AppRoutes.onboardingFamily;
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
                builder: (context, state) => const LedgerHomeScreen(),
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
                path: AppRoutes.accounts,
                name: 'accounts',
                builder: (context, state) => const AccountsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.categories,
                name: 'categories',
                builder: (context, state) => const CategoriesListScreen(),
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
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: l10n.navHome,
      ),
      NavigationDestination(
        icon: const Icon(Icons.receipt_long_outlined),
        selectedIcon: const Icon(Icons.receipt_long),
        label: l10n.navTransactions,
      ),
      NavigationDestination(
        icon: const Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: const Icon(Icons.account_balance_wallet),
        label: l10n.navAccounts,
      ),
      NavigationDestination(
        icon: const Icon(Icons.category_outlined),
        selectedIcon: const Icon(Icons.category),
        label: l10n.navCategories,
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
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: Text(l10n.navHome),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.receipt_long_outlined),
                  selectedIcon: const Icon(Icons.receipt_long),
                  label: Text(l10n.navTransactions),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: const Icon(Icons.account_balance_wallet),
                  label: Text(l10n.navAccounts),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.category_outlined),
                  selectedIcon: const Icon(Icons.category),
                  label: Text(l10n.navCategories),
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
