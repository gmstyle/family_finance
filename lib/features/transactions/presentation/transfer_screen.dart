import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/locale/locale_controller.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../ledger/ledger_labels.dart';
import '../data/transactions_repository.dart';
import 'transactions_controller.dart';

class TransferEditorScreen extends StatefulWidget {
  const TransferEditorScreen({super.key});

  @override
  State<TransferEditorScreen> createState() => _TransferEditorScreenState();
}

class _TransferEditorScreenState extends State<TransferEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  String? _sourceId;
  String? _destinationId;
  String _bookingDate = '';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bookingDate = formatBookingDate(DateTime.now());
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    if (_sourceId == null ||
        _destinationId == null ||
        _sourceId == _destinationId) {
      setState(() => _error = l10n.transferAccountsInvalid);
      return;
    }
    final locale = context.read<LocaleController>().locale.languageCode;
    late final int amountMinor;
    try {
      amountMinor = Money.parseToMinor(_amount.text, locale);
      if (amountMinor <= 0) throw const FormatException('zero');
    } catch (_) {
      setState(() => _error = l10n.moneyInvalid);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<TransactionsController>().repository.createTransfer(
        sourceAccountId: _sourceId!,
        destinationAccountId: _destinationId!,
        amountMinor: amountMinor,
        bookingDate: _bookingDate,
        note: _note.text,
      );
      // List updates via the live Firestore subscription.
      if (mounted) context.pop();
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _error = [e.code, e.message].whereType<String>().join(' — ');
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final familyId = context.watch<AuthController>().familyId;
    final theme = Theme.of(context);

    if (familyId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.transferCreateTitle)),
        body: Center(child: Text(l10n.familyMissing)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transferCreateTitle)),
      body: AppPage(
        form: true,
        padding: AppInsets.page,
        child: Form(
          key: _formKey,
          child: StreamBuilder(
            stream: context.read<AccountsRepository>().watchAccounts(familyId),
            builder: (context, snap) {
              final accounts = snap.data ?? const <Account>[];
              return ListView(
                children: [
                  Text(
                    l10n.transferCreateBody,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _sourceId,
                    decoration: InputDecoration(
                      labelText: l10n.transferSourceAccount,
                    ),
                    items: accounts
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _sourceId = v),
                    validator: (v) =>
                        v == null ? l10n.transferAccountsInvalid : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _destinationId,
                    decoration: InputDecoration(
                      labelText: l10n.transferDestinationAccount,
                    ),
                    items: accounts
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _destinationId = v),
                    validator: (v) =>
                        v == null ? l10n.transferAccountsInvalid : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _amount,
                    decoration: InputDecoration(
                      labelText: l10n.transactionAmount,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l10n.moneyInvalid;
                      }
                      try {
                        final n = Money.parseToMinor(
                          v,
                          context.read<LocaleController>().locale.languageCode,
                        );
                        if (n <= 0) return l10n.moneyInvalid;
                        return null;
                      } catch (_) {
                        return l10n.moneyInvalid;
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.transactionBookingDate),
                    subtitle: Text(_bookingDate),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final v = await pickBookingDate(
                        context,
                        initial: _bookingDate,
                      );
                      if (v != null) setState(() => _bookingDate = v);
                    },
                  ),
                  TextFormField(
                    controller: _note,
                    decoration: InputDecoration(
                      labelText: l10n.transactionNote,
                    ),
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
              );
            },
          ),
        ),
      ),
    );
  }
}
