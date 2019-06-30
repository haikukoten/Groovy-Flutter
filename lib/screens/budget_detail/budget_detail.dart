import 'dart:ui';
import 'package:Groovy/screens/budget_detail/add_purchase.dart';
import 'package:Groovy/screens/budget_detail/budget_history.dart';
import 'package:Groovy/screens/budget_detail/edit_budget.dart';
import 'package:provider/provider.dart';
import 'package:Groovy/providers/auth_provider.dart';
import 'package:Groovy/providers/budget_provider.dart';
import 'package:Groovy/providers/ui_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import "package:intl/intl.dart";
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Groovy/models/budget.dart';
import '../shared/animated/background.dart';
import '../shared/utilities.dart';
import 'package:percent_indicator/percent_indicator.dart';

class BudgetDetailScreen extends StatefulWidget {
  BudgetDetailScreen({Key key}) : super(key: key);

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
    var authProvider = Provider.of<AuthProvider>(context);
    var uiProvider = Provider.of<UIProvider>(context);
    var budgetProvider = Provider.of<BudgetProvider>(context);

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
          onPressed: () {
            authProvider.auth.deleteBudget(_database, budget);
            print("Delete ${budget.key} successful");
            budgetProvider.budgetList.remove(budget);
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        )
      ]);
    }

    // Show 100% of circular indicator if spending is over 100%
    double _buildPercentSpent() {
      double percentSpent =
          (budgetProvider.selectedBudget.spent.floorToDouble() /
              budgetProvider.selectedBudget.setAmount.floorToDouble());
      if (percentSpent > 1) {
        percentSpent = 1;
      }
      return percentSpent;
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
          percent: _buildPercentSpent(),
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
                      color: Colors.white.withOpacity(0.99),
                      fontWeight: FontWeight.bold,
                      fontSize: 24),
                )
              : Text(
                  "${((budgetProvider.selectedBudget.spent / budgetProvider.selectedBudget.setAmount * 100).floor())}%",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.99),
                      fontWeight: FontWeight.bold,
                      fontSize: 24),
                ),
          circularStrokeCap: CircularStrokeCap.round,
          backgroundColor: uiProvider.isLightTheme
              ? Colors.white.withOpacity(0.4)
              : Colors.black.withOpacity(0.35),
          linearGradient: uiProvider.isLightTheme
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white54, Colors.white70],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black26, Colors.black54],
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
                color: uiProvider.isLightTheme
                    ? Colors.white.withOpacity(0.9)
                    : Colors.black.withOpacity(0.6),
                fontSize: 38,
                fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
                "spent of ${currency.format(budgetProvider.selectedBudget.setAmount)}",
                style: TextStyle(
                    color: uiProvider.isLightTheme
                        ? Colors.white.withOpacity(0.9)
                        : Colors.black.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w400)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 45.0),
            child: Text(
                "${currency.format(budgetProvider.selectedBudget.left)}",
                style: TextStyle(
                    color: uiProvider.isLightTheme
                        ? Colors.white.withOpacity(0.9)
                        : Colors.black.withOpacity(0.6),
                    fontSize: 38,
                    fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text("left to spend",
                style: TextStyle(
                    color: uiProvider.isLightTheme
                        ? Colors.white.withOpacity(0.9)
                        : Colors.black.withOpacity(0.7),
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
                              fontSize: 22.0,
                              color: uiProvider.isLightTheme
                                  ? Colors.black
                                  : Colors.white)),
                      onPressed: () {
                        print("Share");
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
                              fontSize: 22.0,
                              color: uiProvider.isLightTheme
                                  ? Colors.black
                                  : Colors.white)),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(CupertinoPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => BudgetHistoryScreen(
                                  budget: budgetProvider.selectedBudget,
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
                              fontSize: 22.0,
                              color: uiProvider.isLightTheme
                                  ? Colors.black
                                  : Colors.white)),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(CupertinoPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => EditBudgetScreen(
                                  budget: budgetProvider.selectedBudget,
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
                              fontSize: 22.0,
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
          ));
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
          if (_finalDragAmount < 0) {
            Navigator.of(context).push(CupertinoPageRoute(
                fullscreenDialog: true,
                builder: (context) => AddPurchaseScreen()));
          }

          // Swipe down to show modal menu
          if (_finalDragAmount > 0) {
            _showModalMenu();
          }
        },
        child: Stack(
          children: <Widget>[
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
                title: Text("${budgetProvider.selectedBudget.name}"),
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
                    ? Colors.white.withOpacity(0.5)
                    : Colors.black.withOpacity(0.5),
                child: Icon(
                  Icons.add,
                  size: 28,
                  color:
                      uiProvider.isLightTheme ? Colors.grey[800] : Colors.white,
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
