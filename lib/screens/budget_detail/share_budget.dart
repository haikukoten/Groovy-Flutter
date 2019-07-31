import 'dart:convert';
import 'dart:ui';
import 'package:Groovy/models/budget.dart';
import 'package:Groovy/models/not_accepted_budget.dart';
import 'package:Groovy/models/user.dart';
import 'package:Groovy/providers/budget_provider.dart';
import 'package:Groovy/providers/ui_provider.dart';
import 'package:Groovy/providers/user_provider.dart';
import 'package:Groovy/screens/shared/swipe_actions/swipe_widget.dart';
import 'package:Groovy/services/auth_service.dart';
import 'package:Groovy/services/notification_service.dart';
import 'package:Groovy/services/user_service.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';
import '../shared/utilities.dart';
import 'package:email_validator/email_validator.dart';

class ShareBudgetScreen extends StatefulWidget {
  ShareBudgetScreen(
      {Key key, this.budget, this.user, this.auth, this.userService})
      : super(key: key);

  final Budget budget;
  final FirebaseUser user;
  final BaseAuth auth;
  final UserService userService;

  @override
  State<StatefulWidget> createState() => _ShareBudgetScreen();
}

class _ShareBudgetScreen extends State<ShareBudgetScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final _shareBudgetFormKey = GlobalKey<FormState>();
  TextEditingController _shareBudgetEmailTextController =
      TextEditingController();
  FocusNode _shareBudgetFocusNode = FocusNode();
  SendNotification notification = SendNotification();

  double _initialDragAmount;
  double _finalDragAmount;

  String _email;
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _getUsersForPhotos();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    _shareBudgetFocusNode.dispose();
    // Clean up the controller when the widget is removed from the
    // widget tree.
    _shareBudgetEmailTextController.dispose();
    super.dispose();
  }

  _getUsersForPhotos() {
    _users = [];
    widget.budget.sharedWith.forEach((email) async {
      User user = await widget.userService.getUserFromEmail(_database, email);
      setState(() {
        _users.add(user);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var uiProvider = Provider.of<UIProvider>(context);
    var budgetProvider = Provider.of<BudgetProvider>(context);
    var userProvider = Provider.of<UserProvider>(context);

    // Check if share form is valid
    bool _validateAndSaveShare() {
      final form = _shareBudgetFormKey.currentState;
      if (form.validate()) {
        form.save();
        return true;
      }
      return false;
    }

    Future<void> _sendNotificationTo(User user) {
      if (user.deviceTokens != null) {
        user.deviceTokens.forEach((token) {
          Map<String, Object> data;
          data = notification.createData(
              "",
              "${widget.user.displayName} shared a budget with you 💸",
              {
                "click_action": "FLUTTER_NOTIFICATION_CLICK",
                "nameOfSentFrom": "${widget.user.displayName}",
              },
              token);

          return notification.send(data);
        });
      }
      return null;
    }

    _shareBudget() async {
      if (_validateAndSaveShare()) {
        // get user from shared email
        User user =
            await userProvider.userService.getUserFromEmail(_database, _email);

        // User doesn't exist
        if (user.email == null) {
          showAlertDialog(
              context, "User not found", "No account found for $_email", [
            FlatButton(
              child: Text(
                'Close',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                FocusScope.of(context).requestFocus(_shareBudgetFocusNode);
              },
            ),
          ]);
        } else {
          budgetProvider.selectedBudget.isShared = true;

          var newSharedWith = [];

          if (budgetProvider.selectedBudget.sharedWith != null) {
            for (String sharedWithEmail
                in budgetProvider.selectedBudget.sharedWith) {
              newSharedWith.add(sharedWithEmail);
            }
          }

          // Add new email
          newSharedWith.add(_email.toLowerCase());

          // Update budget's sharedWith with new shared email
          budgetProvider.selectedBudget.sharedWith = newSharedWith;

          // Share budget with new user (add to new user's notAcceptedBudgets)
          var from =
              "${widget.user.displayName}<<<===:::===>>>${widget.user.email}";
          NotAcceptedBudget notAcceptedBudget =
              NotAcceptedBudget.fromBudget(budgetProvider.selectedBudget, from);
          budgetProvider.budgetService
              .shareBudget(_database, user, notAcceptedBudget);

          // Update all users on sharedWith
          // will check if budget exists in the user's budgets or notAcceptedBudgets and update it accordingly
          await userProvider.userService.updateSharedUsers(
              _database, budgetProvider.selectedBudget, budgetProvider);

          if (user.email != null) {
            await _sendNotificationTo(user);
          }

          _getUsersForPhotos();
        }
      }
    }

    _removeShared(String email) async {
      var newSharedWith = [];
      for (String sharedWithEmail in budgetProvider.selectedBudget.sharedWith) {
        newSharedWith.add(sharedWithEmail);
      }

      newSharedWith.remove(email);

      if (newSharedWith.length == 1) {
        budgetProvider.selectedBudget.isShared = false;
      }

      // Update budget's sharedWith with removed shared email
      budgetProvider.selectedBudget.sharedWith = newSharedWith;

      // get user from shared email
      User user =
          await userProvider.userService.getUserFromEmail(_database, email);

      // remove budget from user
      // will check if budget exists in the user's budgets or notAcceptedBudgets and remove it accordingly
      budgetProvider.budgetService
          .removeSharedBudget(_database, user, budgetProvider.selectedBudget);

      // Update all users on sharedWith
      // will check if budget exists in the user's budgets or notAcceptedBudgets and update it accordingly
      await userProvider.userService.updateSharedUsers(
          _database, budgetProvider.selectedBudget, budgetProvider);

      _getUsersForPhotos();
    }

    Widget _showIcon() {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: CircleAvatar(
          radius: 33,
          backgroundColor: Color(0xffeae7ec),
          child: AutoSizeText(
            budgetProvider.selectedBudget.name[0],
            style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
                fontSize: 24),
          ),
        ),
      );
    }

    Widget _showHelpText() {
      return Padding(
        padding: const EdgeInsets.all(18.0),
        child: Container(
          child: Center(
            child: Text(
              "Add email to share",
              style: TextStyle(
                  color: uiProvider.isLightTheme
                      ? Colors.grey[600]
                      : Colors.grey[400],
                  fontSize: 18,
                  fontWeight: FontWeight.w400),
            ),
          ),
        ),
      );
    }

    Widget _showEmailTextFormField() {
      return Padding(
          padding: const EdgeInsets.fromLTRB(45.0, 8.0, 45.0, 0.0),
          child: Theme(
            data: Theme.of(context).copyWith(splashColor: Colors.transparent),
            child: TextFormField(
              style: TextStyle(
                color:
                    uiProvider.isLightTheme ? Colors.grey[900] : Colors.white,
                fontSize: 16,
              ),
              cursorColor:
                  uiProvider.isLightTheme ? Colors.black87 : Colors.grey,
              keyboardAppearance:
                  uiProvider.isLightTheme ? Brightness.light : Brightness.dark,
              maxLines: 1,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.none,
              focusNode: _shareBudgetFocusNode,
              controller: _shareBudgetEmailTextController,
              autofocus: (budgetProvider.selectedBudget.sharedWith != null &&
                      budgetProvider.selectedBudget.sharedWith.length > 1)
                  ? false
                  : true,
              decoration: InputDecoration(
                  fillColor: uiProvider.isLightTheme
                      ? Colors.grey[200]
                      : Colors.grey[850],
                  filled: true,
                  errorStyle: TextStyle(color: Colors.red[300]),
                  hintText: 'Email',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.transparent)),
                  focusedBorder: UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.transparent)),
                  enabledBorder: UnderlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.transparent))),
              validator: (value) {
                if (value.isEmpty) {
                  return 'Email can\'t be empty';
                }

                if (EmailValidator.validate(value) != true) {
                  return 'Invalid email address';
                }

                if (budgetProvider.selectedBudget.sharedWith != null &&
                    budgetProvider.selectedBudget.sharedWith
                        .contains(value.toLowerCase())) {
                  return 'Budget shared with user already';
                }
              },
              onFieldSubmitted: (value) async {
                _shareBudget();
                _shareBudgetEmailTextController.text = '';
              },
              onSaved: (value) {
                _email = value;
              },
            ),
          ));
    }

    Widget _showSharedWithText() {
      return (budgetProvider.selectedBudget.sharedWith != null &&
              budgetProvider.selectedBudget.sharedWith.length > 1)
          ? Padding(
              padding: const EdgeInsets.fromLTRB(0, 42.0, 0, 12),
              child: Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Shared with:",
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: uiProvider.isLightTheme
                          ? Colors.grey[700]
                          : Colors.grey[400]),
                ),
              ),
            )
          : Container();
    }

    Widget _showSharedWithList() {
      if (budgetProvider.selectedBudget.sharedWith != null &&
          budgetProvider.selectedBudget.sharedWith.length > 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
                child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView.separated(
                  separatorBuilder: (context, index) {
                    return Divider(
                      color: Colors.grey[400],
                    );
                  },
                  physics: BouncingScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _users.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (budgetProvider.selectedBudget.isShared &&
                        _users.length > 1) {
                      User user;
                      if (_users != null) {
                        user = _users[index];
                      }

                      String photo;
                      if (user != null) {
                        photo = user.photo;
                      }
                      return user.email == widget.budget.createdBy
                          ? ListTile(
                              contentPadding:
                                  EdgeInsets.only(left: 0.0, right: 0.0),
                              leading: user != null && photo != null
                                  ? CircleAvatar(
                                      backgroundColor: uiProvider.isLightTheme
                                          ? Colors.grey[200]
                                          : Colors.grey[600],
                                      child: Container(
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle),
                                        width: double.infinity,
                                        height: double.infinity,
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(180),
                                          child: FadeInImage(
                                            fit: BoxFit.cover,
                                            placeholder:
                                                MemoryImage(kTransparentImage),
                                            image: MemoryImage(base64Decode(
                                                _users[index].photo)),
                                          ),
                                        ),
                                      ),
                                    )
                                  : CircleAvatar(
                                      backgroundColor: Color(0xffeae7ec),
                                      child: AutoSizeText(
                                        "${_users[index].name[0]}",
                                        style: TextStyle(
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.w600,
                                            fontSize: 20),
                                      ),
                                    ),
                              title: AutoSizeText(
                                user.name,
                                maxLines: 1,
                                style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    color: uiProvider.isLightTheme
                                        ? Colors.grey[700]
                                        : Colors.grey[400]),
                              ),
                              subtitle: AutoSizeText(
                                user.email,
                                maxLines: 1,
                                style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    color: uiProvider.isLightTheme
                                        ? Colors.grey[700]
                                        : Colors.grey[400]),
                              ),
                              trailing: user.email == widget.budget.createdBy
                                  ? user.email == widget.user.email
                                      ? Text(
                                          "(Me)",
                                          style: TextStyle(
                                              color: uiProvider.isLightTheme
                                                  ? Colors.grey[700]
                                                  : Colors.grey[400]),
                                        )
                                      : Text(
                                          "(Owner)",
                                          style: TextStyle(
                                              color: uiProvider.isLightTheme
                                                  ? Colors.grey[700]
                                                  : Colors.grey[400]),
                                        )
                                  : Text(""),
                            )
                          : OnSlide(
                              backgroundColor: uiProvider.isLightTheme
                                  ? Colors.white
                                  : Colors.grey[900],
                              items: <ActionItems>[
                                new ActionItems(
                                    icon: new IconButton(
                                      padding: EdgeInsets.only(left: 35.0),
                                      icon: new Icon(Icons.delete),
                                      onPressed: () {},
                                      color: uiProvider.isLightTheme
                                          ? Colors.grey[700]
                                          : Colors.grey[300],
                                    ),
                                    onPress: () {
                                      showAlertDialog(
                                          context,
                                          user.email == widget.user.email
                                              ? "Remove yourself?"
                                              : "Remove ${user.name}?",
                                          user.email == widget.user.email
                                              ? "You will no longer be able to see this budget"
                                              : "${user.name} will no longer be able to see this budget",
                                          [
                                            FlatButton(
                                              child: Text(
                                                'Close',
                                                style: TextStyle(
                                                    color: Colors.grey),
                                              ),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            FlatButton(
                                              child: Text(
                                                'Remove',
                                                style: TextStyle(
                                                    color: uiProvider
                                                            .isLightTheme
                                                        ? Colors.black
                                                            .withOpacity(0.9)
                                                        : Colors.white
                                                            .withOpacity(0.9),
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _removeShared(user.email);
                                                });
                                                Navigator.pop(context);
                                              },
                                            )
                                          ]);
                                    },
                                    backgroundColor: Colors.transparent),
                              ],
                              child: ListTile(
                                contentPadding:
                                    EdgeInsets.only(left: 0.0, right: 0.0),
                                leading: user != null && photo != null
                                    ? CircleAvatar(
                                        backgroundColor: uiProvider.isLightTheme
                                            ? Colors.grey[200]
                                            : Colors.grey[600],
                                        child: Container(
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle),
                                          width: double.infinity,
                                          height: double.infinity,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(180),
                                            child: FadeInImage(
                                              fit: BoxFit.cover,
                                              placeholder: MemoryImage(
                                                  kTransparentImage),
                                              image: MemoryImage(base64Decode(
                                                  _users[index].photo)),
                                            ),
                                          ),
                                        ),
                                      )
                                    : CircleAvatar(
                                        backgroundColor: Color(0xffeae7ec),
                                        child: AutoSizeText(
                                          "${_users[index].name[0]}",
                                          style: TextStyle(
                                              color: Colors.grey[800],
                                              fontWeight: FontWeight.w600,
                                              fontSize: 20),
                                        ),
                                      ),
                                title: AutoSizeText(
                                  user.name,
                                  maxLines: 1,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: uiProvider.isLightTheme
                                          ? Colors.grey[800]
                                          : Colors.white),
                                ),
                                subtitle: AutoSizeText(
                                  user.email,
                                  maxLines: 1,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: uiProvider.isLightTheme
                                          ? Colors.grey[900]
                                          : Colors.grey[100]),
                                ),
                                trailing: user.email == widget.user.email
                                    ? Text(
                                        "(Me)",
                                        style: TextStyle(
                                            color: uiProvider.isLightTheme
                                                ? Colors.grey[700]
                                                : Colors.grey[400]),
                                      )
                                    : Text(""),
                                onTap: () {
                                  showAlertDialog(
                                      context,
                                      user.email == widget.user.email
                                          ? "Remove yourself?"
                                          : "Remove ${user.name}?",
                                      user.email == widget.user.email
                                          ? "You will no longer be able to see this budget"
                                          : "${user.name} will no longer be able to see this budget",
                                      [
                                        FlatButton(
                                          child: Text(
                                            'Close',
                                            style:
                                                TextStyle(color: Colors.grey),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        FlatButton(
                                          child: Text(
                                            'Remove',
                                            style: TextStyle(
                                                color: uiProvider.isLightTheme
                                                    ? Colors.black
                                                        .withOpacity(0.9)
                                                    : Colors.white
                                                        .withOpacity(0.9),
                                                fontWeight: FontWeight.bold),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _removeShared(user.email);
                                            });
                                            Navigator.pop(context);
                                          },
                                        )
                                      ]);
                                },
                              ),
                            );
                    }
                  }),
            ))
          ],
        );
      } else {
        return Container();
      }
    }

    Widget _showBody() {
      return Container(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _shareBudgetFormKey,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Column(
                    children: <Widget>[_showIcon(), _showHelpText()],
                  ),
                  flex: 0,
                ),
                _showEmailTextFormField(),
                _showSharedWithText(),
                Expanded(
                  child: _showSharedWithList(),
                )
              ],
            ),
          ));
    }

    // Swipe down to close
    return GestureDetector(
        onPanStart: (details) {
          _initialDragAmount = details.globalPosition.dy;
        },
        onPanUpdate: (details) {
          _finalDragAmount = details.globalPosition.dy - _initialDragAmount;
        },
        onPanEnd: (details) {
          if (_finalDragAmount > 0) {
            FocusScope.of(context).requestFocus(new FocusNode());
            Navigator.pop(context);
          }
        },
        onTap: () {
          _shareBudgetFocusNode.unfocus();
        },
        child: Scaffold(
          backgroundColor:
              uiProvider.isLightTheme ? Colors.white : Colors.grey[900],
          appBar: AppBar(
            title: AutoSizeText("Share ${budgetProvider.selectedBudget.name}",
                maxLines: 1,
                style: TextStyle(
                  color: uiProvider.isLightTheme ? Colors.black : Colors.white,
                )),
            backgroundColor:
                uiProvider.isLightTheme ? Colors.white : Colors.black,
            textTheme: TextTheme(
                title: TextStyle(color: Colors.black87, fontSize: 20.0)),
            iconTheme: IconThemeData(
                color:
                    uiProvider.isLightTheme ? Colors.grey[700] : Colors.white),
            brightness:
                uiProvider.isLightTheme ? Brightness.light : Brightness.dark,
            elevation: 0.0,
          ),
          body: Stack(
            children: <Widget>[
              _showBody(),
              showCircularProgress(context),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            elevation: 0,
            backgroundColor: Colors.grey[300],
            foregroundColor: Colors.black87,
            child: Icon(Icons.check),
            onPressed: () async {
              _shareBudget();
              _shareBudgetEmailTextController.text = '';
            },
          ),
        ));
  }
}
