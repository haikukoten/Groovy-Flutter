import 'budget.dart';
import 'package:Groovy/models/not_accepted_budget.dart';
import 'package:Groovy/models/transaction.dart';
import 'package:firebase_database/firebase_database.dart';

class User {
  String key;
  String name;
  String email;
  List<dynamic> deviceTokens;
  bool isPaid;
  List<Budget> budgets;
  List<NotAcceptedBudget> notAcceptedBudgets;
  List<Transaction> transactions;

  User(
      {this.key,
      this.name,
      this.email,
      this.deviceTokens,
      this.isPaid,
      this.budgets,
      this.notAcceptedBudgets,
      this.transactions});

  User.fromSnapshot(DataSnapshot snapshot) {
    key = snapshot.key;
    name = snapshot.value["name"];
    email = snapshot.value["email"];
    deviceTokens = snapshot.value["deviceTokens"];
    isPaid = snapshot.value["isPaid"];

    if (snapshot.value["budgets"] != null) {
      List<Budget> userBudgets = [];
      Map budgetObjects = snapshot.value["budgets"];
      budgetObjects.forEach((key, budget) {
        Map budgetMap = budget;
        budgetMap["key"] = key;
        userBudgets.add(Budget.fromMap(budgetMap));
      });

      budgets = userBudgets;
    }

    if (snapshot.value["notAcceptedBudgets"] != null) {
      List<NotAcceptedBudget> userNotAcceptedBudgets = [];
      Map notAcceptedBudgetObjects = snapshot.value["notAcceptedBudgets"];
      notAcceptedBudgetObjects.forEach((key, budget) {
        Map notAcceptedBudgetMap = budget;
        notAcceptedBudgetMap["key"] = key;
        userNotAcceptedBudgets
            .add(NotAcceptedBudget.fromMap(notAcceptedBudgetMap));
      });

      notAcceptedBudgets = userNotAcceptedBudgets;
    }

    if (snapshot.value["transactions"] != null) {
      List<dynamic> userTransactions = [];
      (snapshot.value["transactions"] as Map).forEach((key, map) {
        Map transactionMap = map;
        transactionMap["key"] = key;
        userTransactions.add(Transaction.fromMap(transactionMap));
      });
      transactions = userTransactions;
    }
  }

  User.fromMap(Map map) {
    key = map["key"];
    name = map["name"];
    email = map["email"];
    deviceTokens = map["deviceTokens"];
    isPaid = map["isPaid"];

    if (map["budgets"] != null) {
      List<Budget> userBudgets = [];
      Map budgetObjects = map["budgets"];
      budgetObjects.forEach((key, budget) {
        Map budgetMap = budget;
        budgetMap["key"] = key;
        userBudgets.add(Budget.fromMap(budgetMap));
      });

      budgets = userBudgets;
    }

    if (map["notAcceptedBudgets"] != null) {
      List<NotAcceptedBudget> userNotAcceptedBudgets = [];
      Map notAcceptedBudgetObjects = map["notAcceptedBudgets"];
      notAcceptedBudgetObjects.forEach((key, budget) {
        Map notAcceptedBudgetMap = budget;
        notAcceptedBudgetMap["key"] = key;
        userNotAcceptedBudgets
            .add(NotAcceptedBudget.fromMap(notAcceptedBudgetMap));
      });

      notAcceptedBudgets = userNotAcceptedBudgets;
    }

    if (map["transactions"] != null) {
      List<dynamic> userTransactions = [];
      Map transactionObjects = map["transactions"];
      transactionObjects.forEach((key, transaction) {
        Map transactionMap = transaction;
        transactionMap["key"] = key;
        userTransactions.add(Transaction.fromMap(transactionMap));
      });
      transactions = userTransactions;
    }
  }

  toJson() {
    var budgetsObject = {};
    if (budgets != null) {
      budgets.forEach((budget) {
        var budgetAsJSON = budget.toJson();
        budgetsObject[budget.key] = budgetAsJSON;
      });
    }

    var notAcceptedBudgetsObject = {};
    if (notAcceptedBudgets != null) {
      notAcceptedBudgets.forEach((budget) {
        var budgetAsJSON = budget.toJson();
        notAcceptedBudgetsObject[budget.key] = budgetAsJSON;
      });
    }

    return {
      "name": name,
      "email": email,
      "deviceTokens": deviceTokens,
      "isPaid": isPaid,
      "budgets": budgetsObject,
      "notAcceptedBudgets": notAcceptedBudgetsObject,
      "transactions": transactions
    };
  }

  String toString() {
    return "key: $key, name: $name, email: $email, deviceTokens: $deviceTokens, isPaid: $isPaid, budgets: $budgets, notAcceptedBudgets: $notAcceptedBudgets, transactions: $transactions";
  }
}
