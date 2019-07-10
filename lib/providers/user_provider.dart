import 'dart:io';
import 'package:Groovy/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  User _currentUser;
  User get currentUser => _currentUser;
  set currentUser(User currentUser) {
    _currentUser = currentUser;
    notifyListeners();
  }

  List<User> _userList = [];
  List<User> get userList => _userList;
  set userList(List<User> userList) {
    _userList = userList;
    notifyListeners();
  }

  createUser(FirebaseMessaging firebaseMessaging, BaseAuth auth,
      FirebaseDatabase database, FirebaseUser user) async {
    var token = await firebaseMessaging.getToken();
    var platform = Platform.isAndroid ? "android" : "iOS";

    List<String> deviceTokens = [];
    deviceTokens.add("$token&&platform===>$platform");
    auth.createUser(
        database,
        User(
            email: user.email,
            name: user.displayName,
            isPaid: false,
            deviceTokens: deviceTokens));
  }

  Future<void> updateUserDeviceTokens(FirebaseMessaging firebaseMessaging,
      BaseAuth auth, FirebaseDatabase database, User user) async {
    var token = await firebaseMessaging.getToken();
    var platform = Platform.isAndroid ? "android" : "iOS";
    var deviceToken = "$token&&platform===>$platform";
    var deviceTokens = [];

    // IF user has no device tokens, add current
    if (user.deviceTokens == null) {
      deviceTokens.add(deviceToken);
      // If user already has device tokens, but not current, add current
    } else {
      user.deviceTokens.forEach((token) => deviceTokens.add(token));
      if (!deviceTokens.contains(deviceToken)) {
        deviceTokens.add(deviceToken);
      }
    }

    user.deviceTokens = deviceTokens;
    auth.updateUser(database, user);
  }

  Future<void> removeUserDeviceToken(FirebaseMessaging firebaseMessaging,
      BaseAuth auth, FirebaseDatabase database, User user) async {
    var token = await firebaseMessaging.getToken();
    var platform = Platform.isAndroid ? "android" : "iOS";
    var deviceToken = "$token&&platform===>$platform";
    var deviceTokens = [];
    user.deviceTokens.forEach((token) => deviceTokens.add(token));

    // If user contains current device token, remove it
    if (deviceTokens.contains(deviceToken)) {
      deviceTokens.remove(deviceToken);
    }

    user.deviceTokens = deviceTokens;
    auth.updateUser(database, user);
  }
}
