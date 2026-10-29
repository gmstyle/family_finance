import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/family/presentation/family_controller.dart';
import '../../features/receipt_ocr/presentation/ingestion_controller.dart';
import '../../features/settings/presentation/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../router/app_router.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_tokens.dart';
import 'kinship_brand_mark.dart';

/// Stitch Kinship responsive shell: wide sidebar + top bar, or compact
/// header + 4-tab bottom nav + FAB.
class KinshipScaffold extends StatefulWidget {
  const KinshipScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<KinshipScaffold> createState() => _KinshipScaffoldState();
}

class _KinshipScaffoldState extends State<KinshipScaffold> {
  String? _boundFamilyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final familyId = context.watch<AuthController>().familyId;
    if (familyId != _boundFamilyId) {
      _boundFamilyId = familyId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<IngestionController>().bindFamily(familyId);
      });
    }
  }

  StatefulNavigationShell get _shell => widget.navigationShell;

  int get _pendingCount => context.watch<IngestionController>().pending.length;

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthController>();
    final settings = context.read<SettingsController>();
    try {
      await settings.exportAndShare(familyId: auth.familyId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.settingsExportDone)));
    } catch (_) {
      if (!mounted) return;
      final msg = settings.errorMessage ?? l10n.settingsDeleteFailedGeneric;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _openSettings() => context.push(AppRoutes.settings);

  void _openFamily() => context.push(AppRoutes.family);

  void _openReview() {
    _shell.goBranch(2, initialLocation: _shell.currentIndex == 2);
  }

  void _openSearch() {
    _shell.goBranch(1, initialLocation: _shell.currentIndex == 1);
  }

  Future<void> _showAddSheet() async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: Text(l10n.shellAddTransaction),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.transactionNew);
                },
              ),
              ListTile(
                leading: const Icon(Icons.document_scanner_outlined),
                title: Text(l10n.shellScanReceipt),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.receiptScan);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.useNavigationRail(context)) {
      return _WideShell(
        navigationShell: _shell,
        pendingCount: _pendingCount,
        onExport: _export,
        onOpenSettings: _openSettings,
        onOpenFamily: _openFamily,
        onOpenReview: _openReview,
        onOpenSearch: _openSearch,
      );
    }

    return _CompactShell(
      navigationShell: _shell,
      pendingCount: _pendingCount,
      onOpenSettings: _openSettings,
      onOpenFamily: _openFamily,
      onOpenReview: _openReview,
      onAdd: _showAddSheet,
    );
  }
}

class _WideShell extends StatelessWidget {
  const _WideShell({
    required this.navigationShell,
    required this.pendingCount,
    required this.onExport,
    required this.onOpenSettings,
    required this.onOpenFamily,
    required this.onOpenReview,
    required this.onOpenSearch,
  });

