import 'dart:ui';
import 'package:Groovy/screens/budget_detail/add_purchase.dart';
import 'package:Groovy/screens/budget_detail/budget_history.dart';
import 'package:Groovy/screens/budget_detail/edit_budget.dart';
import 'package:Groovy/screens/budget_detail/share_budget.dart';
import 'package:Groovy/services/auth_service.dart';
import 'package:Groovy/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:Groovy/providers/budget_provider.dart';
import 'package:Groovy/providers/user_provider.dart';
import 'package:Groovy/providers/ui_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import "package:intl/intl.dart";
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Groovy/models/budget.dart';
import '../shared/utilities.dart';
import 'package:percent_indicator/percent_indicator.dart';

class BudgetDetailScreen extends StatefulWidget {
  BudgetDetailScreen({Key key, this.user, this.auth, this.userService})
      : super(key: key);

  final FirebaseUser user;
  final BaseAuth auth;
  final UserService userService;

  @override
  State<StatefulWidget> createState() => new _BudgetDetailScreen();
}

class _BudgetDetailScreen extends State<BudgetDetailScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final currency = NumberFormat.simpleCurrency();

  double _initialDragAmount;
  double _finalDragAmount;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var uiProvider = Provider.of<UIProvider>(context);
    var budgetProvider = Provider.of<BudgetProvider>(context);
    var userProvider = Provider.of<UserProvider>(context);

    void _deleteBudget(Budget budget) async {
      showAlertDialog(context, "Delete ${budget.name}",
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
          onPressed: () async {
            if (budget.isShared) {
              var sharedWith = [];
              budget.sharedWith.forEach((email) {
                sharedWith.add(email);
              });
              // remove user from budget shared with
              sharedWith.remove(userProvider.currentUser.email);
              budget.sharedWith = sharedWith;

              // if shared with is only 1 item, then isShared is false
              if (sharedWith.length == 1) {
                budget.isShared = false;
              }

              // Update all users on sharedWith
              await userProvider.userService
                  .updateSharedUsers(_database, budget, budgetProvider);
            }

            // Delete budget for current user
            budgetProvider.budgetService
                .deleteBudget(_database, userProvider.currentUser, budget);
            print("Delete ${budget.key} successful");
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        )
      ]);
    }

    Widget _buildCircularIndicator() {
      return Container(
        padding: EdgeInsets.only(top: 50),
        alignment: Alignment.topCenter,
        child: CircularPercentIndicator(
          animateFromLastPercent: true,
          animation: true,
          startAngle: 0.0,
          radius: 225.0,
          lineWidth: 30.0,
          percent: buildPercentSpent(budgetProvider.selectedBudget),
          animationDuration: 800,
          // Show 500+ % if spending is over 500 % of set amount
          center: (budgetProvider.selectedBudget.spent.floorToDouble() /
                          budgetProvider.selectedBudget.setAmount
                              .floorToDouble()) *
                      100 >
                  500
              ? Text(
                  "500+ %",
                  style: TextStyle(
                      color: uiProvider.isLightTheme
                          ? Colors.grey[700]
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24),
                )
              : Text(
                  "${((budgetProvider.selectedBudget.spent / budgetProvider.selectedBudget.setAmount * 100).floor())}%",
                  style: TextStyle(
                      color: uiProvider.isLightTheme
                          ? Colors.grey[700]
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24),
                ),
          circularStrokeCap: CircularStrokeCap.round,
          backgroundColor:
              uiProvider.isLightTheme ? Colors.white : Colors.black,
          linearGradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: uiProvider.isLightTheme
                ? [Colors.purple[200], Color(0xffa88beb).withOpacity(0.7)]
                : [Colors.purple[300], Color(0xffa88beb).withOpacity(0.9)],
          ),
        ),
      );
    }

    Widget _buildDetailText() {
      return Column(
        children: <Widget>[
          Text(
            "${currency.format(budgetProvider.selectedBudget.spent)}",
            style: TextStyle(
                color:
                    uiProvider.isLightTheme ? Colors.grey[800] : Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
                "spent of ${currency.format(budgetProvider.selectedBudget.setAmount)}",
                style: TextStyle(
                    color: uiProvider.isLightTheme
                        ? Colors.grey[700]
                        : Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w400)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 45.0),
            child: Text(
                "${currency.format(budgetProvider.selectedBudget.left)}",
                style: TextStyle(
                    color: uiProvider.isLightTheme
                        ? Colors.grey[800]
                        : Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text("left to spend",
                style: TextStyle(
                    color: uiProvider.isLightTheme
                        ? Colors.grey[700]
                        : Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w400)),
          )
        ],
      );
    }

    Widget _buildBody() {
      return Column(
        children: <Widget>[
          Expanded(
            child: _buildCircularIndicator(),
            flex: 3,
          ),
          Expanded(
            child: _buildDetailText(),
            flex: 2,
          ),
        ],
      );
    }

    void _showModalMenu() {
      modalBottomSheetMenu(
          context,
          uiProvider,
          Column(
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 5.0),
                  child: SizedBox(
                    height: 55.0,
                    width: double.infinity,
                    child: RaisedButton(
                      elevation: 0.0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32.0)),
                      color: Colors.transparent,
                      child: Text('Share',
                          style: TextStyle(
                              fontSize: 18.0,
                              color: uiProvider.isLightTheme
                                  ? Colors.black
                                  : Colors.white)),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(CupertinoPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => ShareBudgetScreen(
                                budget: budgetProvider.selectedBudget,
                                auth: widget.auth,
                                user: widget.user,
                                userService: widget.userService)));
                      },
                    ),
                  )),
              Divider(
                color: Colors.grey[500],
              ),
              Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
                  child: SizedBox(
                    height: 55.0,
                    width: double.infinity,
                    child: RaisedButton(
                      elevation: 0.0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32.0)),
                      color: Colors.transparent,
                      child: Text('History',
                          style: TextStyle(
                              fontSize: 18.0,
                              color: uiProvider.isLightTheme
                                  ? Colors.black
                                  : Colors.white)),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(CupertinoPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => BudgetHistoryScreen(
                                  budget: budgetProvider.selectedBudget,
                                  user: widget.user,
                                )));
                      },
                    ),
                  )),
              Divider(
                color: Colors.grey[500],
              ),
              Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
                  child: SizedBox(
                    height: 55.0,
                    width: double.infinity,
                    child: RaisedButton(
                      elevation: 0.0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32.0)),
                      color: Colors.transparent,
                      child: Text('Edit',
                          style: TextStyle(
                              fontSize: 18.0,
                              color: uiProvider.isLightTheme
                                  ? Colors.black
                                  : Colors.white)),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(CupertinoPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => EditBudgetScreen(
                                  budget: budgetProvider.selectedBudget,
                                  user: widget.user,
                                )));
                      },
                    ),
                  )),
              Divider(
                color: Colors.grey[500],
              ),
              Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 10.0),
                  child: SizedBox(
                    height: 55.0,
                    width: double.infinity,
                    child: RaisedButton(
                      elevation: 0.0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32.0)),
                      color: Colors.transparent,
                      child: Text('Delete',
                          style: TextStyle(
                              fontSize: 18.0,
                              color: uiProvider.isLightTheme
                                  ? Colors.purple[300]
                                  : Color(0xffe0c3fc))),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteBudget(budgetProvider.selectedBudget);
                      },
                    ),
                  ))
            ],
          ),
          320.0);
    }

    return GestureDetector(
        onPanStart: (details) {
          _initialDragAmount = details.globalPosition.dy;
        },
        onPanUpdate: (details) {
          _finalDragAmount = details.globalPosition.dy - _initialDragAmount;
        },
        onPanEnd: (details) {
          // Swipe up to show 'Add Purchase' screen
          if (_finalDragAmount < -80) {
            Navigator.of(context).push(CupertinoPageRoute(
                fullscreenDialog: true,
                builder: (context) => AddPurchaseScreen(
                      user: widget.user,
                    )));
          }

          // Swipe down to show modal menu
          if (_finalDragAmount > 80) {
            _showModalMenu();
          }
        },
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: uiProvider.isLightTheme
                  ? backgroundWithSolidColor(Color(0xfff2f3fc))
                  : backgroundWithSolidColor(Colors.grey[900]),
            ),
            Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                iconTheme: IconThemeData(
                    color: uiProvider.isLightTheme
                        ? Colors.grey[700]
                        : Colors.white),
                brightness: uiProvider.isLightTheme
                    ? Brightness.light
                    : Brightness.dark,
                elevation: 0.0,
                title: Text(
                  "${budgetProvider.selectedBudget.name}",
                  style: TextStyle(
                      color: uiProvider.isLightTheme
                          ? Colors.grey[900]
                          : Colors.white),
                ),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.more_vert),
                    onPressed: () {
                      _showModalMenu();
                    },
                  )
                ],
              ),
              body: _buildBody(),
              floatingActionButton: FloatingActionButton(
                backgroundColor: uiProvider.isLightTheme
                    ? Colors.purple[300]
                    : Colors.purple[200],
                child: Icon(
                  Icons.add,
                  size: 28,
                  color: uiProvider.isLightTheme ? Colors.white : Colors.black,
                ),
                elevation: 0,
                onPressed: () {
                  Navigator.of(context).push(CupertinoPageRoute(
                      fullscreenDialog: true,
                      builder: (context) => AddPurchaseScreen()));
                },
              ),
            ),
          ],
        ));
  }
}
