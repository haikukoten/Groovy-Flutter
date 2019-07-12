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

  List<Budget> _notAcceptedSharedBudgets = [];
  List<Budget> get notAcceptedSharedBudgets => _notAcceptedSharedBudgets;
  set notAcceptedSharedBudgets(List<Budget> notAcceptedSharedBudgets) {
    _notAcceptedSharedBudgets = notAcceptedSharedBudgets;
    notifyListeners();
  }

  removeNotAcceptedBudget(Budget budget) {
    notAcceptedSharedBudgets.removeWhere(
        (notAcceptedBudget) => notAcceptedBudget.key == budget.key);
  }

  toJSONEncodable(List<Budget> list) {
    return list.map((Budget budget) {
      return budget.toJson();
    }).toList();
  }

  Budget _selectedBudget;
  Budget get selectedBudget => _selectedBudget;
  set selectedBudget(Budget budget) {
    _selectedBudget = budget;
    notifyListeners();
  }
}
