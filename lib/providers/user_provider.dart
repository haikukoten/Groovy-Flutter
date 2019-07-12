import 'package:Groovy/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  UserService _userService;
  UserService get userService => _userService;
  set userService(UserService userService) {
    _userService = userService;
    notifyListeners();
  }

  User _currentUser;
  User get currentUser => _currentUser;
  set currentUser(User currentUser) {
    _currentUser = currentUser;
    notifyListeners();
  }

  createUser(FirebaseMessaging firebaseMessaging, UserService userService,
      FirebaseDatabase database, FirebaseUser user) async {
    var token = await firebaseMessaging.getToken();

    List<String> deviceTokens = [];
    deviceTokens.add(token);
    userService.createUser(
        database,
        User(
            email: user.email,
            name: user.displayName,
            isPaid: false,
            deviceTokens: deviceTokens));
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
    userService.updateUser(database, user);
  }

  Future<void> removeUserDeviceToken(FirebaseMessaging firebaseMessaging,
      UserService userService, FirebaseDatabase database, User user) async {
    var token = await firebaseMessaging.getToken();
    var deviceTokens = [];
    user.deviceTokens.forEach((token) => deviceTokens.add(token));

    // If user contains current device token, remove it
    if (deviceTokens.contains(token)) {
      deviceTokens.remove(token);
    }

    user.deviceTokens = deviceTokens;
    userService.updateUser(database, user);
  }
}
