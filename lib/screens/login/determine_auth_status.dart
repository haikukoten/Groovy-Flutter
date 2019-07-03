import 'package:Groovy/models/user.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:Groovy/screens/login/choose_login.dart';
import 'package:Groovy/services/auth.dart';
import 'package:Groovy/screens/budget_list/budget_list.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

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
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  FirebaseUser _user;

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
      });
    });
    setState(() {
      authStatus = AuthStatus.LOGGED_IN;
    });

    _performAnyUpdatesToCurrentUserOnFirebase();
  }

  void _onSignedOut() {
    setState(() {
      authStatus = AuthStatus.NOT_LOGGED_IN;
      _user = null;
    });
  }

  _performAnyUpdatesToCurrentUserOnFirebase() async {
    var token = await _firebaseMessaging.getToken();
    await widget.auth.getCurrentUser().then((loggedInUser) async {
      User user;
      await _database
          .reference()
          .child("users")
          .orderByChild("email")
          .equalTo(loggedInUser.email)
          .once()
          .then((DataSnapshot snapshot) async {
        if (snapshot.value != null) {
          for (var value in (snapshot.value as Map).values) {
            user = User();
            user.email = value["email"];
            user.name = value["name"];
            user.isPaid = value["isPaid"];
            user.token = value["token"];
          }
        }

        // User exists, update if token is updated
        if (user != null) {
          if (user.token != token) {
            user.token = token;
            print(user.email);
            await widget.auth.updateUser(_database, user);
          }

          // User doesn't exist, create user
        } else {
          print(loggedInUser.displayName);
          print(loggedInUser.email);
          await widget.auth.createUser(
              _database,
              User(
                  email: loggedInUser.email,
                  name: loggedInUser.displayName,
                  isPaid: false,
                  token: token));
        }
      });
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
          onSignedIn: _onLoggedIn,
        );
        break;
      case AuthStatus.LOGGED_IN:
        if (_user != null) {
          return new BudgetListScreen(
            user: _user,
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
