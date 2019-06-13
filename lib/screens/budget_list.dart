import 'dart:async';
import "package:intl/intl.dart";
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
  List<Budget> _budgetList = new List();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  StreamSubscription<Event> _onBudgetAddedSubscription;
  StreamSubscription<Event> _onBudgetChangedSubscription;

  Query _budgetQuery;
  final currency = NumberFormat.simpleCurrency();

  @override
  void initState() {
    super.initState();

    _budgetList = new List();
    _budgetQuery = _database
        .reference()
        .child("budgets")
        .orderByChild("createdBy")
        .equalTo(widget.userEmail);
    _onBudgetAddedSubscription =
        _budgetQuery.onChildAdded.listen(_onEntryAdded);
    _onBudgetChangedSubscription =
        _budgetQuery.onChildChanged.listen(_onEntryChanged);
  }

  @override
  void dispose() {
    _onBudgetAddedSubscription.cancel();
    _onBudgetChangedSubscription.cancel();
    super.dispose();
  }

  _onEntryChanged(Event event) {
    var oldBudget = _budgetList.singleWhere((budget) {
      return budget.key == event.snapshot.key;
    });

    setState(() {
      _budgetList[_budgetList.indexOf(oldBudget)] =
          Budget.fromSnapshot(event.snapshot);
    });
  }

  _onEntryAdded(Event event) {
    setState(() {
      _budgetList.add(Budget.fromSnapshot(event.snapshot));
    });
  }

  Widget _showBudgetList() {
    if (_budgetList.length > 0) {
      return ListView.builder(
          shrinkWrap: true,
          itemCount: _budgetList.length,
          itemBuilder: (BuildContext context, int index) {
            String budgetId = _budgetList[index].key;
            String name = _budgetList[index].name;
            int spent = _budgetList[index].spent;
            int setAmount = _budgetList[index].setAmount;
            return Dismissible(
              key: Key(budgetId),
              background: Container(color: Colors.red),
              onDismissed: (direction) async {
                // _deleteTodo(todoId, index);
                print("deleted");
              },
              child: ListTile(
                title: Text(
                  name,
                  style: TextStyle(fontSize: 20.0),
                ),
                subtitle: Row(
                  children: <Widget>[
                    Text(
                        "${currency.format(spent)} of ${currency.format(setAmount)}"),
                  ],
                ),
              ),
            );
          });
    } else {
      return Center(
          child: Text(
        "Welcome. Your list is empty",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 30.0),
      ));
    }
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
          children: <Widget>[_showBudgetList(), showCircularProgress(context)],
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
