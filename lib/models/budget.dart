import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:Groovy/services/auth.dart';
import 'package:firebase_database/firebase_database.dart';

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

  String _userEmail;
  String get userEmail => _userEmail;
  set userEmail(String email) {
    _userEmail = email;
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }
}

@immutable
class Budget {
  final String key;
  final String createdBy;
  final List<dynamic> hiddenFrom;
  final List<dynamic> history;
  final bool isShared;
  final int left;
  final String name;
  final int setAmount;
  final List<dynamic> sharedWith;
  final int spent;
  final List<dynamic> userDate;

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
    this.spent,
    this.userDate,
  });

  Budget.fromSnapshot(DataSnapshot snapshot)
      : key = snapshot.key,
        createdBy = snapshot.value["createdBy"],
        hiddenFrom = snapshot.value["hiddenFrom"],
        history = snapshot.value["history"],
        isShared = snapshot.value["isShared"],
        left = snapshot.value["left"],
        name = snapshot.value["name"],
        setAmount = snapshot.value["setAmount"],
        sharedWith = snapshot.value["sharedWith"],
        spent = snapshot.value["spent"],
        userDate = snapshot.value["userDate"];

  toJson() {
    return {
      "createdBy": createdBy,
      "hiddenFrom": hiddenFrom,
      "history": history,
      "isShared": isShared,
      "left": left,
      "name": name,
      "setAmount": setAmount,
      "sharedWith": sharedWith,
      "spent": spent,
      "userDate": userDate,
    };
  }
}
