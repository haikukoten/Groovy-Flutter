import 'dart:async';
import 'dart:ui';
import 'package:Groovy/providers/auth_provider.dart';
import 'package:Groovy/providers/budget_provider.dart';
import 'package:Groovy/providers/ui_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import "package:intl/intl.dart";
import 'package:flutter/material.dart';
import 'package:Groovy/services/auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Groovy/models/budget.dart';
import 'package:provider/provider.dart';
import 'shared/swipe_actions/swipe_widget.dart';
import 'shared/animated/background.dart';
import 'shared/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'budget_detail.dart';

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
  Query _budgetQuery;
  final currency = NumberFormat.simpleCurrency();
  SharedPreferences preferences;

  StreamSubscription<Event> _onBudgetAddedSubscription;
  StreamSubscription<Event> _onBudgetChangedSubscription;

  // Create budget key, controllers, and node
  final _createBudgetFormKey = GlobalKey<FormState>();
  var nameTextController = TextEditingController();
  var amountTextController = TextEditingController();

  String _name;
  String _amount;

  @override
  void initState() {
    super.initState();
    getSavedThemePreference();
    _budgetQuery = _database.reference().child("budgets");

    _onBudgetAddedSubscription =
        _budgetQuery.onChildAdded.listen(_onEntryAdded);
    _onBudgetChangedSubscription =
        _budgetQuery.onChildChanged.listen(_onEntryChanged);

    // Listen to amount text controller changes to control how many decimals are input
    amountTextController.addListener(_onAmountChanged);
  }

  void getSavedThemePreference() async {
    preferences = await SharedPreferences.getInstance();
    var uiProvider = Provider.of<UIProvider>(context);
    uiProvider.isLightTheme = preferences.getBool("theme") ?? false;
  }

  @override
  void dispose() {
    _onBudgetAddedSubscription.cancel();
    _onBudgetChangedSubscription.cancel();
    super.dispose();
  }

  _onEntryChanged(Event event) {
    Budget budget = Budget.fromSnapshot(event.snapshot);

    // Update budget if it was created by signed in user
    if (event.snapshot.value["createdBy"] == widget.user.email) {
      var oldBudget = _budgetList.singleWhere((budget) {
        return budget.key == event.snapshot.key;
      });

      setState(() {
        _budgetList[_budgetList.indexOf(oldBudget)] =
            Budget.fromSnapshot(event.snapshot);
      });

      // Update budget if it was not created by signed in user (budget shared with user)
    } else if (event.snapshot.value["sharedWith"].contains(widget.user.email)) {
      try {
        // Shared budget got changed so update it
        var oldBudget = _budgetList.singleWhere((budget) {
          return budget.key == event.snapshot.key;
        });
        setState(() {
          _budgetList[_budgetList.indexOf(oldBudget)] =
              Budget.fromSnapshot(event.snapshot);
        });
      } catch (e) {
        // Budget just got shared with signed in user so add it to list
        setState(() {
          _budgetList.add(budget);
          // Sort budgets alphabetically
          _budgetList.sort((a, b) => a.name.compareTo(b.name));
        });
      }
      ;

      // User is no longer shared with budget so remove it
    } else {
      if (!budget.sharedWith.contains(widget.user.email)) {
        for (Budget userBudget in _budgetList) {
          if (userBudget.key == budget.key) {
            setState(() {
              _budgetList.remove(userBudget);
            });
          }
        }
      }
    }
  }

  _onEntryAdded(Event event) {
    if (event.snapshot.value["createdBy"] == widget.user.email ||
        event.snapshot.value["sharedWith"].contains(widget.user.email)) {
      setState(() {
        _budgetList.add(Budget.fromSnapshot(event.snapshot));
        // Sort budgets alphabetically
        _budgetList.sort((a, b) => a.name.compareTo(b.name));
      });
    }
  }

  _onAmountChanged() {
    var decimalCount = ".".allMatches(amountTextController.text).length;
    if (decimalCount > 1) {
      print("Contains more than one decimal");
      setState(() {
        int decimalIndex = amountTextController.text.lastIndexOf(".");
        amountTextController.text = amountTextController.text
            .replaceFirst(RegExp('.'), '', decimalIndex);
        amountTextController.selection =
            TextSelection.collapsed(offset: amountTextController.text.length);
      });
    }
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

  @override
  Widget build(BuildContext context) {
    var uiProvider = Provider.of<UIProvider>(context);

    _signOut() async {
      try {
        await widget.auth.signOut();
        widget.onSignedOut();
        setState(() {
          uiProvider.isLoading = false;
        });
      } catch (e) {
        print(e);
      }
    }

    // Check if form is valid before creating budget
    bool _validateAndSave() {
      final form = _createBudgetFormKey.currentState;
      if (form.validate()) {
        form.save();
        return true;
      }
      return false;
    }

    void _createBudget() {
      if (_validateAndSave()) {
        widget.auth.createBudget(_database, widget.user, _name, _amount);
        Navigator.of(context).pop();
      }
    }

    void _deleteBudget(Budget budget) async {
      showAlertDialog(context, "Delete '${budget.name}'",
          "Are you sure you want to delete this budget?", [
        FlatButton(
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          child: Text(
            'Delete',
            style: TextStyle(
                color: uiProvider.isLightTheme ? Colors.black : Colors.white),
          ),
          onPressed: () {
            widget.auth.deleteBudget(_database, budget);
            print("Delete ${budget.key} successful");
            int budgetIndex = _budgetList.indexOf(budget);
            setState(() {
              _budgetList.removeAt(budgetIndex);
            });
            Navigator.of(context).pop();
          },
        )
      ]);
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
                              onPress: () {
                                print("share");
                              },
                              backgroundColor: Colors.transparent),
                          new ActionItems(
                              icon: new IconButton(
                                icon: new Icon(Icons.delete),
                                onPressed: () {},
                                color: Colors.white,
                              ),
                              onPress: () {
                                _deleteBudget(_budgetList[index]);
                                print("delete");
                              },
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
                                      color: uiProvider.isLightTheme
                                          ? Colors.white.withOpacity(0.5)
                                          : Colors.black.withOpacity(0.5)),
                                  child: Container(
                                    child: Card(
                                        borderOnForeground: false,
                                        elevation: 0,
                                        color: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(32.0))),
                                        child: InkWell(
                                            splashColor: uiProvider.isLightTheme
                                                ? Colors.grey[300]
                                                    .withOpacity(0.5)
                                                : Colors.grey[100]
                                                    .withOpacity(0.1),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(32.0)),
                                            onTap: () {
                                              var budgetProvider =
                                                  Provider.of<BudgetProvider>(
                                                      context);
                                              budgetProvider.selectedBudget =
                                                  _budgetList[index];
                                              var authProvider =
                                                  Provider.of<AuthProvider>(
                                                      context);
                                              authProvider.auth = widget.auth;
                                              Navigator.pushNamed(
                                                  context, '/budgetDetail');
                                            },
                                            child: Stack(
                                              children: <Widget>[
                                                ListTile(
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          top: 11.0,
                                                          left: 30.0),
                                                  title: Text(
                                                    name,
                                                    style: TextStyle(
                                                        fontSize: 28.0,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: uiProvider
                                                                .isLightTheme
                                                            ? Colors.grey[800]
                                                            : Colors.white),
                                                  ),
                                                  subtitle: Padding(
                                                    padding: EdgeInsets.only(
                                                        top: 5.0),
                                                    child: Text(
                                                      "${currency.format(spent)} of ${currency.format(setAmount)}",
                                                      style: TextStyle(
                                                          color: uiProvider
                                                                  .isLightTheme
                                                              ? Colors.grey[700]
                                                              : Colors
                                                                  .grey[400],
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
            child: Container(
          padding: EdgeInsets.only(bottom: 100.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "No budgets",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                    color: Colors.black.withOpacity(0.5)),
              ),
              Text(
                "Create one to get started",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18.0, color: Colors.black.withOpacity(0.5)),
              ),
            ],
          ),
        ));
      }
    }

    return Stack(children: <Widget>[
      Positioned.fill(
        child: AnimatedBackground(),
      ),
      Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: Colors.white),
          brightness: Brightness.dark,
          elevation: 0.0,
        ),
        drawer: Drawer(
            child: Container(
          color: uiProvider.isLightTheme ? Colors.white : Colors.grey[900],
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
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
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
                              backgroundColor: Colors.grey[300],
                              radius: 29,
                              child: Center(
                                child: Text(
                                  widget.user.email
                                      .substring(0, 1)
                                      .toLowerCase(),
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                    )),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "budgets",
                      style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.w700,
                          color: uiProvider.isLightTheme
                              ? Colors.black87
                              : Colors.grey),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        "${_budgetList.length.toString()}",
                        style: TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.w700,
                            color: uiProvider.isLightTheme
                                ? Colors.grey[500]
                                : Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                color: Colors.grey[500],
              ),
              Padding(
                padding:
                    const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "total spent",
                      style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.w700,
                          color: uiProvider.isLightTheme
                              ? Colors.black87
                              : Colors.grey),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        "${currency.format(totalAmountSpent())}",
                        style: TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.w700,
                            color: uiProvider.isLightTheme
                                ? Colors.grey[500]
                                : Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                color: Colors.grey[500],
              ),
              Padding(
                padding:
                    const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "total left",
                      style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.w700,
                          color: uiProvider.isLightTheme
                              ? Colors.black87
                              : Colors.grey),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        "${currency.format(totalAmountLeft())}",
                        style: TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.w700,
                            color: uiProvider.isLightTheme
                                ? Colors.grey[500]
                                : Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                color: Colors.grey[500],
              ),
              Padding(
                padding:
                    const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "theme",
                      style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.w700,
                          color: uiProvider.isLightTheme
                              ? Colors.black87
                              : Colors.grey),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(right: 5.0),
                            child: CircleAvatar(
                              backgroundColor: uiProvider.isLightTheme
                                  ? Colors.transparent
                                  : Color(0xffd57eeb),
                              radius: 30,
                              child: FloatingActionButton(
                                tooltip: "Dark",
                                mini: true,
                                elevation: 0.0,
                                backgroundColor: Colors.black87,
                                child: Icon(Icons.brightness_2),
                                onPressed: () {
                                  setState(() {
                                    uiProvider.isLightTheme = false;
                                    preferences.setBool(
                                        "theme", uiProvider.isLightTheme);
                                  });
                                  print("Dark");
                                },
                              ),
                            ),
                          ),
                          CircleAvatar(
                            backgroundColor: uiProvider.isLightTheme
                                ? Color(0xffd57eeb)
                                : Colors.transparent,
                            radius: 30,
                            child: FloatingActionButton(
                              tooltip: "Light",
                              mini: true,
                              elevation: 0.0,
                              backgroundColor: Colors.grey[200],
                              child: Icon(
                                Icons.wb_sunny,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  uiProvider.isLightTheme = true;
                                  preferences.setBool(
                                      "theme", uiProvider.isLightTheme);
                                });
                                print("Light");
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
                        showAlertDialog(context, "Signout",
                            "Are you sure you want to signout?", [
                          FlatButton(
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          FlatButton(
                            child: Text(
                              'Signout',
                              style: TextStyle(
                                  color: uiProvider.isLightTheme
                                      ? Colors.black
                                      : Colors.white),
                            ),
                            onPressed: () {
                              setState(() {
                                uiProvider.isLoading = true;
                              });
                              _signOut();
                              Navigator.of(context).pop();
                            },
                          )
                        ]);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        )),
        body: _showBudgetList(),
        floatingActionButton: FloatingActionButton(
          backgroundColor: uiProvider.isLightTheme
              ? Colors.white.withOpacity(0.5)
              : Colors.black.withOpacity(0.5),
          child: Icon(
            Icons.add,
            size: 28,
            color: uiProvider.isLightTheme ? Colors.grey[800] : Colors.white,
          ),
          elevation: 0,
          onPressed: () {
            nameTextController.text = "";
            amountTextController.text = "";
            showInputDialog(
                context,
                uiProvider.isLightTheme ? Colors.white : Colors.black,
                Text(
                  "Create Budget",
                  style: TextStyle(
                      color: uiProvider.isLightTheme
                          ? Colors.black
                          : Colors.grey[300],
                      fontWeight: FontWeight.w500),
                ),
                "",
                FlatButton(
                    child: Text(
                      'Create',
                      style: TextStyle(
                          color: uiProvider.isLightTheme
                              ? Colors.black
                              : Colors.white),
                    ),
                    onPressed: () async {
                      _createBudget();
                    }),
                Form(
                  key: _createBudgetFormKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        style: TextStyle(
                            color: uiProvider.isLightTheme
                                ? Colors.grey[900]
                                : Colors.white),
                        cursorColor: uiProvider.isLightTheme
                            ? Colors.black87
                            : Colors.grey,
                        keyboardAppearance: uiProvider.isLightTheme
                            ? Brightness.light
                            : Brightness.dark,
                        maxLines: 1,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.words,
                        autofocus: true,
                        controller: nameTextController,
                        decoration: InputDecoration(
                            errorStyle: TextStyle(color: Colors.red[300]),
                            hintText: 'Name',
                            hintStyle: TextStyle(color: Colors.grey),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: uiProvider.isLightTheme
                                        ? Colors.grey
                                        : Colors.white)),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: uiProvider.isLightTheme
                                        ? Colors.grey
                                        : Colors.grey[200]))),
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Name can\'t be empty';
                          }
                        },
                        onSaved: (value) => _name = value,
                      ),
                      TextFormField(
                        style: TextStyle(
                            color: uiProvider.isLightTheme
                                ? Colors.grey[900]
                                : Colors.white),
                        cursorColor: uiProvider.isLightTheme
                            ? Colors.black87
                            : Colors.grey,
                        keyboardAppearance: uiProvider.isLightTheme
                            ? Brightness.light
                            : Brightness.dark,
                        maxLines: 1,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        controller: amountTextController,
                        decoration: InputDecoration(
                            errorStyle: TextStyle(color: Colors.red[300]),
                            hintText: '\$',
                            hintStyle: TextStyle(color: Colors.grey),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: uiProvider.isLightTheme
                                        ? Colors.grey
                                        : Colors.white)),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: uiProvider.isLightTheme
                                        ? Colors.grey
                                        : Colors.grey[200]))),
                        inputFormatters: [
                          DecimalTextInputFormatter(decimalRange: 2),
                          BlacklistingTextInputFormatter(
                              RegExp('[\\,|\\-|\\ ]')),
                        ],
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Amount can\'t be empty';
                          }
                        },
                        onFieldSubmitted: (value) {
                          _createBudget();
                        },
                        onSaved: (value) => _amount = value,
                      ),
                    ],
                  ),
                ));
          },
        ),
      ),
    ]);
  }
}
