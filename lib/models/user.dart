import 'package:Groovy/models/transaction.dart';
import 'package:firebase_database/firebase_database.dart';
import 'budget.dart';

class User {
  String key;
  String name;
  String email;
  List<dynamic> deviceTokens;
  bool isPaid;
  List<dynamic> budgets;
  List<dynamic> transactions;

  User(
      {this.key,
      this.name,
      this.email,
      this.deviceTokens,
      this.isPaid,
      this.budgets,
      this.transactions});

  User.fromSnapshot(DataSnapshot snapshot) {
    key = snapshot.key;
    name = snapshot.value["name"];
    email = snapshot.value["email"];
    deviceTokens = snapshot.value["deviceTokens"];
    isPaid = snapshot.value["isPaid"];

    if (snapshot.value["budgets"] != null) {
      List<Budget> userBudgets = [];
      (snapshot.value["budgets"] as Map).forEach((key, map) {
        Map budgetMap = map;
        budgetMap["key"] = key;
        userBudgets.add(Budget.fromMap(budgetMap));
      });
      budgets = userBudgets;
    }

    if (snapshot.value["transactions"] != null) {
      List<Transaction> userTransactions = [];
      (snapshot.value["transactions"] as Map).forEach((key, map) {
        Map transactionMap = map;
        transactionMap["key"] = key;
        userTransactions.add(Transaction.fromMap(transactionMap));
      });
      transactions = userTransactions;
    }
  }

  toJson() {
    return {
      "name": name,
      "email": email,
      "deviceTokens": deviceTokens,
      "isPaid": isPaid,
      "budgets": budgets,
      "transactions": transactions
    };
  }

  String toString() {
    return "key: $key, name: $name, email: $email, deviceTokens: $deviceTokens, isPaid: $isPaid, budgets: $budgets, transactions: $transactions";
  }
}
