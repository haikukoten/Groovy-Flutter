import 'dart:async';
import 'dart:ui';
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
import 'shared/animated/background.dart';
import 'shared/utilities.dart';
import 'package:percent_indicator/percent_indicator.dart';

class BudgetDetailScreen extends StatefulWidget {
  BudgetDetailScreen({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new _BudgetDetailScreen();
}

class _BudgetDetailScreen extends State<BudgetDetailScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final currency = NumberFormat.simpleCurrency();

  final _addPurchaseFormKey = GlobalKey<FormState>();
  var amountTextController = TextEditingController();

  String _amount;
  Budget _budget;
  double initialDragAmount;
  double finalDragAmount;

  @override
  void initState() {
    super.initState();
    // Listen to amount text controller changes to control how many decimals are input
    amountTextController.addListener(_onAmountChanged);
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

  @override
  Widget build(BuildContext context) {
    var authProvider = Provider.of<AuthProvider>(context);
    var uiProvider = Provider.of<UIProvider>(context);
    var budgetProvider = Provider.of<BudgetProvider>(context);
    _budget = budgetProvider.selectedBudget;

    // Check if form is valid before adding purchase
    bool _validateAndSave() {
      final form = _addPurchaseFormKey.currentState;
      if (form.validate()) {
        form.save();
        return true;
      }
      return false;
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
            authProvider.auth.deleteBudget(_database, budget);
            print("Delete ${budget.key} successful");
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
          percent: (_budget.spent.floorToDouble() /
              _budget.setAmount.floorToDouble()),
          animationDuration: 800,
          center: Text(
            "${((_budget.spent / _budget.setAmount * 100).floor())}%",
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
            "${currency.format(_budget.spent)}",
            style: TextStyle(
                color: uiProvider.isLightTheme
                    ? Colors.white.withOpacity(0.9)
                    : Colors.black.withOpacity(0.6),
                fontSize: 38,
                fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text("spent of ${currency.format(_budget.setAmount)}",
                style: TextStyle(
                    color: uiProvider.isLightTheme
                        ? Colors.white.withOpacity(0.9)
                        : Colors.black.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w400)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 45.0),
            child: Text("${currency.format(_budget.left)}",
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

    _addPurchase() {
      if (_validateAndSave()) {
        _budget.spent += num.parse(_amount);
        _budget.left -= num.parse(_amount);
        print(_budget.spent);
        authProvider.auth.updateBudget(_database, _budget);
        Navigator.of(context).pop();
      }
    }

    _showAddPurchaseDialog() {
      amountTextController.text = "";
      showInputDialog(
          context,
          uiProvider.isLightTheme ? Colors.white : Colors.black,
          Text(
            "Add Purchase",
            style: TextStyle(
                color:
                    uiProvider.isLightTheme ? Colors.black : Colors.grey[300],
                fontWeight: FontWeight.w500),
          ),
          "",
          FlatButton(
              child: Text(
                'Add',
                style: TextStyle(
                    color:
                        uiProvider.isLightTheme ? Colors.black : Colors.white),
              ),
              onPressed: () async {
                _addPurchase();
              }),
          Form(
            key: _addPurchaseFormKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  style: TextStyle(
                      color: uiProvider.isLightTheme
                          ? Colors.grey[900]
                          : Colors.white),
                  cursorColor:
                      uiProvider.isLightTheme ? Colors.black87 : Colors.grey,
                  keyboardAppearance: uiProvider.isLightTheme
                      ? Brightness.light
                      : Brightness.dark,
                  autofocus: true,
                  maxLines: 1,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                    BlacklistingTextInputFormatter(RegExp('[\\,|\\-|\\ ]')),
                  ],
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Amount can\'t be empty';
                    }
                  },
                  onFieldSubmitted: (value) {
                    _addPurchase();
                  },
                  onSaved: (value) => _amount = value,
                ),
              ],
            ),
          ));
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
                  padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
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
                        print("History");
                      },
                    ),
                  )),
              Divider(
                color: Colors.grey[500],
              ),
              Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
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
                        print("Edit");
                      },
                    ),
                  )),
              Divider(
                color: Colors.grey[500],
              ),
              Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
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
                                  ? Colors.black
                                  : Colors.white)),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteBudget(_budget);
                      },
                    ),
                  ))
            ],
          ));
    }

    return GestureDetector(
        onPanStart: (details) {
          initialDragAmount = details.globalPosition.dy;
        },
        onPanUpdate: (details) {
          finalDragAmount = details.globalPosition.dy - initialDragAmount;
        },
        onPanEnd: (details) {
          if (finalDragAmount < 0) {
            _showAddPurchaseDialog();
          }

          if (finalDragAmount > 0) {
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
                title: Text("${_budget.name}"),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.person_add),
                    onPressed: () {
                      print("share");
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.more_horiz),
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
                  _showAddPurchaseDialog();
                },
              ),
            ),
          ],
        ));
  }
}
