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

    List<String> tokenPlatform = [];
    tokenPlatform.add("$token&&platform===>$platform");
    auth.createUser(
        database,
        User(
            email: user.email,
            name: user.displayName,
            isPaid: false,
            tokenPlatform: tokenPlatform));
  }
}
