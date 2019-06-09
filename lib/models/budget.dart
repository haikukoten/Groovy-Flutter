import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:groovy/services/auth.dart';

class BudgetModel extends ChangeNotifier {
  /// Internal, private state of user's budgets.
  final List<Budget> _budgets = [];

  /// An unmodifiable view of the user's budgets
  UnmodifiableListView<Budget> get budgets => UnmodifiableListView(_budgets);

  /// Adds [budget] to budgets. This is the only way to modify the user's budgets from outside.
  void add(Budget budget) {
    _budgets.add(budget);

    // This line tells [Model] that it should rebuild the widgets that
    // depend on it.
    notifyListeners();
  }

  // EmailLogin requires these
  // ChooseLogin will set them
  BaseAuth _auth;
  BaseAuth get auth => _auth;
  set auth(BaseAuth auth) {
    _auth = auth;
    notifyListeners();
  }

  VoidCallback _onSignedIn;
  VoidCallback get onSignedIn => _onSignedIn;
  set onSignedIn(VoidCallback onSignedIn) {
    _onSignedIn = onSignedIn;
    notifyListeners();
  }
}

@immutable
class Budget {
  final int key;
  final String createdBy;
  final List<String> hiddenFrom;
  final List<String> history;
  final bool isShared;
  final double left;
  final String name;
  final double setAmount;
  final List<String> sharedWith;
  final List<String> userDate;

  Budget({
    this.key,
    this.createdBy,
    this.hiddenFrom,
    this.history,
    this.isShared,
    this.left,
    this.name,
    this.setAmount,
    this.sharedWith,
    this.userDate,
  });
}
