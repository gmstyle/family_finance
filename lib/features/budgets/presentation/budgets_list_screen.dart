import 'package:flutter/material.dart';

import 'budget_goals_screen.dart';

/// Legacy entry — Budget & Goals live in [BudgetGoalsScreen] (Stitch Fase 3c).
///
/// Kept so existing imports/tests resolve; shell routes `/budgets` only.
class BudgetsListScreen extends StatelessWidget {
  const BudgetsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BudgetGoalsScreen();
  }
}
