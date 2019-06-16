import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import "package:intl/intl.dart";
import 'package:flutter/material.dart';
import 'package:Groovy/services/auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Groovy/models/budget.dart';
import 'package:provider/provider.dart';
import 'shared/swipe_actions/swipe_widget.dart';
import 'shared/animated/background.dart';

class BudgetListScreen extends StatefulWidget {
  BudgetListScreen({Key key, this.auth, this.user, this.onSignedOut})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final FirebaseUser user;

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

    _budgetQuery = _database
        .reference()
        .child("budgets")
        .orderByChild("createdBy")
        .equalTo(widget.user.email);
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

  num totalAmountSpent() {
    num totalSpent = 0;
    for (int i = 0; i < _budgetList.length; i++) {
      totalSpent += _budgetList[i].spent;
    }
    return totalSpent;
  }

  num totalAmountBudgeted() {
    num totalBudgeted = 0;
    if (_budgetList.length > 0) {
      for (int i = 0; i < _budgetList.length; i++) {
        totalBudgeted += _budgetList[i].setAmount;
      }
    }
    return totalBudgeted;
  }

  num totalAmountLeft() {
    num totalLeft = 0;
    if (_budgetList.length > 0) {
      for (int i = 0; i < _budgetList.length; i++) {
        totalLeft += _budgetList[i].left;
      }
    }
    return totalLeft;
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
                  num spent = _budgetList[index].spent;
                  num setAmount = _budgetList[index].setAmount;
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
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.black),
            accountEmail: widget.user.email != null
                ? Text(widget.user.email)
                : SizedBox.shrink(),
            accountName: widget.user.displayName != null
                ? Text(
                    widget.user.displayName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  )
                : SizedBox.shrink(),
            currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.black,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(45.0),
                  child: widget.user.photoUrl != null
                      ? Image.network(
                          widget.user.photoUrl,
                          fit: BoxFit.cover,
                        )
                      : CircleAvatar(
                          backgroundColor: Colors.grey[400],
                          radius: 29,
                          child: Center(
                            child: Text(
                              widget.user.email.substring(0, 1).toLowerCase(),
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                        ),
                )),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "budgets",
                  style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    "${_budgetList.length.toString()}",
                    style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.grey[500],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "total spent",
                  style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    "${currency.format(totalAmountSpent())}",
                    style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.grey[500],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "total left",
                  style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    "${currency.format(totalAmountLeft())}",
                    style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.grey[500],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "theme",
                  style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: <Widget>[
                      FloatingActionButton(
                        tooltip: "Light",
                        mini: true,
                        elevation: 0.0,
                        backgroundColor: Colors.grey[400],
                        child: Icon(Icons.wb_sunny),
                        onPressed: () {
                          print("Light");
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: FloatingActionButton(
                          tooltip: "Dark",
                          mini: true,
                          elevation: 0.0,
                          backgroundColor: Colors.black87,
                          child: Icon(Icons.brightness_2),
                          onPressed: () {
                            print("Dark");
                          },
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 14.0, bottom: 16),
                child: FloatingActionButton(
                  tooltip: "Signout",
                  elevation: 0,
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black87,
                  child: RotationTransition(
                      turns: new AlwaysStoppedAnimation(180 / 360),
                      child: Icon(
                        Icons.exit_to_app,
                      )),
                  onPressed: () {
                    setState(() {
                      budgetModel.isLoading = true;
                    });
                    _signOut();
                  },
                ),
              ),
            ),
          ),
        ],
      )),
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
