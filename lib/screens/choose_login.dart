import 'package:flutter/material.dart';
import 'package:groovy/services/auth.dart';
import 'package:provider/provider.dart';
import 'package:groovy/models/budget.dart';

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text("Sign Up"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlatButton(
                child: Text("Google Login"),
                onPressed: () {
                  print("Google");
                },
              ),
              FlatButton(
                child: Text("Facebook Login"),
                onPressed: () {
                  print("Facebook");
                },
              ),
              FlatButton(
                  child: Text("Email Login"),
                  onPressed: () {
                    // Set auth and onSignedIn for Email Login to use
                    var budgetModel = Provider.of<BudgetModel>(context);
                    budgetModel.auth = widget.auth;
                    budgetModel.onSignedIn = widget.onSignedIn;
                    Navigator.pushNamed(context, '/emailLogin');
                  })
            ],
          ),
        ),
      ),
    );
  }
}
