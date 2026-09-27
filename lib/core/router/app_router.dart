import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/family/presentation/create_family_screen.dart';
import '../../features/family/presentation/family_screens.dart';
import '../../features/home/presentation/home_placeholder_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../l10n/app_localizations.dart';
import '../locale/locale_controller.dart';
import '../theme/app_breakpoints.dart';
import 'listenable_merge.dart';

/// Application routes.
abstract final class AppRoutes {
  static const home = '/';
  static const settings = '/settings';
  static const family = '/family';
  static const signIn = '/sign-in';
  static const forgotPassword = '/forgot-password';
  static const verifyEmail = '/verify-email';
  static const onboardingFamily = '/onboarding/family';
  static const invite = '/invite/:token';

  static String invitePath(String token) => '/invite/$token';
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
                builder: (context, state) => const HomePlaceholderScreen(),
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
