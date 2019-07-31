import 'dart:ui';
import 'package:Groovy/models/budget.dart';
import 'package:Groovy/providers/budget_provider.dart';
import 'package:Groovy/providers/ui_provider.dart';
import 'package:Groovy/providers/user_provider.dart';
import 'package:Groovy/screens/budget_detail/edit_history.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../shared/utilities.dart';

class BudgetHistoryScreen extends StatefulWidget {
  BudgetHistoryScreen({Key key, this.budget, this.user}) : super(key: key);

  final Budget budget;
  final FirebaseUser user;

  @override
  State<StatefulWidget> createState() => _BudgetHistoryScreen();
}

class _BudgetHistoryScreen extends State<BudgetHistoryScreen> {
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
    // Access to auth and onSignedIn from ChooseLogin
    var uiProvider = Provider.of<UIProvider>(context);
    var budgetProvider = Provider.of<BudgetProvider>(context);
    var userProvider = Provider.of<UserProvider>(context);
    final dateFormat = new DateFormat('MM/dd/yy');

    _deleteHistoryItem(String history, String userDate, num amount) async {
      var newHistory = [];
      for (String historyItem in budgetProvider.selectedBudget.history) {
        newHistory.add(historyItem);
      }
      newHistory.removeAt(newHistory.indexOf(history));
      budgetProvider.selectedBudget.history = newHistory;

      var newUserDate = [];
      for (String userDateItem in budgetProvider.selectedBudget.userDate) {
        newUserDate.add(userDateItem);
      }
      newUserDate.removeAt(newUserDate.indexOf(userDate));
      budgetProvider.selectedBudget.userDate = newUserDate;

      budgetProvider.selectedBudget.spent -= amount;
      budgetProvider.selectedBudget.left += amount;

      budgetProvider.budgetService.updateBudget(
          _database, userProvider.currentUser, budgetProvider.selectedBudget);
    }

    void _showDeleteHistoryDialog(
        Budget budget,
        String formattedAmount,
        num amount,
        String user,
        String date,
        String history,
        String userDate) async {
      showAlertDialog(
          context,
          "Delete $formattedAmount purchase?",
          "This will delete the $formattedAmount purchase made by $user on $date",
          [
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
                    color:
                        uiProvider.isLightTheme ? Colors.black : Colors.white),
              ),
              onPressed: () {
                setState(() {
                  _deleteHistoryItem(history, userDate, amount);
                });
                Navigator.of(context).pop();
              },
            )
          ]);
    }

    Widget _showHistoryList() {
      if (budgetProvider.selectedBudget.history != null &&
          budgetProvider.selectedBudget.history.length > 0) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
                child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView.separated(
                  separatorBuilder: (context, index) => Divider(
                        color: Colors.grey[400],
                      ),
                  physics: BouncingScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: budgetProvider.selectedBudget.history.length,
                  itemBuilder: (BuildContext context, int index) {
                    if ((index) !=
                        budgetProvider.selectedBudget.history.length) {
                      String history =
                          budgetProvider.selectedBudget.history[index];
                      num amount = num.parse(history.split(":")[0]);
                      String note = history.split(":")[1];
                      note = note == "" ? "📝" : note;
                      String userDate =
                          budgetProvider.selectedBudget.userDate[index];
                      // Show either email or display name for user
                      String user = userDate.split(":")[0].contains("@")
                          ? userDate.split(":")[0].split("@")[0]
                          : userDate.split(":")[0];
                      int dateInMilliseconds =
                          num.parse(userDate.split(":")[1]).toInt();
                      String date = dateFormat
                          .format(DateTime.fromMillisecondsSinceEpoch(
                              dateInMilliseconds))
                          .toString();
                      return ListTile(
                        contentPadding: EdgeInsets.only(
                            left: 12.0, right: 12.0, bottom: 5.0),
                        title: Text(
                          currency.format(amount),
                          style: TextStyle(
                              fontSize: 22.0,
                              fontWeight: FontWeight.w500,
                              color: uiProvider.isLightTheme
                                  ? Colors.grey[800]
                                  : Colors.white),
                        ),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 3.0),
                          child: Text(
                            "$note",
                            style: TextStyle(
                                color: uiProvider.isLightTheme
                                    ? Colors.grey[700]
                                    : Colors.grey[400],
                                fontWeight: FontWeight.w500,
                                fontSize: 17.0),
                          ),
                        ),
                        trailing: Text(
                          "$date",
                          style: TextStyle(
                              color: uiProvider.isLightTheme
                                  ? Colors.grey[700]
                                  : Colors.grey[400]),
                        ),
                        onTap: () {
                          showAlertDialog(
                              context,
                              "$note",
                              "${currency.format(amount)} spent by $user on $date",
                              [
                                FlatButton(
                                  child: Text(
                                    'Close',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                FlatButton(
                                  child: Text(
                                    'Edit',
                                    style: TextStyle(
                                        color: uiProvider.isLightTheme
                                            ? Colors.black.withOpacity(0.9)
                                            : Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                EditHistoryScreen(
                                                  history: history,
                                                )));
                                  },
                                ),
                                FlatButton(
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                        color: uiProvider.isLightTheme
                                            ? Colors.black.withOpacity(0.9)
                                            : Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showDeleteHistoryDialog(
                                        budgetProvider.selectedBudget,
                                        currency.format(amount),
                                        amount,
                                        user,
                                        date,
                                        history,
                                        userDate);
                                  },
                                )
                              ]);
                        },
                      );
                    }
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
                "No history",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    color: uiProvider.isLightTheme
                        ? Colors.black.withOpacity(0.5)
                        : Colors.white.withOpacity(0.5)),
              ),
            ],
          ),
        ));
      }
    }

    Widget _showBody() {
      return Container(
          padding: EdgeInsets.all(16.0), child: _showHistoryList());
    }

    // Swipe down to close
    return GestureDetector(
        onPanStart: (details) {
          _initialDragAmount = details.globalPosition.dy;
        },
        onPanUpdate: (details) {
          _finalDragAmount = details.globalPosition.dy - _initialDragAmount;
        },
        onPanEnd: (details) {
          if (_finalDragAmount > 0) {
            FocusScope.of(context).requestFocus(new FocusNode());
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          backgroundColor:
              uiProvider.isLightTheme ? Colors.white : Colors.grey[900],
          appBar: AppBar(
            title: AutoSizeText("History",
                maxLines: 1,
                style: TextStyle(
                    color:
                        uiProvider.isLightTheme ? Colors.black : Colors.white,
                    fontSize: 20)),
            backgroundColor:
                uiProvider.isLightTheme ? Colors.white : Colors.black,
            textTheme: TextTheme(title: TextStyle(color: Colors.black87)),
            iconTheme: IconThemeData(
                color:
                    uiProvider.isLightTheme ? Colors.grey[700] : Colors.white),
            brightness:
                uiProvider.isLightTheme ? Brightness.light : Brightness.dark,
            elevation: 0.0,
          ),
          body: Stack(
            children: <Widget>[
              _showBody(),
              showCircularProgress(context),
            ],
          ),
        ));
  }
}
