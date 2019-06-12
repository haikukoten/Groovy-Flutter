import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Add Android release keys for Firebase & Facebook
// Test that canceling Google login works in release mode

abstract class BaseAuth {
  Future<GoogleSignInAccount> googleSignIn();

  Future<dynamic> facebookSignIn();

  Future<String> signIn(String email, String password);

  Future<String> signUp(String email, String password);

  Future<GoogleSignInAccount> getGoogleUser();

  Future<dynamic> getFacebookUser(String token);

  Future<FirebaseUser> getCurrentUser();

  Future<void> sendEmailVerification();

  Future<void> sendPasswordRecoveryEmail(String email);

  Future<void> signOut();

  Future<void> googleSignOut();

  Future<void> facebookSignOut();

  Future<bool> isEmailVerified();

  Future<dynamic> isGoogleUserSignedIn();

  Future<bool> isFacebookUserSignedIn();
}

class Auth implements BaseAuth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookLogin _facebookLogin = FacebookLogin();
  // Create secure storage for Facebook token
  final storage = new FlutterSecureStorage();

  Future<GoogleSignInAccount> googleSignIn() async {
    GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    if (googleUser.id != null) {
      return googleUser;
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
        await storage.write(key: "fbToken", value: token);
        return await getFacebookUser(token);
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

  Future<String> signUp(String email, String password) async {
    FirebaseUser user = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    return user.uid;
  }

  Future<GoogleSignInAccount> getGoogleUser() async {
    GoogleSignInAccount googleUser = await _googleSignIn.signInSilently();
    return googleUser;
  }

  Future<dynamic> getFacebookUser(String token) async {
    final graphResponse = await http.get(
        'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email&access_token=$token');
    final profile = json.decode(graphResponse.body);
    if (profile["email"] != null) {
      return profile;
    } else {
      return null;
    }
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

  Future<void> googleSignOut() async {
    return _googleSignIn.signOut();
  }

  Future<void> facebookSignOut() async {
    return _facebookLogin.logOut();
  }

  Future<void> signOut() async {
    if (await isGoogleUserSignedIn()) {
      return googleSignOut();
    } else if (await isFacebookUserSignedIn()) {
      await storage.delete(key: "fbToken");
      return facebookSignOut();
    } else {
      return _firebaseAuth.signOut();
    }
  }

  Future<bool> isEmailVerified() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    return user.isEmailVerified;
  }

  Future<bool> isGoogleUserSignedIn() async {
    bool isSignedIn = await _googleSignIn.isSignedIn();
    return isSignedIn;
  }

  Future<bool> isFacebookUserSignedIn() async {
    bool isSignedIn = await _facebookLogin.isLoggedIn;
    return isSignedIn;
  }
}
