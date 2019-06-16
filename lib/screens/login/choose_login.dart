import 'dart:ui';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Groovy/services/auth.dart';
import 'package:provider/provider.dart';
import 'package:Groovy/models/budget.dart';
import '../shared/widgets.dart';
import '../shared/animated/background.dart';
import '../shared/animated/wave.dart';

class ChooseLoginScreen extends StatefulWidget {
  ChooseLoginScreen({Key key, this.auth, this.onSignedIn}) : super(key: key);

  final BaseAuth auth;
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

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white, statusBarBrightness: Brightness.dark));

    var budgetModel = Provider.of<BudgetModel>(context);

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
                        child: new Text(
                          "Sign in with Google",
                          style: new TextStyle(color: Colors.grey),
                        ),
                      )
                    ],
                  ),
                  onPressed: () async {
                    setState(() {
                      budgetModel.isLoading = true;
                    });
                    try {
                      FirebaseUser user = await widget.auth.googleSignIn();

                      if (user.email != null && user.email != "") {
                        widget.onSignedIn();
                        setState(() {
                          budgetModel.isLoading = false;
                        });
                      }
                      // TODO: Need testing in release mode
                    } catch (e) {
                      print(e);
                      setState(() {
                        budgetModel.isLoading = false;
                      });
                      if (e.message != null) {
                        showAlertDialog(
                            context, "Account already exists", e.message);
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
                          child: new Text(
                            "Sign in with Facebook",
                            style: new TextStyle(color: Colors.white),
                          ),
                        )
                      ],
                    ),
                    onPressed: () async {
                      setState(() {
                        budgetModel.isLoading = true;
                      });
                      try {
                        FirebaseUser user = await widget.auth.facebookSignIn();
                        if (user != null) {
                          if (user.email != null && user.email != "") {
                            widget.onSignedIn();
                            setState(() {
                              budgetModel.isLoading = false;
                            });
                          }
                          // User cancelled FB login
                        } else {
                          setState(() {
                            budgetModel.isLoading = false;
                          });
                        }
                      } catch (e) {
                        print(e);
                        setState(() {
                          budgetModel.isLoading = false;
                        });
                        showAlertDialog(
                            context, "Account already exists", e.message);
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
                          child: new Text(
                            "Sign in with email",
                            style: new TextStyle(color: Colors.white),
                          ),
                        )
                      ],
                    ),
                    onPressed: () {
                      // Set auth and onSignedIn for Email Login to use
                      var budgetModel = Provider.of<BudgetModel>(context);
                      budgetModel.auth = widget.auth;
                      budgetModel.onSignedIn = widget.onSignedIn;
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
