import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:Groovy/services/auth.dart';
import 'package:firebase_database/firebase_database.dart';

class BudgetModel extends ChangeNotifier {
  List<Budget> _budgets = [];

  List<Budget> get budgets => _budgets;

  set budgets(List<Budget> budgets) {
    _budgets = budgets;
    notifyListeners();
  }

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
  final num left;
  final String name;
  final num setAmount;
  final List<dynamic> sharedWith;
  final num spent;
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
