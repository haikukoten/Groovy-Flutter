import 'package:flutter/material.dart';
import 'package:groovy/screens/choose_login.dart';
import 'package:groovy/services/auth.dart';
import 'package:groovy/screens/budget_list.dart';

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

  @override
  void initState() {
    super.initState();
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
