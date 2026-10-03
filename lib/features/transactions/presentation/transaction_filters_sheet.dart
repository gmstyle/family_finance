import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/accounts_controller.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_controller.dart';
import '../../family/presentation/family_controller.dart';
import '../../ledger/ledger_labels.dart';
import '../domain/transaction.dart';

class TransactionFiltersSheet extends StatefulWidget {
  const TransactionFiltersSheet({super.key, required this.initial});

  final TransactionFilters initial;

  @override
  State<TransactionFiltersSheet> createState() =>
      TransactionFiltersSheetState();
}

class TransactionFiltersSheetState extends State<TransactionFiltersSheet> {
  late String? _accountId = widget.initial.accountId;
  late String? _categoryId = widget.initial.categoryId;
  late String? _memberId = widget.initial.memberId;
  late String? _from = widget.initial.bookingDateFrom;
  late String? _to = widget.initial.bookingDateTo;
  String? _boundFamilyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final familyId = context.watch<AuthController>().familyId;
    if (familyId != _boundFamilyId) {
      _boundFamilyId = familyId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AccountsController>().bindFamily(familyId);
        context.read<CategoriesController>().bindFamily(familyId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final familyId = context.read<AuthController>().familyId!;
    final accountsCtrl = context.read<AccountsController>();
    final categoriesCtrl = context.read<CategoriesController>();
    final familyCtrl = context.read<FamilyController>();

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.transactionsFilters,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            StreamBuilder(
              stream: accountsCtrl.watchAccounts(),
              builder: (context, snap) {
                final accounts = snap.data ?? const <Account>[];
                return DropdownButtonFormField<String?>(
                  // ignore: deprecated_member_use
                  value: _accountId,
                  decoration: InputDecoration(labelText: l10n.filterAccount),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.filterAll)),
                    ...accounts.map(
                      (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _accountId = v),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            StreamBuilder(
              stream: categoriesCtrl.watchCategories(),
              builder: (context, snap) {
                final cats = snap.data ?? const <Category>[];
                return DropdownButtonFormField<String?>(
                  // ignore: deprecated_member_use
                  value: _categoryId,
                  decoration: InputDecoration(labelText: l10n.filterCategory),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.filterAll)),
                    ...cats.map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(categoryLabel(l10n, c)),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            StreamBuilder(
              stream: familyCtrl.watchMembers(familyId),
              builder: (context, snap) {
                final members = snap.data ?? const <FamilyMember>[];
                return DropdownButtonFormField<String?>(
                  // ignore: deprecated_member_use
                  value: _memberId,
                  decoration: InputDecoration(labelText: l10n.filterMember),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.filterAll)),
                    ...members.map(
                      (m) => DropdownMenuItem(
                        value: m.userId,
                        child: Text(m.displayName),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _memberId = v),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.filterDateFrom),
              subtitle: Text(_from ?? l10n.filterAll),
              trailing: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _from = null),
              ),
              onTap: () async {
                final v = await pickBookingDate(context, initial: _from);
                if (v != null) setState(() => _from = v);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.filterDateTo),
              subtitle: Text(_to ?? l10n.filterAll),
              trailing: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _to = null),
              ),
              onTap: () async {
                final v = await pickBookingDate(context, initial: _to);
                if (v != null) setState(() => _to = v);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pop(context, const TransactionFilters()),
                    child: Text(l10n.actionClearFilters),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      TransactionFilters(
                        accountId: _accountId,
                        categoryId: _categoryId,
                        memberId: _memberId,
                        bookingDateFrom: _from,
                        bookingDateTo: _to,
                      ),
                    ),
                    child: Text(l10n.actionApply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
