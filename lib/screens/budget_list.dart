import 'dart:async';
import 'dart:ui';
import "package:intl/intl.dart";
import 'package:flutter/material.dart';
import 'package:Groovy/services/auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Groovy/models/budget.dart';
import 'shared/widgets.dart';
import 'package:provider/provider.dart';
import 'shared/swipe_actions/swipe_widget.dart';
import 'shared/animated/background.dart';

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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
              child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView.builder(
                physics: BouncingScrollPhysics(),
                shrinkWrap: true,
                itemCount: _budgetList.length,
                itemBuilder: (BuildContext context, int index) {
                  String budgetId = _budgetList[index].key;
                  String name = _budgetList[index].name;
                  int spent = _budgetList[index].spent;
                  int setAmount = _budgetList[index].setAmount;
                  return OnSlide(
                      items: <ActionItems>[
                        new ActionItems(
                            icon: new IconButton(
                              icon: new Icon(Icons.edit),
                              onPressed: () {},
                              color: Colors.white,
                            ),
                            onPress: () {
                              print("edit");
                            },
                            backgroundColor: Colors.transparent),
                        new ActionItems(
                            icon: new IconButton(
                              icon: new Icon(Icons.person_add),
                              onPressed: () {},
                              color: Colors.white,
                            ),
                            onPress: () {},
                            backgroundColor: Colors.transparent),
                        new ActionItems(
                            icon: new IconButton(
                              icon: new Icon(Icons.delete),
                              onPressed: () {},
                              color: Colors.white,
                            ),
                            onPress: () {},
                            backgroundColor: Colors.transparent),
                      ],
                      child: Container(
                        height: 120,
                        padding: EdgeInsets.fromLTRB(32, 0, 32, 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32.0),
                        ),
                        child: new ClipRect(
                          child: new BackdropFilter(
                            filter: new ImageFilter.blur(
                              sigmaX: 15.0,
                              sigmaY: 15.0,
                            ),
                            child: new Container(
                                decoration: new BoxDecoration(
                                    borderRadius: BorderRadius.circular(32.0),
                                    color: Colors.black.withOpacity(0.5)),
                                child: Container(
                                  child: Card(
                                      borderOnForeground: false,
                                      elevation: 0,
                                      color: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(32.0))),
                                      child: InkWell(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(32.0)),
                                          onTap: () {},
                                          child: Stack(
                                            children: <Widget>[
                                              ListTile(
                                                contentPadding: EdgeInsets.only(
                                                    top: 11.0, left: 30.0),
                                                title: Text(
                                                  name,
                                                  style: TextStyle(
                                                      fontSize: 28.0,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white),
                                                ),
                                                subtitle: Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 5.0),
                                                  child: Text(
                                                    "${currency.format(spent)} of ${currency.format(setAmount)}",
                                                    style: TextStyle(
                                                        color: Colors.grey[400],
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 17.0),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ))),
                                )),
                          ),
                        ),
                      ));
                }),
          ))
        ],
      );
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
      drawer: Drawer(
          child: new FlatButton(
              child: new Text('Logout',
                  style: new TextStyle(fontSize: 17.0, color: Colors.black)),
              onPressed: () {
                setState(() {
                  budgetModel.isLoading = true;
                });
                _signOut();
              })),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: AnimatedBackground(),
          ),
          Column(
            children: <Widget>[
              Container(
                height: 110,
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  iconTheme: IconThemeData(color: Colors.white),
                  brightness: Brightness.dark,
                  elevation: 0.0,
                ),
              ),
              Expanded(
                child: _showBudgetList(),
              )
            ],
          )
          // showCircularProgress(context)
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black.withOpacity(0.5),
        child: Icon(
          Icons.add,
          size: 28,
          color: Colors.white,
        ),
        elevation: 0,
        onPressed: () {
          print("hi");
        },
      ),
    );
  }
}
