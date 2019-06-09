import 'package:flutter/material.dart';
import 'package:groovy/services/auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:groovy/models/budget.dart';

class BudgetListScreen extends StatefulWidget {
  BudgetListScreen({Key key, this.auth, this.userEmail, this.onSignedOut})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String userEmail;

  @override
  State<StatefulWidget> createState() => new _BudgetListScreen();
}

class _BudgetListScreen extends State<BudgetListScreen> {
  List<Budget> _budgetList;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Query _budgetQuery;

  @override
  void initState() {
    super.initState();

    _budgetList = new List();
    _budgetQuery = _database
        .reference()
        .child("budgets")
        .orderByChild("createdBy")
        .equalTo(widget.userEmail);
    print(_budgetQuery.toString());
  }

  @override
  Widget build(BuildContext context) {
    _signOut() async {
      try {
        await widget.auth.signOut();
        widget.onSignedOut();
      } catch (e) {
        print(e);
      }
    }

    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Flutter login demo'),
          actions: <Widget>[
            new FlatButton(
                child: new Text('Logout',
                    style: new TextStyle(fontSize: 17.0, color: Colors.white)),
                onPressed: () {
                  print("Signed out");
                  _signOut();
                })
          ],
        ),
        body: Center(
          child: Text("Budgets go here"),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            print("Add new budget");
          },
          tooltip: 'Add Budget',
          child: Icon(Icons.add),
        ));
  }
}
