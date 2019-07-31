import 'dart:async';
import 'package:Groovy/models/budget.dart';
import 'package:Groovy/providers/budget_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  Future<void> createUser(
      FirebaseMessaging firebaseMessaging,
      UserService userService,
      FirebaseDatabase database,
      FirebaseUser firebaseUser) async {
    var token = await firebaseMessaging.getToken();

    List<String> deviceTokens = [];
    deviceTokens.add(token);

    User user = User(
        email: firebaseUser.email,
        name: firebaseUser.displayName,
        isPaid: false,
        deviceTokens: deviceTokens);
    return await database.reference().child("users").push().set(user.toJson());
  }

  updateUser(FirebaseDatabase database, User user) async {
    return await database
        .reference()
        .child("users")
        .orderByChild("email")
        .equalTo(user.email)
        .once()
        .then((snapshot) {
      var key = (snapshot.value as Map).keys.first;
      database.reference().child("users").child(key).set(user.toJson());
    });
  }

  // for users in sharedWith, update the users with budget
  Future<void> updateSharedUsers(FirebaseDatabase database, Budget budget,
      BudgetProvider budgetProvider) async {
    List<String> emailsToBeUpdated = [];
    budget.sharedWith.forEach((email) {
      emailsToBeUpdated.add(email);
    });
    // get users from list of emails to be updated
    if (emailsToBeUpdated.isNotEmpty) {
      emailsToBeUpdated.forEach((email) async {
        User user = await getUserFromEmail(database, email);
        // update user with budget
        await budgetProvider.budgetService.updateBudget(database, user, budget);
      });
    }
  }

  Future<void> deleteUser(
      FirebaseDatabase database, FirebaseUser firebaseUser, User user) async {
    return await database
        .reference()
        .child("users")
        .child(firebaseUser.uid)
        .remove();
  }

  Future<User> getUserFromEmail(FirebaseDatabase database, String email) async {
    print(email);
    return await database
        .reference()
        .child("users")
        .orderByChild('email')
        .equalTo(email)
        .once()
        .then((DataSnapshot snapshot) {
      Map userMap = {};
      if (snapshot.value != null) {
        userMap = (snapshot.value as Map).values.first;
        userMap["key"] = (snapshot.value as Map).keys.first;
      }
      return userMap == {} ? User() : User.fromMap(userMap);
    });
  }

  Future<void> updateUserDeviceTokens(FirebaseMessaging firebaseMessaging,
      UserService userService, FirebaseDatabase database, User user) async {
    var token = await firebaseMessaging.getToken();
    var deviceTokens = [];

    // IF user has no device tokens, add current
    if (user.deviceTokens == null) {
      deviceTokens.add(token);
      // If user already has device tokens, but not current, add current
    } else {
      user.deviceTokens.forEach((token) => deviceTokens.add(token));
      if (!deviceTokens.contains(token)) {
        deviceTokens.add(token);
      }
    }

    user.deviceTokens = deviceTokens;
    return userService.updateUser(database, user);
  }

  Future<void> removeUserDeviceToken(FirebaseMessaging firebaseMessaging,
      UserService userService, FirebaseDatabase database, User user) async {
    var token = await firebaseMessaging.getToken();
    var deviceTokens = [];
    if (user != null) {
      user.deviceTokens.forEach((token) => deviceTokens.add(token));

      // If user contains current device token, remove it
      if (deviceTokens.contains(token)) {
        deviceTokens.remove(token);
      }

      user.deviceTokens = deviceTokens;
      userService.updateUser(database, user);
    }
  }
}
