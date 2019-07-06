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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import "package:intl/intl.dart";
import 'package:flutter/material.dart';
import 'package:Groovy/services/auth.dart';
import 'package:Groovy/models/budget.dart';
import 'package:provider/provider.dart';
import '../budget_detail/edit_budget.dart';
import '../shared/swipe_actions/swipe_widget.dart';
import '../shared/animated/background.dart';
import '../shared/utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:auto_size_text/auto_size_text.dart';

class BudgetListScreen extends StatefulWidget {
  BudgetListScreen({Key key, this.auth, this.user, this.onSignedOut})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final FirebaseUser user;

  @override
  State<StatefulWidget> createState() => new _BudgetListScreen();
}

class _BudgetListScreen extends State<BudgetListScreen> {
  GlobalKey _drawerKey = GlobalKey();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  Query _budgetQuery;
  Query _usersQuery;
  final _currency = NumberFormat.simpleCurrency();
  SharedPreferences _preferences;

  StreamSubscription<Event> _onBudgetAddedSubscription;
  StreamSubscription<Event> _onBudgetChangedSubscription;

  StreamSubscription<Event> _onUserAddedSubscription;
  StreamSubscription<Event> _onUserChangedSubscription;

  double _initialDragAmount;
  double _finalDragAmount;

  bool _initialized = false;
  User currentUser = User();
  List<String> tokenPlatorms = [];

  @override
  void initState() {
    super.initState();

    _database.setPersistenceEnabled(true);
    _database.setPersistenceCacheSizeBytes(10000000); // 10MB cache

    _getSavedPreferences();

    _budgetQuery = _database.reference().child("budgets");
    _usersQuery = _database.reference().child("users");

    _onBudgetAddedSubscription =
        _budgetQuery.onChildAdded.listen(_onEntryAdded);
    _onBudgetChangedSubscription =
        _budgetQuery.onChildChanged.listen(_onEntryChanged);

    _onUserAddedSubscription = _usersQuery.onChildAdded.listen(_onUserAdded);
    _onUserChangedSubscription =
        _usersQuery.onChildChanged.listen(_onUserChanged);

    // Handle FCM
    fcmListeners();
  }