  final StatefulNavigationShell navigationShell;
  final int pendingCount;
  final VoidCallback onExport;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenFamily;
  final VoidCallback onOpenReview;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: navigationShell.currentIndex,
            pendingCount: pendingCount,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            onOpenSettings: onOpenSettings,
            onOpenFamily: onOpenFamily,
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  pendingCount: pendingCount,
                  onExport: onExport,
                  onOpenSettings: onOpenSettings,
                  onOpenFamily: onOpenFamily,
                  onOpenReview: onOpenReview,
                  onOpenSearch: onOpenSearch,
                ),
                Expanded(
                  child: ColoredBox(
                    color: scheme.surface,
                    child: navigationShell,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactShell extends StatelessWidget {
  const _CompactShell({
    required this.navigationShell,
    required this.pendingCount,
    required this.onOpenSettings,
    required this.onOpenFamily,
    required this.onOpenReview,
    required this.onAdd,
  });

  final StatefulNavigationShell navigationShell;
  final int pendingCount;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenFamily;
  final VoidCallback onOpenReview;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final extras = AppExtraColors.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _CompactHeader(
          onOpenFamily: onOpenFamily,
          onOpenSettings: onOpenSettings,
          onOpenReview: onOpenReview,
          pendingCount: pendingCount,
        ),
      ),
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        tooltip: l10n.shellAddExpense,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: Material(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.92),
        elevation: 0,
        shadowColor: AppPalette.primaryContainer.withValues(alpha: 0.06),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: [
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
              icon: _BadgeIcon(
                icon: Icons.inbox_outlined,
                count: pendingCount,
                badgeColor: extras.pending,
                badgeForeground: extras.onPending,
              ),
              selectedIcon: _BadgeIcon(
                icon: Icons.inbox,
                count: pendingCount,
                badgeColor: extras.pending,
                badgeForeground: extras.onPending,
              ),
              label: l10n.navReview,
            ),
            NavigationDestination(
              icon: const Icon(Icons.savings_outlined),
              selectedIcon: const Icon(Icons.savings),
              label: l10n.navBudgets,
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedIndex,
    required this.pendingCount,
    required this.onDestinationSelected,
    required this.onOpenSettings,
    required this.onOpenFamily,
  });

  final int selectedIndex;
  final int pendingCount;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenFamily;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: SizedBox(
        width: AppSizes.sidebarWidth,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const KinshipBrandMark(size: 40),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.appTitle,
                            style: textTheme.titleMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            l10n.shellBrandTagline.toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _FamilySwitcherChip(onTap: onOpenFamily),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: ListView(
                    children: [
                      _SidebarNavItem(
                        icon: Icons.dashboard_outlined,
                        label: l10n.navHome,
                        selected: selectedIndex == 0,
                        onTap: () => onDestinationSelected(0),
                      ),
                      _SidebarNavItem(
                        icon: Icons.rule_outlined,
                        label: l10n.ingestionTitle,
                        selected: selectedIndex == 2,
                        badgeCount: pendingCount,
                        onTap: () => onDestinationSelected(2),
                      ),
                      _SidebarNavItem(
                        icon: Icons.receipt_long_outlined,
                        label: l10n.navTransactions,
                        selected: selectedIndex == 1,
                        onTap: () => onDestinationSelected(1),
                      ),
                      _SidebarNavItem(
                        icon: Icons.savings_outlined,
                        label: l10n.navBudgetGoals,
                        selected: selectedIndex == 3,
                        onTap: () => onDestinationSelected(3),
                      ),
                    ],
                  ),
                ),
                _SidebarNavItem(
                  icon: Icons.manage_accounts_outlined,
                  label: l10n.shellSettingsMembers,
                  selected: false,
                  onTap: onOpenSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bg = selected ? scheme.primaryContainer : Colors.transparent;
    final fg = selected ? scheme.onPrimary : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Material(
        color: bg,
        borderRadius: AppRadius.fullAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.fullAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: fg),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.labelLarge?.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: AppRadius.fullAll,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilySwitcherChip extends StatelessWidget {
  const _FamilySwitcherChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final familyId = context.watch<AuthController>().familyId;
    final familyCtrl = context.watch<FamilyController>();

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: scheme.primaryFixed,
                child: Icon(
                  Icons.diversity_3,
                  size: 18,
                  color: scheme.onPrimaryFixed,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: familyId == null
                    ? Text(l10n.familyMissing, style: textTheme.labelLarge)
                    : StreamBuilder(
                        stream: familyCtrl.watchFamily(familyId),
                        builder: (context, snapshot) {
                          final name = snapshot.data?.name;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.shellActiveFamily,
                                style: textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1,
                                ),
                              ),
                              Text(
                                (name == null || name.isEmpty)
                                    ? l10n.familyTitle
                                    : name,
                                style: textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        },
                      ),
              ),
              Icon(Icons.unfold_more, size: 20, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.pendingCount,
    required this.onExport,
    required this.onOpenSettings,
    required this.onOpenFamily,
    required this.onOpenReview,
    required this.onOpenSearch,
  });

  final int pendingCount;
  final VoidCallback onExport;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenFamily;
  final VoidCallback onOpenReview;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final auth = context.watch<AuthController>();
    final familyId = auth.familyId;
    final familyCtrl = context.watch<FamilyController>();
    final exportBusy = context.watch<SettingsController>().exportBusy;

    return Material(
      color: scheme.surface.withValues(alpha: 0.8),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: Material(
                    color: scheme.surfaceContainerLow,
                    borderRadius: AppRadius.fullAll,
                    child: InkWell(
                      onTap: onOpenSearch,
                      borderRadius: AppRadius.fullAll,
                      child: SizedBox(
                        height: 40,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                size: 20,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  l10n.shellSearchHint,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: scheme.outline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              if (familyId != null)
                StreamBuilder(
                  stream: familyCtrl.watchFamily(familyId),
                  builder: (context, snapshot) {
                    final name = snapshot.data?.name;
                    if (name == null || name.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      child: Material(
                        color: scheme.primaryFixed.withValues(alpha: 0.4),
                        borderRadius: AppRadius.fullAll,
                        child: InkWell(
                          onTap: onOpenFamily,
                          borderRadius: AppRadius.fullAll,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.home_work_outlined,
                                  size: 16,
                                  color: scheme.onPrimaryFixedVariant,
                                ),
                                const SizedBox(width: AppSpacing.xxs),
                                Text(
                                  name,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: scheme.onPrimaryFixedVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              Material(
                color: scheme.surfaceContainerLow,
                borderRadius: AppRadius.fullAll,
                child: InkWell(
                  onTap: exportBusy ? null : onExport,
                  borderRadius: AppRadius.fullAll,
                  child: SizedBox(
                    height: 36,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          if (exportBusy)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(
                              Icons.file_download_outlined,
                              size: 18,
                              color: scheme.onSurface,
                            ),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            l10n.shellExport,
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _IconRoundButton(
                tooltip: l10n.shellNotifications,
                icon: Icons.notifications_outlined,
                onPressed: onOpenReview,
                showDot: pendingCount > 0,
              ),
              const SizedBox(width: AppSpacing.sm),
              InkWell(
                onTap: onOpenSettings,
                borderRadius: AppRadius.fullAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: scheme.primary,
                        child: Icon(
                          Icons.person,
                          size: 18,
                          color: scheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.user?.displayName?.trim().isNotEmpty == true
                                ? auth.user!.displayName!
                                : (auth.user?.email ?? l10n.navSettings),
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            l10n.navSettings,
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.onOpenFamily,
    required this.onOpenSettings,
    required this.onOpenReview,
    required this.pendingCount,
  });

  final VoidCallback onOpenFamily;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenReview;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final familyId = context.watch<AuthController>().familyId;
    final familyCtrl = context.watch<FamilyController>();

    return Material(
      color: scheme.surface.withValues(alpha: 0.85),
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
            child: Row(
              children: [
                const KinshipBrandMark(size: 32),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appTitle.toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0.6,
                        ),
                      ),
                      InkWell(
                        onTap: onOpenFamily,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: familyId == null
                                  ? Text(
                                      l10n.familyTitle,
                                      style: textTheme.titleMedium?.copyWith(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : StreamBuilder(
                                      stream: familyCtrl.watchFamily(familyId),
                                      builder: (context, snapshot) {
                                        final name = snapshot.data?.name;
                                        return Text(
                                          (name == null || name.isEmpty)
                                              ? l10n.familyTitle
                                              : name,
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                color: scheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                            ),
                            Icon(
                              Icons.expand_more,
                              size: 18,
                              color: scheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _IconRoundButton(
                  tooltip: l10n.shellNotifications,
                  icon: Icons.notifications_outlined,
                  onPressed: onOpenReview,
                  showDot: pendingCount > 0,
                  large: true,
                ),
                const SizedBox(width: AppSpacing.xxs),
                IconButton(
                  tooltip: l10n.navSettings,
                  onPressed: onOpenSettings,
                  icon: CircleAvatar(
                    radius: 16,
                    backgroundColor: scheme.primary,
                    child: Icon(
                      Icons.person,
                      size: 18,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconRoundButton extends StatelessWidget {
  const _IconRoundButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.showDot = false,
    this.large = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool showDot;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = large ? 44.0 : 36.0;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: large ? Colors.transparent : scheme.surfaceContainerLow,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: large ? 24 : 20, color: scheme.onSurface),
                if (showDot)
                  Positioned(
                    top: large ? 10 : 8,
                    right: large ? 10 : 8,
                    child: Container(
                      width: large ? 10 : 8,
                      height: large ? 10 : 8,
                      decoration: BoxDecoration(
                        color: scheme.secondary,
                        shape: BoxShape.circle,
                        border: large
                            ? Border.all(color: scheme.surface, width: 2)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({
    required this.icon,
    required this.count,
    required this.badgeColor,
    required this.badgeForeground,
  });

  final IconData icon;
  final int count;
  final Color badgeColor;
  final Color badgeForeground;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return Icon(icon);
    return Badge(
      backgroundColor: badgeColor,
      textColor: badgeForeground,
      label: Text(count > 99 ? '99+' : '$count'),
      child: Icon(icon),
    );
  }
}
