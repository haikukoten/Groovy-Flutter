import 'dart:ui';
import 'package:Groovy/models/budget.dart';
import 'package:Groovy/providers/auth_provider.dart';
import 'package:Groovy/providers/budget_provider.dart';
import 'package:Groovy/providers/ui_provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../shared/utilities.dart';

class EditBudgetScreen extends StatefulWidget {
  EditBudgetScreen({Key key, this.budget}) : super(key: key);

  final Budget budget;

  @override
  State<StatefulWidget> createState() => _EditBudgetScreen();
}

class _EditBudgetScreen extends State<EditBudgetScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final _editBudgetFormKey = GlobalKey<FormState>();
  TextEditingController _editAmountTextController;
  FocusNode _editNameFocusNode = FocusNode();
  FocusNode _editAmountFocusNode = FocusNode();

  double _initialDragAmount;
  double _finalDragAmount;

  _onEditAmountChanged() {
    var decimalCount = ".".allMatches(_editAmountTextController.text).length;
    if (decimalCount > 1) {
      print("Contains more than one decimal");
      setState(() {
        int decimalIndex = _editAmountTextController.text.lastIndexOf(".");
        _editAmountTextController.text = _editAmountTextController.text
            .replaceFirst(RegExp('.'), '', decimalIndex);
        _editAmountTextController.selection = TextSelection.collapsed(
            offset: _editAmountTextController.text.length);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _editAmountTextController =
        TextEditingController(text: widget.budget.setAmount.toString());
    // Listen to text controller changes to control how many decimals are input
    _editAmountTextController.addListener(_onEditAmountChanged);
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    _editNameFocusNode.dispose();
    _editAmountFocusNode.dispose();
    // Clean up the controller when the widget is removed from the
    // widget tree.
    _editAmountTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access to auth and onSignedIn from ChooseLogin
    var authProvider = Provider.of<AuthProvider>(context);
    var uiProvider = Provider.of<UIProvider>(context);
    var budgetProvider = Provider.of<BudgetProvider>(context);

    // Check if edit form is valid
    bool _validateAndSaveEdit() {
      final form = _editBudgetFormKey.currentState;
      if (form.validate()) {
        form.save();
        return true;
      }
      return false;
    }

    _editBudget() async {
      if (_validateAndSaveEdit()) {
        budgetProvider.selectedBudget.left =
            budgetProvider.selectedBudget.setAmount -
                budgetProvider.selectedBudget.spent;
        authProvider.auth
            .updateBudget(_database, budgetProvider.selectedBudget);
        Navigator.of(context).pop();
      }
    }

    _resetBudget() async {
      budgetProvider.selectedBudget.spent = 0;
      budgetProvider.selectedBudget.left =
          budgetProvider.selectedBudget.setAmount;
      budgetProvider.selectedBudget.history = ["none:none"];
      budgetProvider.selectedBudget.userDate = ["none:none"];
      authProvider.auth.updateBudget(_database, budgetProvider.selectedBudget);
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }

    Widget _showNameTextFormField() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 15.0, 8.0),
        child: TextFormField(
          initialValue: "${budgetProvider.selectedBudget.name}",
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
          autofocus: true,
          focusNode: _editNameFocusNode,
          decoration: InputDecoration(
              errorStyle: TextStyle(color: Colors.red[300]),
              hintText: 'Name',
              hintStyle: TextStyle(color: Colors.grey),
              icon: Icon(
                Icons.gesture,
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
          validator: (value) {
            if (value.isEmpty) {
              return 'Name can\'t be empty';
            }
          },
          onFieldSubmitted: (value) {
            FocusScope.of(context).requestFocus(_editAmountFocusNode);
          },
          onSaved: (value) {
            budgetProvider.selectedBudget.name = value;
          },
        ),
      );
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
            controller: _editAmountTextController,
            focusNode: _editAmountFocusNode,
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
              _editBudget();
            },
            onSaved: (value) {
              setState(() {
                budgetProvider.selectedBudget.setAmount = num.parse(value);
              });
            }),
      );
    }

    Widget _showBody() {
      return Container(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _editBudgetFormKey,
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                _showNameTextFormField(),
                _showAmountTextFormField(),
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
            title: AutoSizeText("Edit ${budgetProvider.selectedBudget.name}",
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
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.restore),
                tooltip: "Reset",
                onPressed: () {
                  showAlertDialog(
                      context,
                      "Reset ${budgetProvider.selectedBudget.name}?",
                      "Resetting ${budgetProvider.selectedBudget.name} will remove all purchase history and set spending back to \$0.00",
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
                            'Reset',
                            style: TextStyle(
                                color: uiProvider.isLightTheme
                                    ? Colors.black
                                    : Colors.white),
                          ),
                          onPressed: () {
                            _resetBudget();
                          },
                        )
                      ]);
                },
              )
            ],
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
              if (_editNameFocusNode.hasFocus) {
                FocusScope.of(context).requestFocus(_editAmountFocusNode);
              } else {
                _editBudget();
              }
            },
          ),
        ));
  }
}
