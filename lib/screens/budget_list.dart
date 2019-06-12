import 'package:flutter/material.dart';
import 'package:Groovy/services/auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Groovy/models/budget.dart';
import 'shared/shared_widgets.dart';
import 'package:provider/provider.dart';

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
    var budgetModel = Provider.of<BudgetModel>(context);

    _signOut() async {
      try {
        await widget.auth.signOut();
        widget.onSignedOut();
        setState(() {
          budgetModel.isLoading = false;
        });
      } catch (e) {
        print(e);
      }
    }

    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Budgets'),
          actions: <Widget>[
            new FlatButton(
                child: new Text('Logout',
                    style: new TextStyle(fontSize: 17.0, color: Colors.white)),
                onPressed: () {
                  print("Signed out");
                  setState(() {
                    budgetModel.isLoading = true;
                  });
                  _signOut();
                })
          ],
        ),
        body: Stack(
          children: <Widget>[
            Center(
              child: Text("Budgets go here"),
            ),
            showCircularProgress(context)
          ],
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
