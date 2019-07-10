import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/budget.dart';
import '../models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';

// TODO: Add Android release keys for Firebase & Facebook
// Test that canceling Google login works in release mode

abstract class BaseAuth {
  Future<void> createBudget(
      FirebaseDatabase database, User user, String name, String amount);

  Future<void> updateBudget(
      FirebaseDatabase database, User user, Budget budget);

  Future<void> deleteBudget(
      FirebaseDatabase database, User user, Budget budget);

  Future<void> createUser(FirebaseDatabase database, User user);

  Future<void> updateUser(
      FirebaseDatabase database, FirebaseUser firebaseUser, User user);

  Future<void> deleteUser(
      FirebaseDatabase database, FirebaseUser firebaseUser, User user);

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

  Future<void> updateBudget(
      FirebaseDatabase database, User user, Budget budget) async {
    if (budget != null) {
      return await database
          .reference()
          .child("users")
          .child(user.key)
          .child("budgets")
          .child(budget.key)
          .set(budget.toJson());
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

  Future<void> createUser(FirebaseDatabase database, User user) async {
    return await database.reference().child("users").push().set(user.toJson());
  }

  Future<void> updateUser(
      FirebaseDatabase database, FirebaseUser firebaseUser, User user) async {
    return await database
        .reference()
        .child("users")
        .child(firebaseUser.uid)
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
    return await _firebaseAuth.signOut();
  }

  Future<bool> isEmailVerified() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    return user.isEmailVerified;
  }
}
