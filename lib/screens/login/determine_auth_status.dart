import 'package:Groovy/services/budget_service.dart';
import 'package:Groovy/services/user_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:Groovy/screens/login/choose_login.dart';
import 'package:Groovy/screens/home.dart';
import 'package:Groovy/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetermineAuthStatusScreen extends StatefulWidget {
  DetermineAuthStatusScreen({this.auth, this.userService, this.budgetService});

  final BaseAuth auth;
  final UserService userService;
  final BudgetService budgetService;

  @override
  State<StatefulWidget> createState() => _DetermineAuthStatusScreenState();
}

enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
}

class _DetermineAuthStatusScreenState extends State<DetermineAuthStatusScreen> {
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;
  FirebaseUser _user;
  FirebaseDatabase _database = FirebaseDatabase.instance;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  @override
  void initState() {
    super.initState();
    widget.auth.getCurrentUser().then((user) {
      setState(() {
        if (user != null) {
          _user = user;
        }
        authStatus = user?.email == null
            ? AuthStatus.NOT_LOGGED_IN
            : AuthStatus.LOGGED_IN;
      });
    });
  }

  void _onLoggedIn() {
    widget.auth.getCurrentUser().then((user) async {
      setState(() {
        _user = user;
      });
      await _getDatabaseUser(user);
    });
    setState(() {
      authStatus = AuthStatus.LOGGED_IN;
    });
  }

  void _onSignedOut() {
    setState(() {
      authStatus = AuthStatus.NOT_LOGGED_IN;
      _user = null;
    });
  }

  Future<void> _getDatabaseUser(FirebaseUser user) async {
    var retrievedUser =
        await widget.userService.getUserFromEmail(_database, user.email);
    if (retrievedUser.email == null) {
      return await widget.userService
          .createUser(_firebaseMessaging, widget.userService, _database, user);
    } else {
      // Update user's device tokens
      await widget.userService.updateUserDeviceTokens(
          _firebaseMessaging, widget.userService, _database, retrievedUser);
    }
  }

  Widget _buildWaitingScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(Colors.black.withOpacity(0.5))),
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
        return ChooseLoginScreen(
          auth: widget.auth,
          userService: widget.userService,
          budgetService: widget.budgetService,
          onSignedIn: _onLoggedIn,
        );
        break;
      case AuthStatus.LOGGED_IN:
        if (_user != null) {
          return HomeScreen(
            user: _user,
            userService: widget.userService,
            budgetService: widget.budgetService,
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
