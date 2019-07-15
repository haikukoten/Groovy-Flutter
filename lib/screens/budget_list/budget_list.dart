import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:Groovy/models/user.dart';
import 'package:Groovy/providers/auth_provider.dart';
import 'package:Groovy/providers/budget_provider.dart';
import 'package:Groovy/providers/storage_provider.dart';
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
import '../shared/animated/background.dart';
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
  GlobalKey _drawerKey = GlobalKey();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  Query _userQuery;
  final _currency = NumberFormat.simpleCurrency();
  SharedPreferences _preferences;

  StreamSubscription<Event> _onUserChangedSubscription;

  double _initialDragAmount = 0;
  double _finalDragAmount = 0;

  bool _initialized = false;
  User currentUser;
  List<String> tokenPlatorms = [];

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

    _onUserChangedSubscription =
        _userQuery.onChildChanged.listen(_onUserChanged);

    // Handle FCM
    fcmListeners();
  }

  @override
  void dispose() {
    _onUserChangedSubscription.cancel();
    super.dispose();
  }

  void _getSavedPreferences() async {
    _preferences = await SharedPreferences.getInstance();
    var uiProvider = Provider.of<UIProvider>(context);
    uiProvider.isLightTheme = _preferences.getBool("theme") ?? false;
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
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      if (settings.alert == true) {
        Navigator.pop(context);
      }
      print("Settings registered: $settings");
    });
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

  void _getLocalStorageForNotAcceptedSharedBudgets() {
    var storageProvider = Provider.of<StorageProvider>(context);
    var budgetProvider = Provider.of<BudgetProvider>(context);
    var notAcceptedBudgets =
        (storageProvider.storage.getItem('notAcceptedSharedBudgets') as List);

    if (notAcceptedBudgets != null) {
      notAcceptedBudgets.forEach((budget) {
        Budget notSharedBudget = Budget.fromJson(budget);
        budgetProvider.notAcceptedSharedBudgets.add(notSharedBudget);
      });
    }
  }

  _onUserChanged(Event event) {
    var userProvider = Provider.of<UserProvider>(context);
    setState(() {
      userProvider.currentUser = User.fromSnapshot(event.snapshot);
    });
  }

  num totalAmountSpent(UserProvider userProvider) {
    num totalSpent = 0;
    for (int i = 0; i < userProvider.currentUser.budgets.length; i++) {
      totalSpent += userProvider.currentUser.budgets[i].spent;
    }
    return totalSpent;
  }

  num totalAmountBudgeted(UserProvider userProvider) {
    num totalBudgeted = 0;
    if (userProvider.currentUser.budgets.length > 0) {
      for (int i = 0; i < userProvider.currentUser.budgets.length; i++) {
        totalBudgeted += userProvider.currentUser.budgets[i].setAmount;
      }
    }
    return totalBudgeted;
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

  _signOut() {
    Navigator.pop(context);
    Navigator.pop(context);
    var budgetProvider = Provider.of<BudgetProvider>(context);
    var storageProvider = Provider.of<StorageProvider>(context);
    var uiProvider = Provider.of<UIProvider>(context);
    var userProvider = Provider.of<UserProvider>(context);

    widget.userService
        .removeUserDeviceToken(_firebaseMessaging, widget.userService,
            _database, userProvider.currentUser)
        .then((_) {
      try {
        // save empty not accepted shared budgets to storage
        storageProvider.saveItemToStorage(
            budgetProvider,
            budgetProvider.notAcceptedSharedBudgets,
            'notAcceptedSharedBudgets');

        // clear values
        uiProvider.isLoading = false;
        budgetProvider.notAcceptedSharedBudgets = [];
        tokenPlatorms = [];
        widget.auth.signOut();
        widget.onSignedOut();
        print("sign out successful");
      } catch (e) {
        print(e);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var uiProvider = Provider.of<UIProvider>(context);
    var budgetProvider = Provider.of<BudgetProvider>(context);
    var userProvider = Provider.of<UserProvider>(context);
    var authProvider = Provider.of<AuthProvider>(context);
    var storageProvider = Provider.of<StorageProvider>(context);

    // TODO: if budget is shared, alert user that all shared users will also have this deleted. So otherwise just remove yourself from share menu to remove yourself.
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
          onPressed: () {
            print(budget.toString());
            widget.budgetService
                .deleteBudget(_database, userProvider.currentUser, budget);
            print("Delete ${budget.key} successful");
            // int budgetIndex = userProvider.currentUser.budgets.indexOf(budget);
            // setState(() {
            //   userProvider.currentUser.budgets.removeAt(budgetIndex);
            // });
            Navigator.of(context).pop();
          },
        )
      ]);
    }

    _removeUserFromSharedBudget(String email) {
      var newSharedWith = [];
      for (String sharedWithEmail in budgetProvider.selectedBudget.sharedWith) {
        newSharedWith.add(sharedWithEmail);
      }

      newSharedWith.remove(email);

      if (newSharedWith.length == 1) {
        newSharedWith[0] = "none";
        budgetProvider.selectedBudget.isShared = false;
      }

      // Remove display name of user that shared budget
      // var newSharedName = "none";

      budgetProvider.selectedBudget.sharedWith = newSharedWith;
      widget.budgetService.updateBudget(
          _database, userProvider.currentUser, budgetProvider.selectedBudget);
    }

    Widget _showBudgetList() {
      if (userProvider.currentUser != null &&
          userProvider.currentUser.budgets != null &&
          userProvider.currentUser.budgets.length > 0) {
        // Swipe up to show 'Create Budget' dialog
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

                    // Determine if budget is saved in not accepted budgets
                    bool isNotAccepted = false;
                    String nameOfUserThatSharedNotAcceptedBudget = "";
                    for (Budget notAcceptedSharedBudget
                        in budgetProvider.notAcceptedSharedBudgets) {
                      if (notAcceptedSharedBudget.key ==
                          userProvider.currentUser.budgets[index].key) {
                        isNotAccepted = true;
                      }
                    }
                    return isNotAccepted
                        ? Opacity(
                            opacity: 0.5,
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
                                          borderRadius:
                                              BorderRadius.circular(32.0),
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
                                                splashColor:
                                                    uiProvider.isLightTheme
                                                        ? Colors.grey[300]
                                                            .withOpacity(0.5)
                                                        : Colors.grey[100]
                                                            .withOpacity(0.1),
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(32.0)),
                                                onTap: () {
                                                  var budgetProvider = Provider
                                                      .of<BudgetProvider>(
                                                          context);
                                                  budgetProvider
                                                          .selectedBudget =
                                                      userProvider.currentUser
                                                          .budgets[index];
                                                  var authProvider =
                                                      Provider.of<AuthProvider>(
                                                          context);
                                                  authProvider.auth =
                                                      widget.auth;
                                                  userProvider.userService =
                                                      widget.userService;
                                                  budgetProvider.budgetService =
                                                      widget.budgetService;

                                                  showAlertDialog(
                                                      context,
                                                      "Accept budget?",
                                                      nameOfUserThatSharedNotAcceptedBudget ==
                                                                  "" ||
                                                              nameOfUserThatSharedNotAcceptedBudget ==
                                                                  "none"
                                                          ? "'${userProvider.currentUser.budgets[index].name}' has been shared with you. Accept to add it to your list."
                                                          : "$nameOfUserThatSharedNotAcceptedBudget shared '${userProvider.currentUser.budgets[index].name}' with you. Accept to add it to your list.",
                                                      [
                                                        FlatButton(
                                                          child: Text(
                                                            'Close',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .grey),
                                                          ),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                        ),
                                                        FlatButton(
                                                          child: Text(
                                                            'Decline',
                                                            style: TextStyle(
                                                                color: uiProvider
                                                                        .isLightTheme
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white),
                                                          ),
                                                          onPressed: () {
                                                            // Decline budget

                                                            // Remove budget from not accepted shared budgets if it exists
                                                            budgetProvider
                                                                .removeNotAcceptedBudget(
                                                                    budgetProvider
                                                                        .selectedBudget);
                                                            storageProvider.saveItemToStorage(
                                                                budgetProvider,
                                                                budgetProvider
                                                                    .notAcceptedSharedBudgets,
                                                                'notAcceptedSharedBudgets');

                                                            // Remove user from budget shared list
                                                            _removeUserFromSharedBudget(
                                                                widget.user
                                                                    .email);

                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                        ),
                                                        FlatButton(
                                                          child: Text(
                                                            'Accept',
                                                            style: TextStyle(
                                                                color: uiProvider
                                                                        .isLightTheme
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white),
                                                          ),
                                                          onPressed: () {
                                                            // Accept budget

                                                            // Remove budget from not accepted shared budgets if it exists
                                                            budgetProvider
                                                                .removeNotAcceptedBudget(
                                                                    budgetProvider
                                                                        .selectedBudget);
                                                            storageProvider.saveItemToStorage(
                                                                budgetProvider,
                                                                budgetProvider
                                                                    .notAcceptedSharedBudgets,
                                                                'notAcceptedSharedBudgets');

                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                        )
                                                      ]);
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
                                                                ? Colors
                                                                    .grey[800]
                                                                : Colors.white),
                                                      ),
                                                      subtitle: Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                top: 5.0),
                                                        child: AutoSizeText(
                                                          "${_currency.format(spent)} of ${_currency.format(setAmount)}",
                                                          maxLines: 1,
                                                          style: TextStyle(
                                                              color: uiProvider
                                                                      .isLightTheme
                                                                  ? Colors
                                                                      .grey[700]
                                                                  : Colors.grey[
                                                                      400],
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 17.0),
                                                        ),
                                                      ),
                                                      trailing: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                right: 18.0),
                                                        child:
                                                            userProvider
                                                                    .currentUser
                                                                    .budgets[
                                                                        index]
                                                                    .isShared
                                                                ? Icon(
                                                                    Icons
                                                                        .account_circle,
                                                                    color: uiProvider
                                                                            .isLightTheme
                                                                        ? Colors
                                                                            .grey[
                                                                                700]
                                                                            .withOpacity(
                                                                                0.4)
                                                                        : Colors
                                                                            .grey[100]
                                                                            .withOpacity(0.4),
                                                                  )
                                                                : null,
                                                      ),
                                                    ),
                                                  ],
                                                ))),
                                      )),
                                ),
                              ),
                            ))
                        : OnSlide(
                            items: <ActionItems>[
                                new ActionItems(
                                    icon: new IconButton(
                                      icon: new Icon(Icons.edit),
                                      onPressed: () {},
                                      color: Colors.white,
                                    ),
                                    onPress: () {
                                      budgetProvider.selectedBudget =
                                          userProvider
                                              .currentUser.budgets[index];
                                      userProvider.userService =
                                          widget.userService;
                                      budgetProvider.budgetService =
                                          widget.budgetService;
                                      Navigator.of(context).push(
                                          CupertinoPageRoute(
                                              fullscreenDialog: true,
                                              builder: (context) =>
                                                  EditBudgetScreen(
                                                    budget: userProvider
                                                        .currentUser
                                                        .budgets[index],
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
                                          userProvider
                                              .currentUser.budgets[index];
                                      userProvider.userService =
                                          widget.userService;
                                      budgetProvider.budgetService =
                                          widget.budgetService;
                                      Navigator.of(context).push(
                                          CupertinoPageRoute(
                                              fullscreenDialog: true,
                                              builder: (context) =>
                                                  ShareBudgetScreen(
                                                    budget: budgetProvider
                                                        .selectedBudget,
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
                                      _deleteBudget(userProvider
                                          .currentUser.budgets[index]);
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
                                          borderRadius:
                                              BorderRadius.circular(32.0),
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
                                                splashColor:
                                                    uiProvider.isLightTheme
                                                        ? Colors.grey[300]
                                                            .withOpacity(0.5)
                                                        : Colors.grey[100]
                                                            .withOpacity(0.1),
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(32.0)),
                                                onTap: () {
                                                  var budgetProvider = Provider
                                                      .of<BudgetProvider>(
                                                          context);
                                                  budgetProvider
                                                          .selectedBudget =
                                                      userProvider.currentUser
                                                          .budgets[index];
                                                  print(
                                                      "Selected budget ==> ${budgetProvider.selectedBudget}");
                                                  var authProvider =
                                                      Provider.of<AuthProvider>(
                                                          context);
                                                  authProvider.auth =
                                                      widget.auth;
                                                  userProvider.userService =
                                                      widget.userService;
                                                  budgetProvider.budgetService =
                                                      widget.budgetService;
                                                  Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              BudgetDetailScreen(
                                                                user:
                                                                    widget.user,
                                                                auth:
                                                                    widget.auth,
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
                                                                ? Colors
                                                                    .grey[800]
                                                                : Colors.white),
                                                      ),
                                                      subtitle: Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                top: 5.0),
                                                        child: AutoSizeText(
                                                          "${_currency.format(spent)} of ${_currency.format(setAmount)}",
                                                          maxLines: 1,
                                                          style: TextStyle(
                                                              color: uiProvider
                                                                      .isLightTheme
                                                                  ? Colors
                                                                      .grey[700]
                                                                  : Colors.grey[
                                                                      400],
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 17.0),
                                                        ),
                                                      ),
                                                      trailing: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                right: 18.0),
                                                        child:
                                                            userProvider
                                                                    .currentUser
                                                                    .budgets[
                                                                        index]
                                                                    .isShared
                                                                ? Icon(
                                                                    Icons
                                                                        .account_circle,
                                                                    color: uiProvider
                                                                            .isLightTheme
                                                                        ? Colors
                                                                            .grey[
                                                                                700]
                                                                            .withOpacity(
                                                                                0.4)
                                                                        : Colors
                                                                            .grey[100]
                                                                            .withOpacity(0.4),
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
                    color: Colors.black.withOpacity(0.5)),
              ),
              Text(
                "Swipe up to get started",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18.0, color: Colors.black.withOpacity(0.5)),
              ),
            ],
          ),
        );
      }
    }

    return GestureDetector(
        onPanStart: (details) {
          _initialDragAmount = details.globalPosition.dy;
        },
        onPanUpdate: (details) {
          _finalDragAmount = details.globalPosition.dy - _initialDragAmount;
        },
        onPanEnd: (details) {
          final RenderBox drawerBox =
              _drawerKey.currentContext?.findRenderObject();
          // only open create budget window if drawer is closed
          if (_finalDragAmount < 0 && drawerBox == null) {
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
            child: AnimatedBackground(),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              iconTheme: IconThemeData(color: Colors.white),
              brightness: Brightness.dark,
              elevation: 0.0,
            ),
            drawer: Drawer(
                key: _drawerKey,
                child: Container(
                  color:
                      uiProvider.isLightTheme ? Colors.white : Colors.grey[900],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      UserAccountsDrawerHeader(
                        decoration: BoxDecoration(color: Colors.black),
                        accountEmail: widget.user.email != null
                            ? Text(widget.user.email)
                            : SizedBox.shrink(),
                        accountName: widget.user.displayName != null
                            ? Text(
                                widget.user.displayName,
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
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
                                          widget.user.email
                                              .substring(0, 1)
                                              .toLowerCase(),
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
                        padding: const EdgeInsets.only(
                            top: 5.0, bottom: 5.0, left: 14.0),
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
                        padding: const EdgeInsets.only(
                            top: 5.0, bottom: 5.0, left: 14.0),
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
                        padding: const EdgeInsets.only(
                            top: 5.0, bottom: 5.0, left: 14.0),
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
                        padding: const EdgeInsets.only(
                            top: 5.0, bottom: 5.0, left: 14.0),
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
                                            _preferences.setBool("theme",
                                                uiProvider.isLightTheme);
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  CircleAvatar(
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
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 14.0, bottom: 16),
                            child: FloatingActionButton(
                              tooltip: "Signout",
                              elevation: 0,
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black87,
                              child: RotationTransition(
                                  turns: new AlwaysStoppedAnimation(180 / 360),
                                  child: Icon(
                                    Icons.exit_to_app,
                                  )),
                              onPressed: () {
                                showAlertDialog(context, "Signout",
                                    "Are you sure you want to signout?", [
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
                                      'Signout',
                                      style: TextStyle(
                                          color: uiProvider.isLightTheme
                                              ? Colors.black
                                              : Colors.white),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        uiProvider.isLoading = true;
                                      });
                                      _signOut();
                                    },
                                  )
                                ]);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            body: FutureBuilder(
                future: storageProvider.storage.ready,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.data == null) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.black.withOpacity(0.5)),
                      ),
                    );
                  }

                  if (!_initialized) {
                    _getLocalStorageForNotAcceptedSharedBudgets();
                    _initialized = true;
                  }

                  return _showBudgetList();
                }),
            floatingActionButton: FloatingActionButton(
              backgroundColor: uiProvider.isLightTheme
                  ? Colors.white.withOpacity(0.5)
                  : Colors.black.withOpacity(0.5),
              child: Icon(
                Icons.add,
                size: 28,
                color:
                    uiProvider.isLightTheme ? Colors.grey[800] : Colors.white,
              ),
              elevation: 0,
              onPressed: () {
                authProvider.auth = widget.auth;
                userProvider.userService = widget.userService;
                budgetProvider.budgetService = widget.budgetService;
                Navigator.of(context).push(CupertinoPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => CreateBudgetScreen(
                          user: userProvider.currentUser,
                        )));
              },
            ),
          ),
        ]));
  }
}
