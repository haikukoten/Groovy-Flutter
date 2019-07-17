import 'dart:ui' as ui;
import 'package:Groovy/providers/ui_provider.dart';
import 'package:Groovy/providers/user_provider.dart';
import 'package:Groovy/screens/shared/utilities.dart';
import 'package:Groovy/services/auth_service.dart';
import 'package:Groovy/services/budget_service.dart';
import 'package:Groovy/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen(
      {Key key,
      this.auth,
      this.userService,
      this.budgetService,
      this.user,
      this.onSignedOut})
      : super(key: key);

  final BaseAuth auth;
  final UserService userService;
  final BudgetService budgetService;
  final VoidCallback onSignedOut;
  final FirebaseUser user;

  @override
  State<StatefulWidget> createState() => _ProfileScreen();
}

class _ProfileScreen extends State<ProfileScreen> {
  final _currency = NumberFormat.simpleCurrency();
  SharedPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _initPreferences();
  }

  void _initPreferences() async {
    _preferences = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    var uiProvider = Provider.of<UIProvider>(context);
    var userProvider = Provider.of<UserProvider>(context);

    num totalAmountSpent(UserProvider userProvider) {
      num totalSpent = 0;
      for (int i = 0; i < userProvider.currentUser.budgets.length; i++) {
        totalSpent += userProvider.currentUser.budgets[i].spent;
      }
      return totalSpent;
    }

    num totalAmountLeft(UserProvider userProvider) {
      num totalLeft = 0;
      if (userProvider.currentUser.budgets.length > 0) {
        for (int i = 0; i < userProvider.currentUser.budgets.length; i++) {
          totalLeft += userProvider.currentUser.budgets[i].left;
        }
      }
      return totalLeft;
    }

    Widget _showProfile() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.black),
            accountEmail: widget.user.email != null
                ? Text(
                    widget.user.email,
                    style: TextStyle(color: Colors.white),
                  )
                : SizedBox.shrink(),
            accountName: widget.user.displayName != null
                ? Text(
                    widget.user.displayName,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  )
                : SizedBox.shrink(),
            currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.black,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(45.0),
                  child: widget.user.photoUrl != null
                      ? Image.network(
                          widget.user.photoUrl,
                          fit: BoxFit.cover,
                        )
                      : CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          radius: 29,
                          child: Center(
                            child: Text(
                              widget.user.email.substring(0, 1).toLowerCase(),
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                )),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "budgets",
                  style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w700,
                      color: uiProvider.isLightTheme
                          ? Colors.black87
                          : Colors.grey),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    userProvider.currentUser == null ||
                            userProvider.currentUser.budgets == null
                        ? "0"
                        : "${userProvider.currentUser.budgets.length.toString()}",
                    style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.w700,
                        color: uiProvider.isLightTheme
                            ? Colors.grey[500]
                            : Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.grey[500],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "total spent",
                  style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w700,
                      color: uiProvider.isLightTheme
                          ? Colors.black87
                          : Colors.grey),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    userProvider.currentUser == null ||
                            userProvider.currentUser.budgets == null
                        ? "${_currency.format(0)}"
                        : "${_currency.format(totalAmountSpent(userProvider))}",
                    style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.w700,
                        color: uiProvider.isLightTheme
                            ? Colors.grey[500]
                            : Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.grey[500],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "total left",
                  style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w700,
                      color: uiProvider.isLightTheme
                          ? Colors.black87
                          : Colors.grey),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    userProvider.currentUser == null ||
                            userProvider.currentUser.budgets == null
                        ? "${_currency.format(0)}"
                        : "${_currency.format(totalAmountLeft(userProvider))}",
                    style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.w700,
                        color: uiProvider.isLightTheme
                            ? Colors.grey[500]
                            : Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.grey[500],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "theme",
                  style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w700,
                      color: uiProvider.isLightTheme
                          ? Colors.black87
                          : Colors.grey),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: <Widget>[
                      Padding(
                          padding: const EdgeInsets.only(right: 5.0),
                          child: CircleAvatar(
                            backgroundColor: uiProvider.isLightTheme
                                ? Color(0xffd57eeb)
                                : Colors.transparent,
                            radius: 30,
                            child: FloatingActionButton(
                              tooltip: "Light",
                              mini: true,
                              elevation: 0.0,
                              backgroundColor: Colors.grey[200],
                              child: Icon(
                                Icons.wb_sunny,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  uiProvider.isLightTheme = true;
                                  _preferences.setBool(
                                      "theme", uiProvider.isLightTheme);
                                });
                              },
                            ),
                          )),
                      CircleAvatar(
                        backgroundColor: uiProvider.isLightTheme
                            ? Colors.transparent
                            : Color(0xffd57eeb),
                        radius: 30,
                        child: FloatingActionButton(
                          tooltip: "Dark",
                          mini: true,
                          elevation: 0.0,
                          backgroundColor: Colors.black87,
                          child: Icon(Icons.brightness_2),
                          onPressed: () {
                            setState(() {
                              uiProvider.isLightTheme = false;
                              _preferences.setBool(
                                  "theme", uiProvider.isLightTheme);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      );
    }

    return Stack(
      children: <Widget>[
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(color: Colors.white),
            brightness: Brightness.dark,
            elevation: 0.0,
          ),
        ),
        Positioned.fill(
          child: uiProvider.isLightTheme
              ? backgroundGradientWithColors(Colors.white, Colors.grey[200])
              : backgroundWithSolidColor(Colors.grey[900]),
        ),
        _showProfile()
      ],
    );
  }
}
