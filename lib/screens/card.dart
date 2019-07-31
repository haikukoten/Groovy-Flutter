import 'package:Groovy/models/budget.dart';
import 'package:Groovy/providers/ui_provider.dart';
import 'package:Groovy/screens/shared/utilities.dart';
import 'package:Groovy/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CardScreen extends StatefulWidget {
  CardScreen({Key key, this.budget, this.user, this.auth}) : super(key: key);

  final Budget budget;
  final FirebaseUser user;
  final BaseAuth auth;

  @override
  State<StatefulWidget> createState() => _CardScreen();
}

class _CardScreen extends State<CardScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var uiProvider = Provider.of<UIProvider>(context);

    Widget _showTransactionList() {
      return Center(child: Text("Card"));
    }

    return Stack(
      children: <Widget>[
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(color: Colors.white),
            brightness:
                uiProvider.isLightTheme ? Brightness.light : Brightness.dark,
            elevation: 0.0,
          ),
        ),
        Positioned.fill(
          child: uiProvider.isLightTheme
              ? backgroundWithSolidColor(Color(0xfff2f3fc))
              : backgroundWithSolidColor(Colors.grey[900]),
        ),
        _showTransactionList()
      ],
    );
  }
}