  @override
  void dispose() {
    _onBudgetAddedSubscription.cancel();
    _onBudgetChangedSubscription.cancel();
    _onUserAddedSubscription.cancel();
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
        print('on message $message');
      },
      onResume: (Map<String, dynamic> message) async {
        print('on resume $message');
      },
      onLaunch: (Map<String, dynamic> message) async {
        print('on launch $message');
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

  _onEntryChanged(Event event) {
    Budget budget = Budget.fromSnapshot(event.snapshot);
    var budgetProvider = Provider.of<BudgetProvider>(context);
    var uiProvider = Provider.of<UIProvider>(context);
    var storageProvider = Provider.of<StorageProvider>(context);

    // Update budget if it was created by signed in user
    if (event.snapshot.value["createdBy"] == widget.user.email) {
      var oldBudget = budgetProvider.budgetList.singleWhere((budget) {
        return budget.key == event.snapshot.key;
      });

      setState(() {
        budgetProvider
                .budgetList[budgetProvider.budgetList.indexOf(oldBudget)] =
            Budget.fromSnapshot(event.snapshot);
      });

      // Update budget if it was not created by signed in user (budget shared with user)
    } else if (event.snapshot.value["sharedWith"].contains(widget.user.email)) {
      try {
        // Shared budget got changed so update it
        var oldBudget = budgetProvider.budgetList.singleWhere((budget) {
          return budget.key == event.snapshot.key;
        });
        setState(() {
          budgetProvider
                  .budgetList[budgetProvider.budgetList.indexOf(oldBudget)] =
              Budget.fromSnapshot(event.snapshot);
        });
      } catch (e) {
        // Budget just got shared with signed in user so add it to list

        setState(() {
          budgetProvider.budgetList.add(budget);
          // Sort budgets alphabetically
          budgetProvider.budgetList.sort((a, b) => a.name.compareTo(b.name));
        });

        // If user is logged in, show alert that budget has been shared with user
        var notificationMessage = budget.sharedName == "none"
            ? "New shared budget"
            : "${budget.sharedName} shared a budget with you";
        showSimpleNotification(
            Text(
              notificationMessage,
              style: TextStyle(
                  color: uiProvider.isLightTheme ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            background: uiProvider.isLightTheme ? Colors.white : Colors.black);

        // Save new shared budget in localstorage so user can determine if they want to accept or decline
        if (budgetProvider.notAcceptedSharedBudgets.isEmpty) {
          budgetProvider.notAcceptedSharedBudgets.add(budget);
          storageProvider.saveItemToStorage(
              budgetProvider,
              budgetProvider.notAcceptedSharedBudgets,
              'notAcceptedSharedBudgets');
        } else {
          for (Budget sharedBudget in budgetProvider.notAcceptedSharedBudgets) {
            if (sharedBudget.key != budget.key) {
              budgetProvider.notAcceptedSharedBudgets.add(budget);
              storageProvider.saveItemToStorage(
                  budgetProvider,
                  budgetProvider.notAcceptedSharedBudgets,
                  'notAcceptedSharedBudgets');
            }
          }
        }
      }
      // User is no longer shared with budget so remove it
    } else {
      if (!budget.sharedWith.contains(widget.user.email)) {
        for (Budget userBudget in budgetProvider.budgetList) {
          if (userBudget.key == budget.key) {
            setState(() {
              budgetProvider.budgetList.remove(userBudget);
            });
          }
        }
      }

      // Remove budget from not accepted shared budgets if it exists
      budgetProvider.removeNotAcceptedBudget(budget);
      storageProvider.saveItemToStorage(budgetProvider,
          budgetProvider.notAcceptedSharedBudgets, 'notAcceptedSharedBudgets');
    }
  }

  _onEntryAdded(Event event) {
    var budgetProvider = Provider.of<BudgetProvider>(context);
    if (event.snapshot.value["createdBy"] == widget.user.email ||
        event.snapshot.value["sharedWith"].contains(widget.user.email)) {
      setState(() {
        budgetProvider.budgetList.add(Budget.fromSnapshot(event.snapshot));
        // Sort budgets alphabetically
        budgetProvider.budgetList.sort((a, b) => a.name.compareTo(b.name));
      });
    }
  }

  _onUserAdded(Event event) {
    var userProvider = Provider.of<UserProvider>(context);
    userProvider.userList.add(User.fromSnapshot(event.snapshot));
    _updateUserOnFirebase();
  }

  _onUserChanged(Event event) {
    var userProvider = Provider.of<UserProvider>(context);
    if (event.snapshot.value["email"] == widget.user.email) {
      // update current user
      currentUser = User.fromSnapshot(event.snapshot);
      userProvider.currentUser = currentUser;

      // update useres list
      var oldUser = userProvider.userList.singleWhere((user) {
        return user.key == event.snapshot.key;
      });

      setState(() {
        userProvider.userList[userProvider.userList.indexOf(oldUser)] =
            User.fromSnapshot(event.snapshot);
      });
    }
  }

  _updateUserOnFirebase() {
    var userProvider = Provider.of<UserProvider>(context);
    List<User> duplicateUsers = [];

    userProvider.userList.forEach((user) {
      if (user.email == widget.user.email) {
        currentUser = user;
        userProvider.currentUser = currentUser;
        duplicateUsers.add(user);
        if (!tokenPlatorms.contains(user.tokenPlatform.first)) {
          tokenPlatorms.add(user.tokenPlatform.first);
        }
      }
    });

    if (duplicateUsers.length == 2) {
      duplicateUsers[0].tokenPlatform = tokenPlatorms;

      userProvider.userList.forEach((user) {
        if (user.key == duplicateUsers[1].key) {
          widget.auth.deleteUser(_database, user);
        }
      });

      currentUser = duplicateUsers[0];
      userProvider.currentUser = currentUser;
      widget.auth.updateUser(_database, duplicateUsers[0]);
    }
  }

  num totalAmountSpent(BudgetProvider budgetProvider) {
    num totalSpent = 0;
    for (int i = 0; i < budgetProvider.budgetList.length; i++) {
      totalSpent += budgetProvider.budgetList[i].spent;
    }
    return totalSpent;
  }

  num totalAmountBudgeted(BudgetProvider budgetProvider) {
    num totalBudgeted = 0;
    if (budgetProvider.budgetList.length > 0) {
      for (int i = 0; i < budgetProvider.budgetList.length; i++) {
        totalBudgeted += budgetProvider.budgetList[i].setAmount;
      }
    }
    return totalBudgeted;
  }

  num totalAmountLeft(BudgetProvider budgetProvider) {
    num totalLeft = 0;
    if (budgetProvider.budgetList.length > 0) {
      for (int i = 0; i < budgetProvider.budgetList.length; i++) {
        totalLeft += budgetProvider.budgetList[i].left;
      }
    }
    return totalLeft;
  }

  _removeUserToken() async {
    var userProvider = Provider.of<UserProvider>(context);
    String currentTokenPlatform;
    var token = await _firebaseMessaging.getToken();
    var platform = Platform.isAndroid ? "android" : "iOS";
    currentTokenPlatform = "$token&&platform===>$platform";

    var tokenPlatforms = [];
    currentUser.tokenPlatform
        .forEach((tokenPlatform) => tokenPlatforms.add(tokenPlatform));

    if (currentUser.tokenPlatform.contains(currentTokenPlatform)) {
      print(currentUser.toString());
      tokenPlatforms.remove(currentTokenPlatform);
      currentUser.tokenPlatform = tokenPlatforms;
      if (currentUser.tokenPlatform.isNotEmpty) {
        widget.auth.updateUser(_database, currentUser);
      } else {
        widget.auth.deleteUser(_database, currentUser);
      }
    }

    currentUser = User();
    userProvider.currentUser = currentUser;
  }

  _signOut() {
    _removeUserToken();
    Navigator.pop(context);
    Navigator.pop(context);
    var budgetProvider = Provider.of<BudgetProvider>(context);
    var storageProvider = Provider.of<StorageProvider>(context);
    var uiProvider = Provider.of<UIProvider>(context);
    var userProvider = Provider.of<UserProvider>(context);

    try {
      uiProvider.isLoading = false;
      budgetProvider.budgetList = [];
      budgetProvider.notAcceptedSharedBudgets = [];
      tokenPlatorms = [];
      userProvider.userList = [];
      // save empty not accepted shared budgets to storage
      storageProvider.saveItemToStorage(budgetProvider,
          budgetProvider.notAcceptedSharedBudgets, 'notAcceptedSharedBudgets');
      widget.auth.signOut();
      widget.onSignedOut();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    var uiProvider = Provider.of<UIProvider>(context);
    var budgetProvider = Provider.of<BudgetProvider>(context);
    var authProvider = Provider.of<AuthProvider>(context);
    var storageProvider = Provider.of<StorageProvider>(context);

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
            widget.auth.deleteBudget(_database, budget);
            print("Delete ${budget.key} successful");
            int budgetIndex = budgetProvider.budgetList.indexOf(budget);
            setState(() {
              budgetProvider.budgetList.removeAt(budgetIndex);
            });
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
      var newSharedName = "none";

      budgetProvider.selectedBudget.sharedWith = newSharedWith;
      budgetProvider.selectedBudget.sharedName = newSharedName;
      widget.auth.updateBudget(_database, budgetProvider.selectedBudget);
    }

    Widget _showBudgetList() {
      if (budgetProvider.budgetList.length > 0) {
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
                  itemCount: budgetProvider.budgetList.length,
                  itemBuilder: (BuildContext context, int index) {
                    String name = budgetProvider.budgetList[index].name;
                    num spent = budgetProvider.budgetList[index].spent;
                    num setAmount = budgetProvider.budgetList[index].setAmount;

                    // Determine if budget is saved in not accepted budgets
                    bool isNotAccepted = false;
                    String nameOfUserThatSharedNotAcceptedBudget = "";
                    for (Budget notAcceptedSharedBudget
                        in budgetProvider.notAcceptedSharedBudgets) {
                      if (notAcceptedSharedBudget.key ==
                          budgetProvider.budgetList[index].key) {
                        isNotAccepted = true;
                        nameOfUserThatSharedNotAcceptedBudget =
                            notAcceptedSharedBudget.sharedName;
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
                                                      budgetProvider
                                                          .budgetList[index];
                                                  var authProvider =
                                                      Provider.of<AuthProvider>(
                                                          context);
                                                  authProvider.auth =
                                                      widget.auth;

                                                  showAlertDialog(
                                                      context,
                                                      "Accept budget?",
                                                      nameOfUserThatSharedNotAcceptedBudget ==
                                                                  "" ||
                                                              nameOfUserThatSharedNotAcceptedBudget ==
                                                                  "none"
                                                          ? "'${budgetProvider.budgetList[index].name}' has been shared with you. Accept to add it to your list."
                                                          : "$nameOfUserThatSharedNotAcceptedBudget shared '${budgetProvider.budgetList[index].name}' with you. Accept to add it to your list.",
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
                                                            budgetProvider
                                                                    .budgetList[
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
                                          budgetProvider.budgetList[index];
                                      Navigator.of(context).push(
                                          CupertinoPageRoute(
                                              fullscreenDialog: true,
                                              builder: (context) =>
                                                  EditBudgetScreen(
                                                    budget: budgetProvider
                                                        .budgetList[index],
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
                                          budgetProvider.budgetList[index];
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
                                      _deleteBudget(
                                          budgetProvider.budgetList[index]);
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
                                                      budgetProvider
                                                          .budgetList[index];
                                                  var authProvider =
                                                      Provider.of<AuthProvider>(
                                                          context);
                                                  authProvider.auth =
                                                      widget.auth;
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
                                                            budgetProvider
                                                                    .budgetList[
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
            Navigator.of(context).push(CupertinoPageRoute(
                fullscreenDialog: true,
                builder: (context) => CreateBudgetScreen(
                      user: widget.user,
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
                                "${budgetProvider.budgetList.length.toString()}",
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
                                "${_currency.format(totalAmountSpent(budgetProvider))}",
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
                                "${_currency.format(totalAmountLeft(budgetProvider))}",
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
                Navigator.of(context).push(CupertinoPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => CreateBudgetScreen(
                          user: widget.user,
                        )));
              },
            ),
          ),
        ]));
  }
}
