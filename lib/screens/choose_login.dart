import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Groovy/services/auth.dart';
import 'package:provider/provider.dart';
import 'package:Groovy/models/budget.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'shared/shared_widgets.dart';

class ChooseLoginScreen extends StatefulWidget {
  ChooseLoginScreen({Key key, this.auth, this.onSignedIn, this.onSocialSignIn})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback onSignedIn;
  final VoidCallback onSocialSignIn;

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
                      GoogleSignInAccount googleUser =
                          await widget.auth.googleSignIn();

                      if (googleUser.email != null && googleUser.email != "") {
                        budgetModel.userEmail = googleUser.email;
                        widget.onSocialSignIn();
                        setState(() {
                          budgetModel.isLoading = false;
                        });
                      }
                    } catch (e) {
                      print(e);
                    }
                  }),
              Padding(
                padding: EdgeInsets.only(top: 15.0),
                child: RaisedButton(
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
                        dynamic facebookResult =
                            await widget.auth.facebookSignIn();

                        if (facebookResult != null) {
                          // FB profile exists
                          if (facebookResult["email"] != null) {
                            budgetModel.userEmail = facebookResult["email"];
                            widget.onSocialSignIn();
                            setState(() {
                              budgetModel.isLoading = false;
                            });
                          }
                          // Error message
                          else {
                            print(facebookResult);
                            setState(() {
                              budgetModel.isLoading = false;
                            });
                          }
                        }
                        // User cancelled FB signin
                        else {
                          print("User cancelled");
                          setState(() {
                            budgetModel.isLoading = false;
                          });
                        }
                      } catch (e) {
                        print(e);
                      }
                    }),
              ),
              Padding(
                padding: EdgeInsets.only(top: 15.0),
                child: RaisedButton(
                    color: Color.fromRGBO(219, 68, 55, 1.0),
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
        children: <Widget>[_showBody(), showCircularProgress(context)],
      ),
    );
  }
}
