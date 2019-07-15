import 'package:Groovy/providers/user_provider.dart';
import 'package:Groovy/services/budget_service.dart';
import 'package:Groovy/services/user_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:Groovy/screens/login/choose_login.dart';
import 'package:Groovy/services/auth_service.dart';
import 'package:Groovy/screens/budget_list/budget_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class DetermineAuthStatusScreen extends StatefulWidget {
  DetermineAuthStatusScreen({this.auth, this.userService, this.budgetService});

  final BaseAuth auth;
  final UserService userService;
  final BudgetService budgetService;

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
    widget.auth.getCurrentUser().then((user) {
      setState(() {
        _user = user;
        // User on opening app is overriding any budgets that get shared with them while the app is terminated
        _initDatabaseUser(user);
      });
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

  void _initDatabaseUser(FirebaseUser user) async {
    var userProvider = Provider.of<UserProvider>(context);
    widget.userService
        .getUserFromEmail(_database, user.email)
        .then((retrievedUser) {
      if (retrievedUser.email == null) {
        widget.userService
            .createUser(_firebaseMessaging, widget.userService, _database, user)
            .then((createdUser) {
          userProvider.currentUser = createdUser;
        });
      } else {
        userProvider.currentUser = retrievedUser;
        widget.userService.updateUserDeviceTokens(
            _firebaseMessaging, widget.userService, _database, retrievedUser);
      }
    });
  }

  Widget _buildWaitingScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: CircularProgressIndicator(
            valueColor: new AlwaysStoppedAnimation<Color>(
                Colors.black.withOpacity(0.5))),
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
          userService: widget.userService,
          budgetService: widget.budgetService,
          onSignedIn: _onLoggedIn,
        );
        break;
      case AuthStatus.LOGGED_IN:
        if (_user != null) {
          return new BudgetListScreen(
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
