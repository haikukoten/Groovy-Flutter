import 'package:flutter/foundation.dart';
import '../models/budget.dart';

class BudgetProvider extends ChangeNotifier {
  List<Budget> _budgetList = [];
  List<Budget> get budgetList => _budgetList;
  set budgetList(List<Budget> budgetList) {
    _budgetList = budgetList;
    notifyListeners();
  }

  Budget _selectedBudget;
  Budget get selectedBudget => _selectedBudget;
  set selectedBudget(Budget budget) {
    _selectedBudget = budget;
    notifyListeners();
  }
}
