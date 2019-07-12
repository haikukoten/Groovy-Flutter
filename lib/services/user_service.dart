import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  Future<void> createUser(FirebaseDatabase database, User user) async {
    return await database.reference().child("users").push().set(user.toJson());
  }

  Future<void> updateUser(FirebaseDatabase database, User user) async {
    print("User ===> ${user.toJson()}");
    return await database
        .reference()
        .child("users")
        .child(user.key)
        .set(user.toJson());
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
}
