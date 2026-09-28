import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/money/money.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ledger_async_body.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../family/data/family_repository.dart';
import '../../ledger/ledger_labels.dart';
import '../data/accounts_repository.dart';

String accountTypeLabel(AppLocalizations l10n, AccountType type) {
  return switch (type) {
    AccountType.cash => l10n.accountTypeCash,
    AccountType.bankAccount => l10n.accountTypeBank,
    AccountType.card => l10n.accountTypeCard,
    AccountType.wallet => l10n.accountTypeWallet,
  };
}

class AccountsListScreen extends StatelessWidget {
  const AccountsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final familyId = auth.familyId;
    final locale = context.watch<LocaleController>().locale.languageCode;
    final repo = context.read<AccountsRepository>();
    final familyRepo = context.read<FamilyController>().repository;

    if (familyId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.accountsTitle)),
        body: Center(child: Text(l10n.familyMissing)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountsTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.accountNew),
        child: const Icon(Icons.add),
      ),
      body: AppPage(
        child: StreamBuilder<FamilyInfo?>(
          stream: familyRepo.watchFamily(familyId),
          builder: (context, familySnap) {
            final currency = familySnap.data?.currency ?? 'EUR';
            return StreamBuilder<List<Account>>(
              stream: repo.watchAccounts(familyId, includeArchived: true),
              builder: (context, snap) {
                final error = snap.hasError ? snap.error.toString() : null;
                final accounts = snap.data;
                final active =
                    accounts?.where((a) => !a.archived).toList() ?? const [];
                final archived =
                    accounts?.where((a) => a.archived).toList() ?? const [];

                return LedgerAsyncBody(
                  isLoading:
                      snap.connectionState == ConnectionState.waiting &&
                      accounts == null,
                  errorMessage: error,
                  isEmpty: accounts != null && accounts.isEmpty,
                  emptyMessage: l10n.accountsEmpty,
                  child: ListView(
                    padding: AppInsets.pageCompact,
                    children: [
                      for (final account in active)
                        _AccountTile(
                          account: account,
                          currency: currency,
                          locale: locale,
                          onTap: () => context.push(
                            AppRoutes.accountEditPath(account.id),
                          ),
                          onArchive: () => repo.archiveAccount(
                            familyId: familyId,
                            accountId: account.id,
                          ),
                        ),
                      if (archived.isNotEmpty) ...[
                        AppSectionTitle(
                          l10n.accountsArchived,
                          padding: AppInsets.sectionTight,
                        ),
                        for (final account in archived)
                          _AccountTile(
                            account: account,
                            currency: currency,
                            locale: locale,
                            archived: true,
                            onTap: () => context.push(
                              AppRoutes.accountEditPath(account.id),
                            ),
                            onArchive: () => repo.archiveAccount(
                              familyId: familyId,
                              accountId: account.id,
                              archived: false,
                            ),
                          ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.currency,
    required this.locale,
    required this.onTap,
    required this.onArchive,
    this.archived = false,
  });

  final Account account;
  final String currency;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final extras = AppExtraColors.of(context);
    final amount = Money.formatFromMinor(account.balanceMinor, locale);

    return ListTile(
      leading: Icon(switch (account.type) {
        AccountType.cash => Icons.payments_outlined,
        AccountType.bankAccount => Icons.account_balance_outlined,
        AccountType.card => Icons.credit_card_outlined,
        AccountType.wallet => Icons.account_balance_wallet_outlined,
      }),
      title: Text(account.name),
      subtitle: Text(accountTypeLabel(l10n, account.type)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$amount $currency',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: account.balanceMinor >= 0 ? extras.income : extras.expense,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'archive') onArchive();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'archive',
                child: Text(
                  archived ? l10n.actionUnarchive : l10n.actionArchive,
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class AccountEditorScreen extends StatefulWidget {
  const AccountEditorScreen({super.key, this.accountId});

  final String? accountId;

  @override
  State<AccountEditorScreen> createState() => _AccountEditorScreenState();
}

class _AccountEditorScreenState extends State<AccountEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _opening = TextEditingController();
  AccountType _type = AccountType.bankAccount;
  String _openingDate = '';
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Account? _existing;

  bool get _isEdit => widget.accountId != null;

  @override
  void initState() {
    super.initState();
    _openingDate = formatBookingDate(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final familyId = context.read<AuthController>().familyId;
    final locale = context.read<LocaleController>().locale.languageCode;
    if (familyId == null || widget.accountId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final account = await context.read<AccountsRepository>().getAccount(
        familyId,
        widget.accountId!,
      );
      if (account == null) {
        setState(() {
          _error = AppLocalizations.of(context)!.ledgerNotFound;
          _loading = false;
        });
        return;
      }
      _existing = account;
      _name.text = account.name;
      _type = account.type;
      _opening.text = Money.formatFromMinor(
        account.openingBalanceMinor,
        locale,
      );
      _openingDate = account.openingDate.isEmpty
          ? formatBookingDate(DateTime.now())
          : account.openingDate;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final familyId = context.read<AuthController>().familyId;
    if (familyId == null) return;
    final locale = context.read<LocaleController>().locale.languageCode;

    late final int openingMinor;
    try {
      openingMinor = Money.parseToMinor(_opening.text, locale);
    } catch (_) {
      setState(() => _error = l10n.moneyInvalid);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = context.read<AccountsRepository>();
      if (_isEdit) {
        await repo.updateAccount(
          familyId: familyId,
          accountId: widget.accountId!,
          name: _name.text,
          type: _type,
          openingBalanceMinor: openingMinor,
          openingDate: _openingDate,
        );
      } else {
        await repo.createAccount(
          familyId: familyId,
          name: _name.text,
          type: _type,
          openingBalanceMinor: openingMinor,
          openingDate: _openingDate,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.accountEditTitle : l10n.accountCreateTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AppPage(
              form: true,
              padding: AppInsets.page,
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: InputDecoration(labelText: l10n.accountName),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? l10n.accountNameInvalid
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<AccountType>(
                      // ignore: deprecated_member_use
                      value: _type,
                      decoration: InputDecoration(labelText: l10n.accountType),
                      items: AccountType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(accountTypeLabel(l10n, t)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _type = v);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _opening,
                      decoration: InputDecoration(
                        labelText: l10n.accountOpeningBalance,
                        helperText: _existing != null
                            ? l10n.accountBalanceHint(
                                Money.formatFromMinor(
                                  _existing!.balanceMinor,
                                  context
                                      .read<LocaleController>()
                                      .locale
                                      .languageCode,
                                ),
                              )
                            : null,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.moneyInvalid;
                        }
                        try {
                          Money.parseToMinor(
                            v,
                            context
                                .read<LocaleController>()
                                .locale
                                .languageCode,
                          );
                          return null;
                        } catch (_) {
                          return l10n.moneyInvalid;
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.accountOpeningDate),
                      subtitle: Text(_openingDate),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final initial =
                            DateTime.tryParse(_openingDate) ?? DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        setState(() {
                          _openingDate = formatBookingDate(picked);
                        });
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: AppSizes.buttonProgress,
                              height: AppSizes.buttonProgress,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.actionSave),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
