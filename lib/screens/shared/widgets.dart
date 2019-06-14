import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:Groovy/models/budget.dart';

Widget showCircularProgress(BuildContext context) {
  var budgetModel = Provider.of<BudgetModel>(context);
  if (budgetModel.isLoading) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: Colors.grey[100].withOpacity(0.8),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
  return Container(
    height: 0.0,
    width: 0.0,
  );
}

onBottom(Widget child) => Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: child,
      ),
    );

Future<void> showAlertDialog(BuildContext context, String title, String message,
    [Function func]) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(message),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32.0))),
        actions: <Widget>[
          FlatButton(
            child: Text(
              'OK',
              style: TextStyle(color: Colors.black),
            ),
            onPressed: () {
              if (func != null) {
                func();
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
