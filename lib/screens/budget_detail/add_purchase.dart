import 'dart:ui';
import 'package:Groovy/providers/auth_provider.dart';
import 'package:Groovy/providers/budget_provider.dart';
import 'package:Groovy/providers/ui_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../shared/utilities.dart';

class AddPurchaseScreen extends StatefulWidget {
  AddPurchaseScreen({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AddPurchaseScreen();
}

class _AddPurchaseScreen extends State<AddPurchaseScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final _addPurchaseFormKey = GlobalKey<FormState>();
  var _purchaseAmountTextController = TextEditingController();
  FocusNode _purchaseNoteFocusNode = FocusNode();
  FocusNode _purchaseAmountFocusNode = FocusNode();

  String _amount;
  String _note;

  double _initialDragAmount;
  double _finalDragAmount;

  _onPurchaseAmountChanged() {
    var decimalCount =
        ".".allMatches(_purchaseAmountTextController.text).length;
    if (decimalCount > 1) {
      print("Contains more than one decimal");
      setState(() {
        int decimalIndex = _purchaseAmountTextController.text.lastIndexOf(".");
        _purchaseAmountTextController.text = _purchaseAmountTextController.text
            .replaceFirst(RegExp('.'), '', decimalIndex);
        _purchaseAmountTextController.selection = TextSelection.collapsed(
            offset: _purchaseAmountTextController.text.length);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Listen to text controller changes to control how many decimals are input
    _purchaseAmountTextController.addListener(_onPurchaseAmountChanged);
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    _purchaseNoteFocusNode.dispose();
    _purchaseAmountFocusNode.dispose();
    // Clean up the controller when the widget is removed from the
    // widget tree.
    _purchaseAmountTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access to auth and onSignedIn from ChooseLogin
    var authProvider = Provider.of<AuthProvider>(context);
    var uiProvider = Provider.of<UIProvider>(context);
    var budgetProvider = Provider.of<BudgetProvider>(context);

    // Check if purchase form is valid before adding purchase
    bool _validateAndSavePurchase() {
      final form = _addPurchaseFormKey.currentState;
      if (form.validate()) {
        form.save();
        return true;
      }
      return false;
    }

    _addPurchase() async {
      if (_validateAndSavePurchase()) {
        FirebaseUser user = await authProvider.auth.getCurrentUser();
        var now = DateTime.now().millisecondsSinceEpoch;
        var history = [];
        for (String historyItem in budgetProvider.selectedBudget.history) {
          history.add(historyItem);
        }
        history.add("$_amount:$_note");
        var userDate = [];
        for (String userDateItem in budgetProvider.selectedBudget.userDate) {
          userDate.add(userDateItem);
        }
        userDate.add("${user.displayName}:$now");
        budgetProvider.selectedBudget.spent += num.parse(_amount);
        budgetProvider.selectedBudget.left -= num.parse(_amount);
        budgetProvider.selectedBudget.history = history;
        budgetProvider.selectedBudget.userDate = userDate;
        authProvider.auth
            .updateBudget(_database, budgetProvider.selectedBudget);
        Navigator.of(context).pop();
      }
    }

    Widget _showAmountTextFormField() {
      return Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 15.0, 8.0),
          child: TextFormField(
            style: TextStyle(
                color:
                    uiProvider.isLightTheme ? Colors.grey[900] : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
            cursorColor: uiProvider.isLightTheme ? Colors.black87 : Colors.grey,
            keyboardAppearance:
                uiProvider.isLightTheme ? Brightness.light : Brightness.dark,
            maxLines: 1,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            controller: _purchaseAmountTextController,
            autofocus: true,
            focusNode: _purchaseAmountFocusNode,
            decoration: InputDecoration(
                errorStyle: TextStyle(color: Colors.red[300]),
                hintText: 'Amount',
                hintStyle: TextStyle(color: Colors.grey),
                icon: Icon(
                  Icons.attach_money,
                  color: Colors.grey[400],
                  size: 32,
                ),
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
              FocusScope.of(context).requestFocus(_purchaseNoteFocusNode);
            },
            onSaved: (value) => _amount = value,
          ));
    }

    Widget _showNoteTextFormField() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 15.0, 8.0),
        child: TextFormField(
          style: TextStyle(
              color: uiProvider.isLightTheme ? Colors.grey[900] : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold),
          cursorColor: uiProvider.isLightTheme ? Colors.black87 : Colors.grey,
          keyboardAppearance:
              uiProvider.isLightTheme ? Brightness.light : Brightness.dark,
          maxLines: 1,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.words,
          focusNode: _purchaseNoteFocusNode,
          decoration: InputDecoration(
              errorStyle: TextStyle(color: Colors.red[300]),
              hintText: 'Note',
              hintStyle: TextStyle(color: Colors.grey),
              icon: Icon(
                Icons.note_add,
                color: Colors.grey[400],
                size: 32,
              ),
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
          onFieldSubmitted: (value) {
            _addPurchase();
          },
          onSaved: (value) => _note = value ?? "",
        ),
      );
    }

    Widget _showBody() {
      return Container(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _addPurchaseFormKey,
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                _showAmountTextFormField(),
                _showNoteTextFormField(),
              ],
            ),
          ));
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
            title: Text("Add Purchase",
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
          floatingActionButton: FloatingActionButton(
            elevation: 0,
            backgroundColor: Colors.grey[300],
            foregroundColor: Colors.black87,
            child: Icon(Icons.check),
            onPressed: () {
              if (_purchaseAmountFocusNode.hasFocus) {
                FocusScope.of(context).requestFocus(_purchaseNoteFocusNode);
              } else {
                _addPurchase();
              }
            },
          ),
        ));
  }
}
