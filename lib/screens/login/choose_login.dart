import 'dart:ui';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:Groovy/providers/auth_provider.dart';
import 'package:Groovy/providers/ui_provider.dart';
import 'package:Groovy/services/budget_service.dart';
import 'package:Groovy/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Groovy/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../shared/utilities.dart';
import '../shared/animated/background.dart';
import '../shared/animated/wave.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ChooseLoginScreen extends StatefulWidget {
  ChooseLoginScreen(
      {Key key,
      this.auth,
      this.userService,
      this.budgetService,
      this.onSignedIn})
      : super(key: key);

  final BaseAuth auth;
  final UserService userService;
  final BudgetService budgetService;
  final VoidCallback onSignedIn;

  @override
  State<StatefulWidget> createState() => new _ChooseLoginScreen();
}

class _ChooseLoginScreen extends State<ChooseLoginScreen> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    var uiProvider = Provider.of<UIProvider>(context);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.black.withOpacity(0.5),
        statusBarBrightness: Brightness.dark));

    Future<void> _showDialog(String title, String message,
        [Function func]) async {
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(message),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0))),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  'OK',
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () {
                  if (func != null) {
                    func();
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    Widget _showBody() {
      return Container(
        padding: EdgeInsets.only(bottom: 60.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              RaisedButton(
                  elevation: 0.0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(32.0))),
                  child: new Row(
                    children: <Widget>[
                      new Container(
                          padding:
                              const EdgeInsets.fromLTRB(16.0, 16.0, 32.0, 16.0),
                          child: new Image.asset('assets/go-logo.png')),
                      new Expanded(
                        child: new AutoSizeText(
                          "Sign in with Google",
                          maxLines: 1,
                          style: new TextStyle(color: Colors.grey),
                        ),
                      )
                    ],
                  ),
                  onPressed: () async {
                    setState(() {
                      uiProvider.isLoading = true;
                    });
                    try {
                      FirebaseUser user = await widget.auth.googleSignIn();

                      if (user.email != null && user.email != "") {
                        widget.onSignedIn();
                        setState(() {
                          uiProvider.isLoading = false;
                        });
                      }
                      // TODO: Need testing in release mode
                    } catch (e) {
                      print(e);
                      setState(() {
                        uiProvider.isLoading = false;
                      });
                      if (e.message != null) {
                        _showDialog("Account already exists", e.message);
                      }
                    }
                  }),
              Padding(
                padding: EdgeInsets.only(top: 15.0),
                child: RaisedButton(
                    elevation: 0.0,
                    color: Color.fromRGBO(59, 87, 157, 1.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(32.0))),
                    child: new Row(
                      children: <Widget>[
                        new Container(
                            padding: const EdgeInsets.fromLTRB(
                                16.0, 16.0, 32.0, 16.0),
                            child: new Image.asset('assets/fb-logo.png')),
                        new Expanded(
                          child: new AutoSizeText(
                            "Sign in with Facebook",
                            maxLines: 1,
                            style: new TextStyle(color: Colors.white),
                          ),
                        )
                      ],
                    ),
                    onPressed: () async {
                      setState(() {
                        uiProvider.isLoading = true;
                      });
                      try {
                        FirebaseUser user = await widget.auth.facebookSignIn();
                        if (user != null) {
                          if (user.email != null && user.email != "") {
                            widget.onSignedIn();
                            setState(() {
                              uiProvider.isLoading = false;
                            });
                          }
                          // User cancelled FB login
                        } else {
                          setState(() {
                            uiProvider.isLoading = false;
                          });
                        }
                      } catch (e) {
                        print(e);
                        setState(() {
                          uiProvider.isLoading = false;
                        });
                        _showDialog("Account already exists", e.message);
                      }
                    }),
              ),
              Padding(
                padding: EdgeInsets.only(top: 15.0),
                child: RaisedButton(
                    elevation: 0.0,
                    color: Colors.red[400],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(32.0))),
                    child: new Row(
                      children: <Widget>[
                        new Container(
                            padding: const EdgeInsets.fromLTRB(
                                16.0, 16.0, 32.0, 16.0),
                            child: new Image.asset('assets/email-logo.png')),
                        new Expanded(
                          child: new AutoSizeText(
                            "Sign in with email",
                            maxLines: 1,
                            style: new TextStyle(color: Colors.white),
                          ),
                        )
                      ],
                    ),
                    onPressed: () {
                      // Set auth and onSignedIn for Email Login to use
                      var authProvider = Provider.of<AuthProvider>(context);
                      authProvider.auth = widget.auth;
                      authProvider.onSignedIn = widget.onSignedIn;
                      Navigator.pushNamed(context, '/emailLogin');
                    }),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Platform.isAndroid
              ? AppBar(
                  brightness: Brightness.dark,
                )
              : Container(),
          Positioned.fill(
            child: AnimatedBackground(),
          ),
          onBottom(AnimatedWave(
            height: 100,
            speed: 0.5,
            color: Colors.white.withAlpha(60),
          )),
          onBottom(AnimatedWave(
            height: 120,
            speed: 0.4,
            offset: pi,
            color: Colors.white.withAlpha(60),
          )),
          onBottom(AnimatedWave(
            height: 220,
            speed: 0.7,
            offset: pi / 2,
            color: Colors.white.withAlpha(60),
          )),
          _showBody(),
          showCircularProgress(context)
        ],
      ),
    );
  }
}
