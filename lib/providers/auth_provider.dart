import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Groovy/services/auth.dart';

class AuthProvider extends ChangeNotifier {
  // EmailLogin and BudgetDetail requires these
  // ChooseLogin will set them
  BaseAuth _auth;
  BaseAuth get auth => _auth;
  set auth(BaseAuth auth) {
    _auth = auth;
    notifyListeners();
  }

  VoidCallback _onSignedIn;
  VoidCallback get onSignedIn => _onSignedIn;
  set onSignedIn(VoidCallback onSignedIn) {
    _onSignedIn = onSignedIn;
    notifyListeners();
  }

  FirebaseUser _firebaseUser;
  FirebaseUser get firebaseUser => _firebaseUser;
  set firebaseUser(FirebaseUser firebaseUser) {
    _firebaseUser = firebaseUser;
    notifyListeners();
  }
}
