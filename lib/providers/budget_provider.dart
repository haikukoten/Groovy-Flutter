import 'package:flutter/foundation.dart';
import '../models/budget.dart';

class BudgetProvider extends ChangeNotifier {
  Budget _selectedBudget;
  Budget get selectedBudget => _selectedBudget;
  set selectedBudget(Budget budget) {
    _selectedBudget = budget;
    notifyListeners();
  }
}
