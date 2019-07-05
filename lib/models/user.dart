import 'package:firebase_database/firebase_database.dart';

class User {
  String key;
  String name;
  String email;
  List<dynamic> tokenPlatform;
  bool isPaid;

  User({
    this.key,
    this.name,
    this.email,
    this.tokenPlatform,
    this.isPaid,
  });

  User.fromSnapshot(DataSnapshot snapshot)
      : key = snapshot.key,
        name = snapshot.value["name"],
        email = snapshot.value["email"],
        tokenPlatform = snapshot.value["tokenPlatform"],
        isPaid = snapshot.value["isPaid"];

  toJson() {
    return {
      "name": name,
      "email": email,
      "tokenPlatform": tokenPlatform,
      "isPaid": isPaid,
    };
  }

  String toString() {
    return "name: $name, email: $email, tokenPlatform: $tokenPlatform, isPaid: $isPaid";
  }
}
