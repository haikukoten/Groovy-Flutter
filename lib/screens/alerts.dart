import 'dart:convert';

import 'package:Groovy/models/budget.dart';
import 'package:Groovy/models/not_accepted_budget.dart';
import 'package:Groovy/models/user.dart';
import 'package:Groovy/providers/ui_provider.dart';
import 'package:Groovy/providers/user_provider.dart';
import 'package:Groovy/screens/shared/utilities.dart';
import 'package:Groovy/services/auth_service.dart';
import 'package:Groovy/services/user_service.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

class AlertScreen extends StatefulWidget {
  AlertScreen(
      {Key key, this.user, this.currentUser, this.userService, this.auth})
      : super(key: key);

  final FirebaseUser user;
  final User currentUser;
  final UserService userService;
  final BaseAuth auth;

  @override
  State<StatefulWidget> createState() => _AlertScreen();
}

class _AlertScreen extends State<AlertScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  List<User> _users = [];
  List<dynamic> _alerts = [];

  @override
  void initState() {
    super.initState();
    _getAlerts();
  }

  _getAlerts() {
    if (widget.currentUser.notAcceptedBudgets != null) {
      widget.currentUser.notAcceptedBudgets.forEach((budget) async {
        var fromEmail = budget.from.split("<<<===:::===>>>")[1];
        User user =
            await widget.userService.getUserFromEmail(_database, fromEmail);
        setState(() {
          // create 2 dimensional list that contains [[user, budget]]
          _alerts.add([user, budget]);
        });
      });
    }
  }

  _removeAlert(User user, NotAcceptedBudget notAcceptedBudget) {
    _alerts.removeWhere(
        (alert) => alert[0] == user && alert[1] == notAcceptedBudget);
  }

  _removeNotAcceptedBudgetFromCurrentUser(NotAcceptedBudget notAcceptedBudget) {
    var userProvider = Provider.of<UserProvider>(context);
    User newCurrentUser = userProvider.currentUser;
    newCurrentUser.notAcceptedBudgets
        .removeWhere((budget) => budget == notAcceptedBudget);
    userProvider.currentUser = newCurrentUser;
  }

  void _showAcceptOrDeclineModal(
      User user, NotAcceptedBudget notAcceptedBudget) {
    var uiProvider = Provider.of<UIProvider>(context);
    var userProvider = Provider.of<UserProvider>(context);
    modalBottomSheetMenu(
        context,
        uiProvider,
        Column(
          children: <Widget>[
            Padding(
                padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 5.0),
                child: SizedBox(
                  height: 55.0,
                  width: double.infinity,
                  child: RaisedButton(
                    elevation: 0.0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0)),
                    color: Colors.transparent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(right: 18.0),
                          child: Icon(
                            Icons.check,
                            color: uiProvider.isLightTheme
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                        Text('Accept',
                            style: TextStyle(
                                fontSize: 18.0,
                                color: uiProvider.isLightTheme
                                    ? Colors.black
                                    : Colors.white))
                      ],
                    ),
                    onPressed: () {
                      Budget budget =
                          Budget.fromNotAcceptedBudget(notAcceptedBudget);

                      setState(() {
                        _removeAlert(user, notAcceptedBudget);
                        _removeNotAcceptedBudgetFromCurrentUser(
                            notAcceptedBudget);
                        userProvider.currentUser.budgets.add(budget);
                        widget.userService
                            .updateUser(_database, userProvider.currentUser);
                      });
                      showSimpleNotification(
                          Text(
                            "New budget!",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: uiProvider.isLightTheme
                                    ? Colors.black
                                    : Colors.white),
                          ),
                          background: uiProvider.isLightTheme
                              ? Colors.white
                              : Colors.black,
                          autoDismiss: true,
                          leading: CircleAvatar(
                            backgroundColor: Color(0xffeae7ec),
                            child: AutoSizeText(
                              budget.name[0],
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          elevation: 8,
                          subtitle: Text(
                            " ${budget.name}",
                            style: TextStyle(
                                color: uiProvider.isLightTheme
                                    ? Colors.grey[800]
                                    : Colors.white),
                          ),
                          trailing: Text("🎉"),
                          contentPadding: EdgeInsets.fromLTRB(16, 8, 16, 8));
                      HapticFeedback.lightImpact();
                      HapticFeedback.vibrate();
                      Navigator.pop(context);
                    },
                  ),
                )),
            Divider(
              color: Colors.grey[500],
            ),
            Padding(
                padding: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
                child: SizedBox(
                  height: 55.0,
                  width: double.infinity,
                  child: RaisedButton(
                    elevation: 0.0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0)),
                    color: Colors.transparent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(right: 18.0),
                          child: Icon(
                            Icons.close,
                            color: uiProvider.isLightTheme
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                        Text('Decline',
                            style: TextStyle(
                                fontSize: 18.0,
                                color: uiProvider.isLightTheme
                                    ? Colors.black
                                    : Colors.white))
                      ],
                    ),
                    onPressed: () {
                      setState(() {
                        _removeAlert(user, notAcceptedBudget);
                        _removeNotAcceptedBudgetFromCurrentUser(
                            notAcceptedBudget);
                        widget.userService
                            .updateUser(_database, userProvider.currentUser);
                      });
                      Navigator.pop(context);
                    },
                  ),
                ))
          ],
        ),
        160.0);
  }

  @override
  Widget build(BuildContext context) {
    var uiProvider = Provider.of<UIProvider>(context);

    Widget _showAlertList() {
      if (_alerts != null && _alerts.length > 0) {
        var notAcceptedSharedBudgets = [];
        _alerts.forEach((alert) {
          notAcceptedSharedBudgets.add(alert[1]);
        });
        // alphabetize notAcceptedSharedBudgets
        notAcceptedSharedBudgets.sort((a, b) => a.name.compareTo(b.name));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
                child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView.builder(
                  physics: BouncingScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _alerts.length,
                  itemBuilder: (BuildContext context, int index) {
                    User user = _alerts[index][0];
                    NotAcceptedBudget notAcceptedBudget = _alerts[index][1];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Container(
                        decoration: BoxDecoration(
                            color: uiProvider.isLightTheme
                                ? Colors.white
                                : Colors.grey[800],
                            boxShadow: [
                              BoxShadow(
                                  color: uiProvider.isLightTheme
                                      ? Colors.grey[200]
                                      : Colors.black.withOpacity(0.5),
                                  offset: Offset(5.0, 5.0),
                                  blurRadius: 15,
                                  spreadRadius: 5),
                            ],
                            borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.fromLTRB(0, 12, 0, 12),
                        child: ListTile(
                          title: AutoSizeText(
                            "${user.name} shared ${notAcceptedBudget.name} with you",
                            maxLines: 1,
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: uiProvider.isLightTheme
                                    ? Colors.black
                                    : Colors.white),
                          ),
                          leading: user != null && user.photo != null
                              ? CircleAvatar(
                                  backgroundColor: uiProvider.isLightTheme
                                      ? Colors.grey[200]
                                      : Colors.grey[600],
                                  child: Container(
                                    decoration:
                                        BoxDecoration(shape: BoxShape.circle),
                                    width: double.infinity,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(180),
                                      child: FadeInImage(
                                        fit: BoxFit.cover,
                                        placeholder:
                                            MemoryImage(kTransparentImage),
                                        image: MemoryImage(
                                            base64Decode(user.photo)),
                                      ),
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  backgroundColor: Color(0xffeae7ec),
                                  child: AutoSizeText(
                                    "${user.name[0]}${user.name[1]}",
                                    style: TextStyle(
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 24),
                                  ),
                                ),
                          subtitle: AutoSizeText(
                            "Tap to accept or decline",
                            style: TextStyle(
                                color: uiProvider.isLightTheme
                                    ? Colors.grey[800]
                                    : Colors.grey[400]),
                          ),
                          onTap: () {
                            // show accept or decline modal for notAcceptedBudget
                            _showAcceptOrDeclineModal(user, notAcceptedBudget);
                          },
                        ),
                      ),
                    );
                  }),
            ))
          ],
        );
      } else {
        return Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(bottom: 100.0),
          child: Center(
            child: Text(
              "No alerts",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                  color: uiProvider.isLightTheme
                      ? Colors.black.withOpacity(0.6)
                      : Colors.white.withOpacity(0.6)),
            ),
          ),
        );
      }
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
                      "Alerts",
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: uiProvider.isLightTheme
                              ? Colors.grey[900]
                              : Colors.white),
                    )),
              ),
            ),
            Expanded(flex: 1, child: _showAlertList())
          ]),
        ),
      ],
    );
  }
}
