import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:Groovy/models/user.dart';
import 'package:Groovy/providers/auth_provider.dart';
import 'package:Groovy/providers/budget_provider.dart';
import 'package:Groovy/providers/ui_provider.dart';
import 'package:Groovy/providers/user_provider.dart';
import 'package:Groovy/screens/budget_detail/budget_detail.dart';
import 'package:Groovy/screens/budget_detail/share_budget.dart';
import 'package:Groovy/screens/budget_list/create_budget.dart';
import 'package:Groovy/screens/request_notifications.dart';
import 'package:Groovy/services/budget_service.dart';
import 'package:Groovy/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import "package:intl/intl.dart";
import 'package:flutter/material.dart';
import 'package:Groovy/services/auth_service.dart';
import 'package:Groovy/models/budget.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import '../budget_detail/edit_budget.dart';
import '../shared/swipe_actions/swipe_widget.dart';
import '../shared/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auto_size_text/auto_size_text.dart';

class BudgetListScreen extends StatefulWidget {
  BudgetListScreen(
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
  State<StatefulWidget> createState() => new _BudgetListScreen();
}

class _BudgetListScreen extends State<BudgetListScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  Query _userQuery;
  final _currency = NumberFormat.simpleCurrency();
  SharedPreferences _preferences;

  StreamSubscription<Event> _onUserAddedSubscription;
  StreamSubscription<Event> _onUserChangedSubscription;

  double _initialDragAmountY = 0;
  double _finalDragAmountY = 0;

  @override
  void initState() {
    super.initState();

    _database.setPersistenceEnabled(true);
    _database.setPersistenceCacheSizeBytes(10000000); // 10MB cache

    _getSavedPreferences();

    _userQuery = _database
        .reference()
        .child("users")
        .orderByChild("email")
        .equalTo(widget.user.email);

    _onUserAddedSubscription = _userQuery.onChildAdded.listen(_onUserAdded);
    _onUserChangedSubscription =
        _userQuery.onChildChanged.listen(_onUserChanged);

    // Handle FCM
    fcmListeners();
  }

  @override
  void dispose() {
    _onUserAddedSubscription.cancel();
    _onUserChangedSubscription.cancel();
    super.dispose();
  }

  void _getSavedPreferences() async {
    _preferences = await SharedPreferences.getInstance();
    var uiProvider = Provider.of<UIProvider>(context);
    uiProvider.isLightTheme = _preferences.getBool("theme") ?? true;
  }

