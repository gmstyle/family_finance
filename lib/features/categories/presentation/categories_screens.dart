import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/app_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ledger_async_body.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../ledger/ledger_labels.dart';
import '../data/categories_repository.dart';

class CategoriesListScreen extends StatefulWidget {
  const CategoriesListScreen({super.key});

  @override
  State<CategoriesListScreen> createState() => _CategoriesListScreenState();
}

class _CategoriesListScreenState extends State<CategoriesListScreen> {
  bool _showArchived = false;

  Future<void> _createCategory() async {
    final result = await showDialog<_NewCategoryDraft>(
      context: context,
      builder: (context) => const _CreateCategoryDialog(),
    );
    if (result == null || !mounted) return;
    final familyId = context.read<AuthController>().familyId;
    if (familyId == null) return;
    try {
      await context.read<CategoriesRepository>().createCustomCategory(
        familyId: familyId,
        name: result.name,
        type: result.type,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final familyId = auth.familyId;
    final repo = context.read<CategoriesRepository>();

    if (familyId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.categoriesTitle)),
        body: Center(child: Text(l10n.familyMissing)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoriesTitle),
        actions: [
          IconButton(
            tooltip: l10n.categoriesShowArchived,
            onPressed: () => setState(() => _showArchived = !_showArchived),
            icon: Icon(
              _showArchived
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createCategory,
        child: const Icon(Icons.add),
      ),
      body: AppPage(
        child: StreamBuilder<List<Category>>(
          stream: repo.watchCategories(
            familyId,
            includeArchived: _showArchived,
          ),
          builder: (context, snap) {
            final error = snap.hasError ? snap.error.toString() : null;
            final categories = snap.data;
            final expense =
                categories
                    ?.where((c) => c.type == CategoryType.expense)
                    .toList() ??
                const [];
            final income =
                categories
                    ?.where((c) => c.type == CategoryType.income)
                    .toList() ??
                const [];

            return LedgerAsyncBody(
              isLoading:
                  snap.connectionState == ConnectionState.waiting &&
                  categories == null,
              errorMessage: error,
              isEmpty: categories != null && categories.isEmpty,
              emptyMessage: l10n.categoriesEmpty,
              child: ListView(
                padding: AppInsets.pageCompact,
                children: [
                  AppSectionTitle(
                    l10n.categoryTypeExpense,
                    padding: AppInsets.sectionTight,
                  ),
                  for (final cat in expense)
                    _CategoryTile(
                      category: cat,
                      onArchive: () => repo.archiveCategory(
                        familyId: familyId,
                        categoryId: cat.id,
                        archived: !cat.archived,
                      ),
                    ),
                  AppSectionTitle(
                    l10n.categoryTypeIncome,
                    padding: AppInsets.sectionTight,
                  ),
                  for (final cat in income)
                    _CategoryTile(
                      category: cat,
                      onArchive: () => repo.archiveCategory(
                        familyId: familyId,
                        categoryId: cat.id,
                        archived: !cat.archived,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onArchive});

  final Category category;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = categoryLabel(l10n, category);

    return ListTile(
      leading: Icon(
        category.isSystem ? Icons.lock_outline : Icons.label_outline,
      ),
      title: Text(label),
      subtitle: Text(
        category.isSystem ? l10n.categorySystemBadge : l10n.categoryCustomBadge,
      ),
      trailing: category.archived
          ? TextButton(onPressed: onArchive, child: Text(l10n.actionUnarchive))
          : IconButton(
              tooltip: l10n.actionArchive,
              onPressed: onArchive,
              icon: const Icon(Icons.archive_outlined),
            ),
    );
  }
}

class _NewCategoryDraft {
  const _NewCategoryDraft({required this.name, required this.type});
  final String name;
  final CategoryType type;
}

class _CreateCategoryDialog extends StatefulWidget {
  const _CreateCategoryDialog();

  @override
  State<_CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<_CreateCategoryDialog> {
  final _name = TextEditingController();
  CategoryType _type = CategoryType.expense;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.categoryCreateTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l10n.categoryName),
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<CategoryType>(
            // ignore: deprecated_member_use
            value: _type,
            decoration: InputDecoration(labelText: l10n.categoryType),
            items: [
              DropdownMenuItem(
                value: CategoryType.expense,
                child: Text(l10n.categoryTypeExpense),
              ),
              DropdownMenuItem(
                value: CategoryType.income,
                child: Text(l10n.categoryTypeIncome),
              ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _type = v);
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.categoryTypeImmutableHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.length < 2) return;
            Navigator.pop(context, _NewCategoryDraft(name: name, type: _type));
          },
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
