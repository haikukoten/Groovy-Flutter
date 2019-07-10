import 'dart:ui';
import 'package:Groovy/providers/auth_provider.dart';
import 'package:Groovy/providers/budget_provider.dart';
import 'package:Groovy/providers/ui_provider.dart';
import 'package:Groovy/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../shared/utilities.dart';

class EditHistoryScreen extends StatefulWidget {
  EditHistoryScreen({Key key, this.history, this.user}) : super(key: key);

  final String history;
  final FirebaseUser user;

  @override
  State<StatefulWidget> createState() => _EditHistoryScreen();
}

class _EditHistoryScreen extends State<EditHistoryScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final _editHistoryFormKey = GlobalKey<FormState>();
  TextEditingController _editHistoryAmountController;
  FocusNode _editHistoryAmountFocusNode = FocusNode();
  FocusNode _editHistoryNoteFocusNode = FocusNode();

  String _amount;
  String _note;

  _onEditHistoryAmountChanged() {
    var decimalCount = ".".allMatches(_editHistoryAmountController.text).length;
    if (decimalCount > 1) {
      print("Contains more than one decimal");
      setState(() {
        int decimalIndex = _editHistoryAmountController.text.lastIndexOf(".");
        _editHistoryAmountController.text = _editHistoryAmountController.text
            .replaceFirst(RegExp('.'), '', decimalIndex);
        _editHistoryAmountController.selection = TextSelection.collapsed(
            offset: _editHistoryAmountController.text.length);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _amount = widget.history.split(":")[0];
    _note = widget.history.split(":")[1];

    _editHistoryAmountController = TextEditingController(text: _amount);
    // Listen to text controller changes to control how many decimals are input
    _editHistoryAmountController.addListener(_onEditHistoryAmountChanged);
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    _editHistoryAmountFocusNode.dispose();
    _editHistoryNoteFocusNode.dispose();
    // Clean up the controller when the widget is removed from the
    // widget tree.
    _editHistoryAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access to auth and onSignedIn from ChooseLogin
    var authProvider = Provider.of<AuthProvider>(context);
    var uiProvider = Provider.of<UIProvider>(context);
    var budgetProvider = Provider.of<BudgetProvider>(context);
    var userProvider = Provider.of<UserProvider>(context);

    // Check if edit form is valid
    bool _validateAndSaveEditHistory() {
      final form = _editHistoryFormKey.currentState;
      if (form.validate()) {
        form.save();
        return true;
      }
      return false;
    }

    _editHistory() async {
      if (_validateAndSaveEditHistory()) {
        int historyIndex =
            budgetProvider.selectedBudget.history.indexOf(widget.history);

        var newHistory = [];
        for (String historyItem in budgetProvider.selectedBudget.history) {
          newHistory.add(historyItem);
        }

        newHistory[historyIndex] = "$_amount:$_note";
        budgetProvider.selectedBudget.history = newHistory;

        num newAmountSpent = 0;

        for (String newHistoryItem in newHistory) {
          // skip "none:none" value for recalculating spent
          if (newHistoryItem.split(":")[0] != "none") {
            num amount = num.parse(newHistoryItem.split(":")[0]);
            newAmountSpent += amount;
          }
        }

        budgetProvider.selectedBudget.spent = newAmountSpent;
        budgetProvider.selectedBudget.left =
            budgetProvider.selectedBudget.setAmount - newAmountSpent;

        authProvider.auth.updateBudget(
            _database, userProvider.currentUser, budgetProvider.selectedBudget);
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
            controller: _editHistoryAmountController,
            focusNode: _editHistoryAmountFocusNode,
            autofocus: true,
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
              FocusScope.of(context).requestFocus(_editHistoryNoteFocusNode);
            },
            onSaved: (value) {
              setState(() {
                _amount = value;
              });
            }),
      );
    }

    Widget _showNoteTextFormField() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 15.0, 8.0),
        child: TextFormField(
          initialValue: "$_note",
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
          focusNode: _editHistoryNoteFocusNode,
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
            _editHistory();
          },
          onSaved: (value) {
            setState(() {
              _note = value;
            });
          },
        ),
      );
    }

    Widget _showBody() {
      return Container(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _editHistoryFormKey,
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
    return Scaffold(
      backgroundColor:
          uiProvider.isLightTheme ? Colors.white : Colors.grey[900],
      appBar: AppBar(
        title: Text("Edit Purchase",
            style: TextStyle(
                color: uiProvider.isLightTheme ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20)),
        backgroundColor: uiProvider.isLightTheme ? Colors.white : Colors.black,
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
          if (_editHistoryAmountFocusNode.hasFocus) {
            FocusScope.of(context).requestFocus(_editHistoryNoteFocusNode);
          } else {
            _editHistory();
          }
        },
      ),
    );
  }
}
