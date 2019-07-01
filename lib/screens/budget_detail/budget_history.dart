import 'dart:ui';
import 'package:Groovy/models/budget.dart';
import 'package:Groovy/providers/auth_provider.dart';
import 'package:Groovy/providers/budget_provider.dart';
import 'package:Groovy/providers/ui_provider.dart';
import 'package:Groovy/screens/budget_detail/edit_history.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../shared/swipe_actions/swipe_widget.dart';
import '../shared/utilities.dart';

class BudgetHistoryScreen extends StatefulWidget {
  BudgetHistoryScreen({Key key, this.budget}) : super(key: key);

  final Budget budget;

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
    var authProvider = Provider.of<AuthProvider>(context);
    var uiProvider = Provider.of<UIProvider>(context);
    var budgetProvider = Provider.of<BudgetProvider>(context);
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

      authProvider.auth.updateBudget(_database, budgetProvider.selectedBudget);
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
      if (budgetProvider.selectedBudget.history.length > 1) {
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
                    // 'index + 1' is necessary to get around the "none" values in history and userDate.
                    // Again, this is not ideal, but necessary for now to provide backwards compatibility with users of the older app.
                    if ((index + 1) !=
                        budgetProvider.selectedBudget.history.length) {
                      String history =
                          budgetProvider.selectedBudget.history[index + 1];
                      num amount = num.parse(history.split(":")[0]);
                      String note = history.split(":")[1];
                      note = note == "" ? "📝" : note;
                      String userDate =
                          budgetProvider.selectedBudget.userDate[index + 1];
                      String user = userDate.split(":")[0].split("@")[0];
                      int dateInMilliseconds =
                          num.parse(userDate.split(":")[1]).toInt();
                      String date = dateFormat
                          .format(DateTime.fromMillisecondsSinceEpoch(
                              dateInMilliseconds))
                          .toString();
                      return OnSlide(
                        backgroundColor: uiProvider.isLightTheme
                            ? Colors.white
                            : Colors.grey[900],
                        items: <ActionItems>[
                          new ActionItems(
                              icon: new IconButton(
                                padding: EdgeInsets.only(left: 40.0),
                                icon: new Icon(Icons.edit),
                                onPressed: () {},
                                color: uiProvider.isLightTheme
                                    ? Colors.grey[700]
                                    : Colors.grey[300],
                              ),
                              onPress: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => EditHistoryScreen(
                                          history: history,
                                        )));
                              },
                              backgroundColor: Colors.transparent),
                          new ActionItems(
                              icon: new IconButton(
                                padding: EdgeInsets.only(left: 35.0),
                                icon: new Icon(Icons.delete),
                                onPressed: () {},
                                color: uiProvider.isLightTheme
                                    ? Colors.grey[700]
                                    : Colors.grey[300],
                              ),
                              onPress: () {
                                _showDeleteHistoryDialog(
                                    budgetProvider.budgetList[index],
                                    currency.format(amount),
                                    amount,
                                    user,
                                    date,
                                    history,
                                    userDate);
                              },
                              backgroundColor: Colors.transparent),
                        ],
                        child: ListTile(
                          contentPadding: EdgeInsets.only(
                              left: 12.0, right: 12.0, bottom: 5.0),
                          isThreeLine: true,
                          title: Text(
                            currency.format(amount),
                            style: TextStyle(
                                fontSize: 28.0,
                                fontWeight: FontWeight.w700,
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
                                  fontWeight: FontWeight.w700,
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
                                          budgetProvider.budgetList[index],
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
                        ),
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
                    fontSize: 24.0,
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
            title: AutoSizeText("${budgetProvider.selectedBudget.name} History",
                maxLines: 1,
                style: TextStyle(
                    color:
                        uiProvider.isLightTheme ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 20)),
            backgroundColor:
                uiProvider.isLightTheme ? Colors.white : Colors.black,
            textTheme: TextTheme(
                title: TextStyle(
                    color: Colors.black87,
                    fontSize: 20.0,
                    fontWeight: FontWeight.w500)),
            iconTheme: IconThemeData(
                color: uiProvider.isLightTheme ? Colors.black : Colors.white),
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
