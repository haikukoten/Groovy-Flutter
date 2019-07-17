import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/budget.dart';
import '../models/user.dart';

class BudgetService {
  Future<void> createBudget(
      FirebaseDatabase database, User user, String name, String amount) async {
    if (name.length > 0) {
      // TODO: Create 'transfer budgets' function from old version of app to new version
      // so users can get their old budgets on the new app architecture
      Budget budget = new Budget(
          createdBy: user.email,
          hiddenFrom: [],
          history: [],
          isShared: false,
          left: num.parse(amount),
          name: name,
          setAmount: num.parse(amount),
          sharedWith: [user.email],
          spent: 0,
          userDate: []);
      return await database
          .reference()
          .child("users")
          .child(user.key)
          .child("budgets")
          .push()
          .set(budget.toJson());
    }
  }

  // Checks if budget exists in the user's budgets or notAcceptedBudgets and update it accordingly
  Future<void> updateBudget(
      FirebaseDatabase database, User user, Budget budget) async {
    if (budget != null) {
      // Update user's budget list if budget exists
      if (user.budgets != null) {
        user.budgets.forEach((userBudget) async {
          if (userBudget.key == budget.key) {
            return await database
                .reference()
                .child("users")
                .child(user.key)
                .child("budgets")
                .child(budget.key)
                .set(budget.toJson());
          }
        });
      }

      // Update user's not accepted budget list if budget exists
      if (user.notAcceptedBudgets != null) {
        user.notAcceptedBudgets.forEach((notAcceptedBudget) async {
          if (notAcceptedBudget.key == budget.key) {
            return await database
                .reference()
                .child("users")
                .child(user.key)
                .child("notAcceptedBudgets")
                .child(budget.key)
                .set(budget.toJson());
          }
        });
      }
    }
  }

  Future<void> deleteBudget(
      FirebaseDatabase database, User user, Budget budget) async {
    return await database
        .reference()
        .child("users")
        .child(user.key)
        .child("budgets")
        .child(budget.key)
        .remove();
  }

  Future<void> shareBudget(
      FirebaseDatabase database, User user, Budget budget) async {
    return await database
        .reference()
        .child("users")
        .child(user.key)
        .child("notAcceptedBudgets")
        .child(budget.key)
        .set(budget.toJson());
  }

  // Checks if budget exists in the user's budgets or notAcceptedBudgets and remove it accordingly
  Future<void> removeSharedBudget(
      FirebaseDatabase database, User user, Budget budget) async {
    if (budget != null) {
      // Update user's budget list if budget exists
      if (user.budgets != null) {
        user.budgets.forEach((userBudget) async {
          if (userBudget.key == budget.key) {
            return await database
                .reference()
                .child("users")
                .child(user.key)
                .child("budgets")
                .child(budget.key)
                .remove();
          }
        });
      }

      // Update user's not accepted budget list if budget exists
      if (user.notAcceptedBudgets != null) {
        user.notAcceptedBudgets.forEach((notAcceptedBudget) async {
          if (notAcceptedBudget.key == budget.key) {
            return await database
                .reference()
                .child("users")
                .child(user.key)
                .child("notAcceptedBudgets")
                .child(budget.key)
                .remove();
          }
        });
      }
    }
  }
}
