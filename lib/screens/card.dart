import 'package:Groovy/models/budget.dart';
import 'package:Groovy/models/user.dart';
import 'package:Groovy/providers/ui_provider.dart';
import 'package:Groovy/screens/shared/utilities.dart';
import 'package:Groovy/services/auth_service.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gradient_widgets/gradient_widgets.dart';
import 'package:provider/provider.dart';

class CardScreen extends StatefulWidget {
  CardScreen({Key key, this.user, this.currentUser, this.auth})
      : super(key: key);

  final BaseAuth auth;
  final FirebaseUser user;
  final User currentUser;

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

    Widget _showIcon() {
      return Container(
        child: Center(
          child: Icon(
            Icons.account_balance,
            color: Colors.grey[400],
            size: 75,
          ),
        ),
      );
    }

    Widget _showHelpText() {
      return Padding(
        padding: const EdgeInsets.all(18.0),
        child: Container(
          child: Center(
            child: AutoSizeText(
              "Connect your bank account\nto easily track transactions",
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      );
    }

    Widget _showAcceptButton() {
      return Padding(
          padding: EdgeInsets.fromLTRB(55.0, 15.0, 55.0, 0.0),
          child: SizedBox(
            height: 55.0,
            width: double.infinity,
            child: RaisedButton(
              elevation: 0.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0)),
              color: Colors.blue[600],
              child: Text('Connect',
                  style: TextStyle(fontSize: 20.0, color: Colors.white)),
              onPressed: () {
                //
              },
            ),
          ));
    }

    _showTransactionList() {
      return Center(
        child: Text("Transactions"),
      );
    }

    _showBankLogin() {
      return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
                flex: 7,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[_showIcon(), _showHelpText()],
                )),
            Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[_showAcceptButton()],
                )),
          ]);
    }

    Widget _determineUserStatus() {
      return widget.currentUser.isPaid
          ? _showTransactionList()
          : _showBankLogin();
    }

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: uiProvider.isLightTheme
              ? backgroundWithSolidColor(Color(0xfff2f3fc))
              : backgroundWithSolidColor(Colors.grey[900]),
        ),
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(color: Colors.white),
            brightness:
                uiProvider.isLightTheme ? Brightness.light : Brightness.dark,
            elevation: 0.0,
          ),
          body: Column(children: [
            Expanded(
              flex: 0,
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 0, 22),
                    child: AutoSizeText(
                      "Card",
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: uiProvider.isLightTheme
                              ? Colors.grey[900]
                              : Colors.white),
                    )),
              ),
            ),
            Expanded(flex: 1, child: _determineUserStatus())
          ]),
        ),
      ],
    );
  }
}
