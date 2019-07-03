import 'package:firebase_database/firebase_database.dart';

class User {
  String key;
  String name;
  String email;
  String token;
  bool isPaid;

  User({
    this.key,
    this.name,
    this.email,
    this.token,
    this.isPaid,
  });

  User.fromSnapshot(DataSnapshot snapshot, String key)
      : key = key,
        name = snapshot.value["name"],
        email = snapshot.value["email"],
        token = snapshot.value["token"],
        isPaid = snapshot.value["isPaid"];

  toJson() {
    return {
      "name": name,
      "email": email,
      "token": token,
      "isPaid": isPaid,
    };
  }
}
