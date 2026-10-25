import 'package:flutter/material.dart';

import '../../budgets/presentation/budget_goals_screen.dart';

/// Legacy entry — Goals live in [BudgetGoalsScreen] tab (Stitch Fase 3c).
///
/// Shell uses `/budgets?tab=goals`; editor routes stay separate.
class GoalsListScreen extends StatelessWidget {
  const GoalsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BudgetGoalsScreen(initialShowGoals: true);
  }
}
