import 'package:Groovy/providers/auth_provider.dart';
import 'package:Groovy/providers/budget_provider.dart';
import 'package:Groovy/providers/ui_provider.dart';
import 'package:Groovy/providers/user_provider.dart';
import 'package:Groovy/screens/budget_list/create_budget.dart';
import 'package:Groovy/screens/shared/utilities.dart';
import 'package:Groovy/services/auth_service.dart';
import 'package:Groovy/services/budget_service.dart';
import 'package:Groovy/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'alerts.dart';
import 'budget_list/budget_list.dart';
import 'card.dart';
import 'profile.dart';
import 'package:bubble_bottom_bar/bubble_bottom_bar.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen(
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
  _HomeScreen createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  void _navigationTapped(int page) {
    _pageController.animateToPage(page,
        duration: const Duration(milliseconds: 300), curve: Curves.ease);
  }

  void _onPageChanged(int page) {
    setState(() {
      this._page = page;
    });
  }

  _signOut() async {
    Navigator.pop(context);
    var uiProvider = Provider.of<UIProvider>(context);
    var userProvider = Provider.of<UserProvider>(context);

    await widget.userService.removeUserDeviceToken(_firebaseMessaging,
        widget.userService, _database, userProvider.currentUser);

    try {
      uiProvider.isLoading = false;
      widget.auth.signOut();
      widget.onSignedOut();
      print("sign out successful");
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    var authProvider = Provider.of<AuthProvider>(context);
    var uiProvider = Provider.of<UIProvider>(context);
    var budgetProvider = Provider.of<BudgetProvider>(context);
    var userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
        backgroundColor:
            uiProvider.isLightTheme ? Color(0xfff2f3fc) : Colors.grey[900],
        body: PageView(
          children: [
            BudgetListScreen(
              user: widget.user,
              userService: widget.userService,
              budgetService: widget.budgetService,
              auth: widget.auth,
              onSignedOut: widget.onSignedOut,
            ),
            CardScreen(
              auth: widget.auth,
              user: widget.user,
              currentUser: userProvider.currentUser,
            ),
            AlertScreen(
              auth: widget.auth,
              userService: widget.userService,
              user: widget.user,
              currentUser: userProvider.currentUser,
            ),
            ProfileScreen(
              user: widget.user,
              userProvider: userProvider,
              userService: widget.userService,
              budgetService: widget.budgetService,
              auth: widget.auth,
              onSignedOut: widget.onSignedOut,
            )
          ],
          onPageChanged: _onPageChanged,
          controller: _pageController,
        ),
        floatingActionButton: _page == 0
            ? FloatingActionButton(
                backgroundColor: uiProvider.isLightTheme
                    ? Colors.purple[300]
                    : Colors.purple[200],
                child: Icon(
                  Icons.add,
                  size: 28,
                  color: uiProvider.isLightTheme ? Colors.white : Colors.black,
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
              )
            : _page == 3
                ? FloatingActionButton(
                    tooltip: "Signout",
                    elevation: 0,
                    backgroundColor: uiProvider.isLightTheme
                        ? Colors.grey[800]
                        : Colors.grey[300],
                    foregroundColor: Colors.black87,
                    child: RotationTransition(
                        turns: new AlwaysStoppedAnimation(180 / 360),
                        child: Icon(
                          Icons.exit_to_app,
                          color: uiProvider.isLightTheme
                              ? Colors.white
                              : Colors.black,
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
                  )
                : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        bottomNavigationBar: Container(
            color:
                uiProvider.isLightTheme ? Colors.grey[200] : Colors.grey[900],
            child: BubbleBottomBar(
              fabLocation: _page == 0 || _page == 3
                  ? BubbleBottomBarFabLocation.end
                  : null,
              backgroundColor:
                  uiProvider.isLightTheme ? Colors.white : Colors.black,
              opacity: 0.2,
              currentIndex: _page,
              onTap: _navigationTapped,
              borderRadius: BorderRadius.circular(16.0),
              elevation: 0.0,
              hasNotch: false,
              hasInk: true,
              inkColor: Colors.black12,
              items: <BubbleBottomBarItem>[
                BubbleBottomBarItem(
                    backgroundColor: uiProvider.isLightTheme
                        ? Colors.purple[300]
                        : Colors.purple[200],
                    icon: Icon(
                      Icons.home,
                      color:
                          uiProvider.isLightTheme ? Colors.black : Colors.white,
                    ),
                    activeIcon: Icon(
                      Icons.home,
                      color: uiProvider.isLightTheme
                          ? Colors.purple[600]
                          : Colors.purple[200],
                    ),
                    title: Text(
                      "Home",
                      style: TextStyle(
                          color: uiProvider.isLightTheme
                              ? Colors.purple[600]
                              : Colors.purple[200]),
                    )),
                BubbleBottomBarItem(
                    backgroundColor: uiProvider.isLightTheme
                        ? Colors.blue[300]
                        : Colors.blue[200],
                    icon: Icon(
                      Icons.credit_card,
                      color:
                          uiProvider.isLightTheme ? Colors.black : Colors.white,
                    ),
                    activeIcon: Icon(
                      Icons.credit_card,
                      color: uiProvider.isLightTheme
                          ? Colors.blue[600]
                          : Colors.blue[200],
                    ),
                    title: Text(
                      "Card",
                      style: TextStyle(
                          color: uiProvider.isLightTheme
                              ? Colors.blue[600]
                              : Colors.blue[200]),
                    )),
                BubbleBottomBarItem(
                    backgroundColor: uiProvider.isLightTheme
                        ? Colors.pink[300]
                        : Colors.pink[200],
                    icon: userProvider.currentUser != null &&
                            userProvider.currentUser.notAcceptedBudgets !=
                                null &&
                            userProvider.currentUser.notAcceptedBudgets.length >
                                0
                        ? Icon(
                            Icons.notifications_active,
                            color: uiProvider.isLightTheme
                                ? Colors.black
                                : Colors.white,
                          )
                        : Icon(
                            Icons.notifications,
                            color: uiProvider.isLightTheme
                                ? Colors.black
                                : Colors.white,
                          ),
                    activeIcon: userProvider.currentUser != null &&
                            userProvider.currentUser.notAcceptedBudgets !=
                                null &&
                            userProvider.currentUser.notAcceptedBudgets.length >
                                0
                        ? Icon(
                            Icons.notifications_active,
                            color: uiProvider.isLightTheme
                                ? Colors.pink[600]
                                : Colors.pink[200],
                          )
                        : Icon(
                            Icons.notifications,
                            color: uiProvider.isLightTheme
                                ? Colors.pink[600]
                                : Colors.pink[200],
                          ),
                    title: Text(
                      "Alerts",
                      style: TextStyle(
                          color: uiProvider.isLightTheme
                              ? Colors.pink[600]
                              : Colors.pink[200]),
                    )),
                BubbleBottomBarItem(
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    icon: Icon(
                      Icons.person,
                      color:
                          uiProvider.isLightTheme ? Colors.black : Colors.white,
                    ),
                    activeIcon: Icon(
                      Icons.person,
                      color:
                          uiProvider.isLightTheme ? Colors.black : Colors.white,
                    ),
                    title: Text(
                      "Me",
                      style: TextStyle(
                          color: uiProvider.isLightTheme
                              ? Colors.black
                              : Colors.white),
                    ))
              ],
            )));
  }
}
