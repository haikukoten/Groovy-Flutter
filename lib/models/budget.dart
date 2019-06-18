import 'package:flutter/foundation.dart';
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
}

@immutable
class Budget {
  String key;
  String createdBy;
  List<dynamic> hiddenFrom;
  List<dynamic> history;
  bool isShared;
  num left;
  String name;
  num setAmount;
  List<dynamic> sharedWith;
  num spent;
  List<dynamic> userDate;

  Budget({
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
