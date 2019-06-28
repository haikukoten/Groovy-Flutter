import 'dart:ui';
import 'package:Groovy/providers/auth_provider.dart';
import 'package:Groovy/providers/ui_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'shared/utilities.dart';

class CreateBudgetScreen extends StatefulWidget {
  CreateBudgetScreen({Key key, this.user}) : super(key: key);

  final FirebaseUser user;

  @override
  State<StatefulWidget> createState() => _CreateBudgetScreen();
}

class _CreateBudgetScreen extends State<CreateBudgetScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  // Create budget key, controllers, and focus node
  final _createBudgetFormKey = GlobalKey<FormState>();
  TextEditingController _budgetAmountTextController = TextEditingController();
  FocusNode _budgetAmountFocusNode = FocusNode();

  String _name;
  String _amount;

  double _initialDragAmount;
  double _finalDragAmount;

  _onAmountChanged() {
    var decimalCount = ".".allMatches(_budgetAmountTextController.text).length;
    if (decimalCount > 1) {
      print("Contains more than one decimal");
      setState(() {
        int decimalIndex = _budgetAmountTextController.text.lastIndexOf(".");
        _budgetAmountTextController.text = _budgetAmountTextController.text
            .replaceFirst(RegExp('.'), '', decimalIndex);
        _budgetAmountTextController.selection = TextSelection.collapsed(
            offset: _budgetAmountTextController.text.length);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // Listen to text controller changes to control how many decimals are input
    _budgetAmountTextController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    _budgetAmountFocusNode.dispose();
    // Clean up the controller when the widget is removed from the
    // widget tree.
    _budgetAmountTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access to auth and onSignedIn from ChooseLogin
    var authProvider = Provider.of<AuthProvider>(context);
    var uiProvider = Provider.of<UIProvider>(context);

    // Check if edit form is valid before creating budget
    bool _validateAndSaveCreateBudget() {
      final form = _createBudgetFormKey.currentState;
      if (form.validate()) {
        form.save();
        return true;
      }
      return false;
    }

    void _createBudget() {
      if (_validateAndSaveCreateBudget()) {
        authProvider.auth.createBudget(_database, widget.user, _name, _amount);
        Navigator.of(context).pop();
      }
    }

    Widget _showNameTextFormField() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 15.0, 8.0),
        child: TextFormField(
          initialValue: "",
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
            FocusScope.of(context).requestFocus(_budgetAmountFocusNode);
          },
          onSaved: (value) => _name = value,
        ),
      );
    }

    Widget _showAmountTextFormField() {
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
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          controller: _budgetAmountTextController,
          focusNode: _budgetAmountFocusNode,
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
            _createBudget();
          },
          onSaved: (value) => _amount = value,
        ),
      );
    }

    Widget _showBody() {
      return Container(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _createBudgetFormKey,
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                _showNameTextFormField(),
                _showAmountTextFormField(),
              ],
            ),
          ));
    }

    // Swipe up to show 'Create Budget' dialog
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
          title: Text(
            "Create Budget",
            style: TextStyle(
                color: uiProvider.isLightTheme ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20),
          ),
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
            _createBudget();
          },
        ),
      ),
    );
  }
}
