import 'package:flutter/material.dart';
import 'package:Groovy/screens/choose_login.dart';
import 'package:Groovy/services/auth.dart';
import 'package:Groovy/screens/budget_list.dart';
import 'package:provider/provider.dart';
import 'package:Groovy/models/budget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DetermineAuthStatusScreen extends StatefulWidget {
  DetermineAuthStatusScreen({this.auth});

  final BaseAuth auth;

  @override
  State<StatefulWidget> createState() => new _DetermineAuthStatusScreenState();
}

enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
}

class _DetermineAuthStatusScreenState extends State<DetermineAuthStatusScreen> {
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;
  String _userEmail = "";
  // Create secure storage for Facebook token
  final storage = new FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loginCurrentUser();
  }

  void _loginCurrentUser() async {
    // Check if user is signed in with Google
    if (await widget.auth.isGoogleUserSignedIn()) {
      widget.auth.getGoogleUser().then((googleUser) {
        setState(() {
          if (googleUser != null) {
            _userEmail = googleUser.email;
          }
          authStatus = googleUser?.email == null
              ? AuthStatus.NOT_LOGGED_IN
              : AuthStatus.LOGGED_IN;
        });
      });
    }
    // Check if user is signed in with Facebook
    else if (await widget.auth.isFacebookUserSignedIn()) {
      String token = await storage.read(key: "fbToken");
      if (token != null) {
        widget.auth.getFacebookUser(token).then((facebookUser) {
          setState(() {
            if (facebookUser != null && facebookUser["email"] != null) {
              _userEmail = facebookUser["email"];
            }
            authStatus = facebookUser["email"] == null
                ? AuthStatus.NOT_LOGGED_IN
                : AuthStatus.LOGGED_IN;
          });
        });
      }
    }

    // Check if user is signed in with email
    else if (await widget.auth.getCurrentUser() != null) {
      widget.auth.getCurrentUser().then((user) {
        setState(() {
          if (user != null) {
            _userEmail = user?.email;
          }
          authStatus = user?.email == null
              ? AuthStatus.NOT_LOGGED_IN
              : AuthStatus.LOGGED_IN;
        });
      });
    }
    // User not logged in
    else {
      setState(() {
        authStatus = AuthStatus.NOT_LOGGED_IN;
      });
    }
  }

  void _onLoggedIn() {
    widget.auth.getCurrentUser().then((user) {
      setState(() {
        _userEmail = user.email;
      });
    });
    setState(() {
      authStatus = AuthStatus.LOGGED_IN;
    });
  }

  void _onSocialLogin() {
    var budgetModel = Provider.of<BudgetModel>(context);
    setState(() {
      _userEmail = budgetModel.userEmail;
      authStatus = AuthStatus.LOGGED_IN;
      print(_userEmail);
    });
  }

  void _onSignedOut() {
    setState(() {
      authStatus = AuthStatus.NOT_LOGGED_IN;
      _userEmail = "";
    });
  }

  Widget _buildWaitingScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (authStatus) {
      case AuthStatus.NOT_DETERMINED:
        return _buildWaitingScreen();
        break;
      case AuthStatus.NOT_LOGGED_IN:
        return new ChooseLoginScreen(
          auth: widget.auth,
          onSignedIn: _onLoggedIn,
          onSocialSignIn: _onSocialLogin,
        );
        break;
      case AuthStatus.LOGGED_IN:
        if (_userEmail.length > 0 && _userEmail != null) {
          return new BudgetListScreen(
            userEmail: _userEmail,
            auth: widget.auth,
            onSignedOut: _onSignedOut,
          );
        } else
          return _buildWaitingScreen();
        break;
      default:
        return _buildWaitingScreen();
    }
  }
}
