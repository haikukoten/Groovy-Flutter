import 'package:Groovy/services/budget_service.dart';
import 'package:flutter/foundation.dart';
import '../models/budget.dart';

class BudgetProvider extends ChangeNotifier {
  BudgetService _budgetService;
  BudgetService get budgetService => _budgetService;
  set budgetService(BudgetService budgetService) {
    _budgetService = budgetService;
    notifyListeners();
  }

  Budget _selectedBudget;
  Budget get selectedBudget => _selectedBudget;
  set selectedBudget(Budget budget) {
    _selectedBudget = budget;
    notifyListeners();
  }
}
