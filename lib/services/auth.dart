import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

import '../models/budget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';

// Add Android release keys for Firebase & Facebook
// Test that canceling Google login works in release mode

abstract class BaseAuth {
  Future<void> createBudget(
      FirebaseDatabase database, FirebaseUser user, String name, String amount);

  Future<void> updateBudget(FirebaseDatabase database, Budget budget);

  Future<void> deleteBudget(FirebaseDatabase database, Budget budget);

  Future<FirebaseUser> googleSignIn();

  Future<dynamic> facebookSignIn();

  Future<String> signIn(String email, String password);

  Future<String> signUp(String email, String password, String name);

  Future<FirebaseUser> getFirebaseUserFrom(dynamic authUser);

  Future<FirebaseUser> getCurrentUser();

  Future<void> sendEmailVerification();

  Future<void> sendPasswordRecoveryEmail(String email);

  Future<void> signOut();

  Future<bool> isEmailVerified();
}

class Auth implements BaseAuth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookLogin _facebookLogin = FacebookLogin();

  Future<void> createBudget(FirebaseDatabase database, FirebaseUser user,
      String name, String amount) async {
    if (name.length > 0) {
      // Putting "none" values is not ideal, but unfortunately the old app design was made in such a way that it expects these values.
      // In order for users of the old version of the app to continue without unexpected results, "none" values have been added.
      Budget budget = new Budget(
          createdBy: user.email,
          hiddenFrom: ["none"],
          history: ["none:none"],
          isShared: false,
          left: num.parse(amount),
          name: name,
          setAmount: num.parse(amount),
          sharedWith: ["none"],
          spent: 0,
          userDate: ["none:none"]);
      return await database
          .reference()
          .child("budgets")
          .push()
          .set(budget.toJson());
    }
  }

  Future<void> updateBudget(FirebaseDatabase database, Budget budget) async {
    if (budget != null) {
      return await database
          .reference()
          .child("budgets")
          .child(budget.key)
          .set(budget.toJson());
    }
  }

  Future<void> deleteBudget(FirebaseDatabase database, Budget budget) async {
    return await database
        .reference()
        .child("budgets")
        .child(budget.key)
        .remove();
  }

  Future<FirebaseUser> googleSignIn() async {
    GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    FirebaseUser user = await getFirebaseUserFrom(googleUser);
    if (user.email != null) {
      print("User: $user");
      return user;
    } else {
      return null;
    }
  }

  Future<dynamic> facebookSignIn() async {
    // Let's force the users to login using the login dialog based on WebViews
    _facebookLogin.loginBehavior = FacebookLoginBehavior.webViewOnly;
    FacebookLoginResult _login =
        await _facebookLogin.logInWithReadPermissions(['email']);

    switch (_login.status) {
      case FacebookLoginStatus.loggedIn:
        String token = _login.accessToken.token;
        return await getFirebaseUserFrom(token);
        break;
      case FacebookLoginStatus.cancelledByUser:
        return null;
        break;
      case FacebookLoginStatus.error:
        return _login.errorMessage;
        break;
    }
  }

  Future<String> signIn(String email, String password) async {
    FirebaseUser user = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    return user.uid;
  }

  Future<String> signUp(String email, String password, String name) async {
    FirebaseUser user = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    UserUpdateInfo updateUser = UserUpdateInfo();
    updateUser.displayName = "$name";
    user.updateProfile(updateUser);
    return user.uid;
  }

  Future<FirebaseUser> getFirebaseUserFrom(dynamic auth) async {
    AuthCredential credential;
    if (auth.runtimeType == GoogleSignInAccount) {
      final GoogleSignInAuthentication googleAuth = await auth.authentication;
      credential = GoogleAuthProvider.getCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
    } else {
      credential = FacebookAuthProvider.getCredential(accessToken: auth);
    }

    final FirebaseUser user =
        await _firebaseAuth.signInWithCredential(credential);

    return user;
  }

  Future<FirebaseUser> getCurrentUser() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    return user;
  }

  Future<void> sendEmailVerification() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    user.sendEmailVerification();
  }

  Future<void> sendPasswordRecoveryEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }

    if (await _facebookLogin.isLoggedIn) {
      await _facebookLogin.logOut();
    }
    return _firebaseAuth.signOut();
  }

  Future<bool> isEmailVerified() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    return user.isEmailVerified;
  }
}
