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
import 'package:Groovy/screens/shared/animated/fade_in.dart';
import 'package:Groovy/screens/shared/utilities.dart';
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
import 'package:percent_indicator/linear_percent_indicator.dart';
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

    void _showOptionsModal(Budget budget) {
      var uiProvider = Provider.of<UIProvider>(context);
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
                          Text('Share',
                              style: TextStyle(
                                  fontSize: 18.0,
                                  color: uiProvider.isLightTheme
                                      ? Colors.black
                                      : Colors.white)),
                        ],
                      ),
                      onPressed: () {
                        budgetProvider.selectedBudget = budget;
                        userProvider.userService = widget.userService;
                        budgetProvider.budgetService = widget.budgetService;
                        Navigator.pop(context);
                        Navigator.of(context).push(CupertinoPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => ShareBudgetScreen(
                                  budget: budgetProvider.selectedBudget,
                                  user: widget.user,
                                  userService: widget.userService,
                                  auth: widget.auth,
                                )));
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
                          Text('Edit',
                              style: TextStyle(
                                  fontSize: 18.0,
                                  color: uiProvider.isLightTheme
                                      ? Colors.black
                                      : Colors.white)),
                        ],
                      ),
                      onPressed: () {
                        budgetProvider.selectedBudget = budget;
                        userProvider.userService = widget.userService;
                        budgetProvider.budgetService = widget.budgetService;
                        Navigator.pop(context);
                        Navigator.of(context).push(CupertinoPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => EditBudgetScreen(
                                  budget: budget,
                                  user: widget.user,
                                )));
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
                          Text('Delete',
                              style: TextStyle(
                                  fontSize: 18.0,
                                  color: uiProvider.isLightTheme
                                      ? Colors.purple[300]
                                      : Color(0xffe0c3fc))),
                        ],
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteBudget(budget);
                      },
                    ),
                  ))
            ],
          ),
          240.0);
    }

    Widget _showBudgetList() {
      if (userProvider.currentUser != null &&
          userProvider.currentUser.budgets != null &&
          userProvider.currentUser.budgets.length > 0) {
        var budgets = userProvider.currentUser.budgets;
        // alphabetize budgets
        budgets.sort((a, b) => a.name.compareTo(b.name));
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
                  itemCount: budgets.length,
                  itemBuilder: (BuildContext context, int index) {
                    var budget = budgets[index];
                    String name = budget.name;
                    return FadeIn(
                        0.5,
                        Padding(
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
                                name,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: uiProvider.isLightTheme
                                        ? Colors.black
                                        : Colors.white),
                              ),
                              leading: CircleAvatar(
                                radius: 35,
                                backgroundColor: Color(0xffeae7ec),
                                child: AutoSizeText(
                                  name[0],
                                  style: TextStyle(
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 24),
                                ),
                              ),
                              subtitle: new LayoutBuilder(builder:
                                  (BuildContext context,
                                      BoxConstraints constraints) {
                                return LinearPercentIndicator(
                                  linearGradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: uiProvider.isLightTheme
                                          ? [
                                              Colors.purple[200],
                                              Color(0xffa88beb).withOpacity(0.7)
                                            ]
                                          : [
                                              Colors.purple[300],
                                              Color(0xffa88beb).withOpacity(0.9)
                                            ]),
                                  animation: true,
                                  width: constraints.maxWidth * 0.95,
                                  lineHeight: 7,
                                  percent: buildPercentSpent(budget),
                                  backgroundColor: uiProvider.isLightTheme
                                      ? Colors.grey[300]
                                      : Colors.black,
                                  alignment: MainAxisAlignment.start,
                                );
                              }),
                              trailing: budget.isShared
                                  ? Icon(
                                      Icons.account_circle,
                                      color: Colors.grey.withOpacity(0.5),
                                    )
                                  : null,
                              onTap: () {
                                var budgetProvider =
                                    Provider.of<BudgetProvider>(context);
                                budgetProvider.selectedBudget =
                                    userProvider.currentUser.budgets[index];
                                print(
                                    "Selected budget ==> ${budgetProvider.selectedBudget}");
                                var authProvider =
                                    Provider.of<AuthProvider>(context);
                                authProvider.auth = widget.auth;
                                userProvider.userService = widget.userService;
                                budgetProvider.budgetService =
                                    widget.budgetService;
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => BudgetDetailScreen(
                                          user: widget.user,
                                          auth: widget.auth,
                                          userService: widget.userService,
                                        )));
                              },
                              onLongPress: () {
                                _showOptionsModal(
                                    userProvider.currentUser.budgets[index]);
                              },
                            ),
                          ),
                        ));
                  }),
            ))
          ],
        );
      } else {
        return FadeIn(
            0.5,
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.only(bottom: 100.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "No budgets",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
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
            ));
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
                ? backgroundWithSolidColor(Color(0xfff2f3fc))
                : backgroundWithSolidColor(Colors.grey[900]),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(40),
              child: AppBar(
                backgroundColor: Colors.transparent,
                iconTheme: IconThemeData(color: Colors.white),
                brightness: uiProvider.isLightTheme
                    ? Brightness.light
                    : Brightness.dark,
                elevation: 0.0,
              ),
            ),
            body: Column(children: [
              Expanded(
                flex: 0,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 0, 22),
                    child: FadeIn(
                        0.3,
                        AutoSizeText(
                          "Budgets",
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: uiProvider.isLightTheme
                                  ? Colors.grey[900]
                                  : Colors.white),
                        )),
                  ),
                ),
              ),
              Expanded(flex: 1, child: _showBudgetList())
            ]),
          ),
        ]));
  }
}