  void fcmListeners() {
    if (Platform.isIOS) _iOSRequestNotificationPermission();

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        _showSimpleNotificationForMessage(message);
      },
      onResume: (Map<String, dynamic> message) async {
        _showSimpleNotificationForMessage(message);
      },
      onLaunch: (Map<String, dynamic> message) async {
        _showSimpleNotificationForMessage(message);
      },
    );
  }

  void _iOSRequestNotificationPermission() async {
    _preferences = await SharedPreferences.getInstance();
    var notificationPermissions =
        _preferences.getBool("notifications") ?? false;

    // If user has not chosen permission yet (first launch), give them option
    if (notificationPermissions == false) {
      Navigator.of(context).push(CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) => RequestNotificationsScreen()));
    }
  }

  void _showSimpleNotificationForMessage(Map<String, dynamic> message) {
    var data = message["data"];
    var from = data["nameOfSentFrom"];
    var uiProvider = Provider.of<UIProvider>(context);
    showSimpleNotification(
        Text(
          "$from shared a budget with you",
          style: TextStyle(
              color: uiProvider.isLightTheme ? Colors.black : Colors.white),
        ),
        background: uiProvider.isLightTheme ? Colors.white : Colors.black);
  }

  _onUserAdded(Event event) {
    var userProvider = Provider.of<UserProvider>(context);
    setState(() {
      userProvider.currentUser = User.fromSnapshot(event.snapshot);
    });
  }

  _onUserChanged(Event event) {
    var userProvider = Provider.of<UserProvider>(context);
    setState(() {
      userProvider.currentUser = User.fromSnapshot(event.snapshot);
    });
  }

  @override
  Widget build(BuildContext context) {
    var uiProvider = Provider.of<UIProvider>(context);
    var budgetProvider = Provider.of<BudgetProvider>(context);
    var userProvider = Provider.of<UserProvider>(context);
    var authProvider = Provider.of<AuthProvider>(context);

    void _deleteBudget(Budget budget) async {
      showAlertDialog(context, "Delete ${budget.name}",
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
          onPressed: () async {
            if (budget.isShared) {
              var sharedWith = [];
              budget.sharedWith.forEach((email) {
                sharedWith.add(email);
              });
              // remove user from budget shared with
              sharedWith.remove(userProvider.currentUser.email);
              budget.sharedWith = sharedWith;

              // if shared with is only 1 item, then isShared is false
              if (sharedWith.length == 1) {
                budget.isShared = false;
              }

              // Update all users on sharedWith
              await widget.userService
                  .updateSharedUsers(_database, budget, budgetProvider);
            }

            // Delete budget for current user
            widget.budgetService
                .deleteBudget(_database, userProvider.currentUser, budget);
            print("Delete ${budget.key} successful");
            Navigator.of(context).pop();
          },
        )
      ]);
    }

    Widget _showBudgetList() {
      if (userProvider.currentUser != null &&
          userProvider.currentUser.budgets != null &&
          userProvider.currentUser.budgets.length > 0) {
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
                  itemCount: userProvider.currentUser.budgets.length,
                  itemBuilder: (BuildContext context, int index) {
                    String name = userProvider.currentUser.budgets[index].name;
                    num spent = userProvider.currentUser.budgets[index].spent;
                    num setAmount =
                        userProvider.currentUser.budgets[index].setAmount;
                    return OnSlide(
                        items: <ActionItems>[
                          new ActionItems(
                              icon: new IconButton(
                                icon: new Icon(Icons.edit),
                                onPressed: () {},
                                color: Colors.white,
                              ),
                              onPress: () {
                                budgetProvider.selectedBudget =
                                    userProvider.currentUser.budgets[index];
                                userProvider.userService = widget.userService;
                                budgetProvider.budgetService =
                                    widget.budgetService;
                                Navigator.of(context).push(CupertinoPageRoute(
                                    fullscreenDialog: true,
                                    builder: (context) => EditBudgetScreen(
                                          budget: userProvider
                                              .currentUser.budgets[index],
                                          user: widget.user,
                                        )));
                              },
                              backgroundColor: Colors.transparent),
                          new ActionItems(
                              icon: new IconButton(
                                icon: new Icon(Icons.account_circle),
                                onPressed: () {},
                                color: Colors.white,
                              ),
                              onPress: () {
                                budgetProvider.selectedBudget =
                                    userProvider.currentUser.budgets[index];
                                userProvider.userService = widget.userService;
                                budgetProvider.budgetService =
                                    widget.budgetService;
                                Navigator.of(context).push(CupertinoPageRoute(
                                    fullscreenDialog: true,
                                    builder: (context) => ShareBudgetScreen(
                                          budget: budgetProvider.selectedBudget,
                                          user: widget.user,
                                          auth: widget.auth,
                                        )));
                              },
                              backgroundColor: Colors.transparent),
                          new ActionItems(
                              icon: new IconButton(
                                icon: new Icon(Icons.delete),
                                onPressed: () {},
                                color: Colors.white,
                              ),
                              onPress: () {
                                _deleteBudget(
                                    userProvider.currentUser.budgets[index]);
                              },
                              backgroundColor: Colors.transparent),
                        ],
                        child: Container(
                          height: 120,
                          padding: EdgeInsets.fromLTRB(32, 0, 32, 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                          child: new ClipRect(
                            child: new BackdropFilter(
                              filter: new ImageFilter.blur(
                                sigmaX: 15.0,
                                sigmaY: 15.0,
                              ),
                              child: new Container(
                                  decoration: new BoxDecoration(
                                      borderRadius: BorderRadius.circular(32.0),
                                      color: uiProvider.isLightTheme
                                          ? Colors.white.withOpacity(0.5)
                                          : Colors.black.withOpacity(0.5)),
                                  child: Container(
                                    child: Card(
                                        borderOnForeground: false,
                                        elevation: 0,
                                        color: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(32.0))),
                                        child: InkWell(
                                            splashColor: uiProvider.isLightTheme
                                                ? Colors.grey[300]
                                                    .withOpacity(0.5)
                                                : Colors.grey[100]
                                                    .withOpacity(0.1),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(32.0)),
                                            onTap: () {
                                              var budgetProvider =
                                                  Provider.of<BudgetProvider>(
                                                      context);
                                              budgetProvider.selectedBudget =
                                                  userProvider.currentUser
                                                      .budgets[index];
                                              print(
                                                  "Selected budget ==> ${budgetProvider.selectedBudget}");
                                              var authProvider =
                                                  Provider.of<AuthProvider>(
                                                      context);
                                              authProvider.auth = widget.auth;
                                              userProvider.userService =
                                                  widget.userService;
                                              budgetProvider.budgetService =
                                                  widget.budgetService;
                                              Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          BudgetDetailScreen(
                                                            user: widget.user,
                                                            auth: widget.auth,
                                                          )));
                                            },
                                            child: Stack(
                                              children: <Widget>[
                                                ListTile(
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          top: 11.0,
                                                          left: 30.0),
                                                  title: AutoSizeText(
                                                    name,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                        fontSize: 28.0,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: uiProvider
                                                                .isLightTheme
                                                            ? Colors.grey[800]
                                                            : Colors.white),
                                                  ),
                                                  subtitle: Padding(
                                                    padding: EdgeInsets.only(
                                                        top: 5.0),
                                                    child: AutoSizeText(
                                                      "${_currency.format(spent)} of ${_currency.format(setAmount)}",
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                          color: uiProvider
                                                                  .isLightTheme
                                                              ? Colors.grey[700]
                                                              : Colors
                                                                  .grey[400],
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 17.0),
                                                    ),
                                                  ),
                                                  trailing: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 18.0),
                                                    child: userProvider
                                                            .currentUser
                                                            .budgets[index]
                                                            .isShared
                                                        ? Icon(
                                                            Icons
                                                                .account_circle,
                                                            color: uiProvider
                                                                    .isLightTheme
                                                                ? Colors
                                                                    .grey[700]
                                                                    .withOpacity(
                                                                        0.4)
                                                                : Colors
                                                                    .grey[100]
                                                                    .withOpacity(
                                                                        0.4),
                                                          )
                                                        : null,
                                                  ),
                                                ),
                                              ],
                                            ))),
                                  )),
                            ),
                          ),
                        ));
                  }),
            ))
          ],
        );
      } else {
        return Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(bottom: 100.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "No budgets",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                    color: uiProvider.isLightTheme
                        ? Colors.black.withOpacity(0.6)
                        : Colors.white.withOpacity(0.6)),
              ),
              Text(
                "Swipe up to get started",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18.0,
                    color: uiProvider.isLightTheme
                        ? Colors.black.withOpacity(0.6)
                        : Colors.white.withOpacity(0.6)),
              ),
            ],
          ),
        );
      }
    }

    return GestureDetector(
        onPanStart: (details) {
          _initialDragAmountY = details.globalPosition.dy;
        },
        onPanUpdate: (details) {
          _finalDragAmountY = details.globalPosition.dy - _initialDragAmountY;
        },
        onPanEnd: (details) {
          if (_finalDragAmountY < -60) {
            authProvider.auth = widget.auth;
            userProvider.userService = widget.userService;
            budgetProvider.budgetService = widget.budgetService;
            Navigator.of(context).push(CupertinoPageRoute(
                fullscreenDialog: true,
                builder: (context) => CreateBudgetScreen(
                      user: userProvider.currentUser,
                    )));
          }
        },
        child: Stack(children: <Widget>[
          Positioned.fill(
            child: uiProvider.isLightTheme
                ? backgroundGradientWithColors(Colors.white, Colors.grey[200])
                : backgroundWithSolidColor(Colors.grey[900]),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              iconTheme: IconThemeData(color: Colors.white),
              brightness:
                  uiProvider.isLightTheme ? Brightness.light : Brightness.dark,
              elevation: 0.0,
            ),
            body: _showBudgetList(),
          ),
        ]));
  }
}
