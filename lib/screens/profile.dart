import 'dart:convert';
import 'dart:io';

import 'package:Groovy/providers/ui_provider.dart';
import 'package:Groovy/providers/user_provider.dart';
import 'package:Groovy/screens/shared/utilities.dart';
import 'package:Groovy/services/auth_service.dart';
import 'package:Groovy/services/budget_service.dart';
import 'package:Groovy/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen(
      {Key key,
      this.auth,
      this.userProvider,
      this.userService,
      this.budgetService,
      this.user,
      this.onSignedOut})
      : super(key: key);

  final BaseAuth auth;
  final UserProvider userProvider;
  final UserService userService;
  final BudgetService budgetService;
  final VoidCallback onSignedOut;
  final FirebaseUser user;

  @override
  State<StatefulWidget> createState() => _ProfileScreen();
}

class _ProfileScreen extends State<ProfileScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  Image _image;
  final _currency = NumberFormat.simpleCurrency();
  SharedPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _initPreferences();
    _initImage();
  }

  void _initPreferences() async {
    _preferences = await SharedPreferences.getInstance();
  }

  void _initImage() {
    if (widget.userProvider.currentUser.photo != null) {
      setState(() {
        _image =
            Image.memory(base64Decode(widget.userProvider.currentUser.photo));
      });
    } else {
      _image = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    var uiProvider = Provider.of<UIProvider>(context);
    var userProvider = Provider.of<UserProvider>(context);

    Future<void> _updateUserWithNewImage(File image) async {
      setState(() {
        _image = Image.file(image);
      });

      // get blob for image
      var imageAsBlob = base64Encode(image.readAsBytesSync());

      // update user's photo
      userProvider.currentUser.photo = imageAsBlob;

      // update user
      widget.userService.updateUser(_database, userProvider.currentUser);
    }

    Future _getCameraImage() async {
      var image = await ImagePicker.pickImage(source: ImageSource.camera);
      _updateUserWithNewImage(image);
    }

    Future _getGalleryImage() async {
      var image = await ImagePicker.pickImage(source: ImageSource.gallery);
      _updateUserWithNewImage(image);
    }

    void _showImagePickerModal() {
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
                              Icons.camera_alt,
                              color: uiProvider.isLightTheme
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                          Text('Camera',
                              style: TextStyle(
                                  fontSize: 18.0,
                                  color: uiProvider.isLightTheme
                                      ? Colors.black
                                      : Colors.white))
                        ],
                      ),
                      onPressed: () {
                        // close modal
                        Navigator.pop(context);
                        _getCameraImage();
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
                              Icons.photo_library,
                              color: uiProvider.isLightTheme
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                          Text('Gallery',
                              style: TextStyle(
                                  fontSize: 18.0,
                                  color: uiProvider.isLightTheme
                                      ? Colors.black
                                      : Colors.white))
                        ],
                      ),
                      onPressed: () {
                        // close modal
                        Navigator.pop(context);
                        _getGalleryImage();
                      },
                    ),
                  ))
            ],
          ),
          160.0);
    }

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
          Expanded(
            flex: 0,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  color: uiProvider.isLightTheme
                      ? Color(0xffd8d9f4).withOpacity(0.5)
                      : Colors.black,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12.0),
                      bottomRight: Radius.circular(12.0))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(left: 16, top: 60),
                    child: GestureDetector(
                      onTap: () {
                        _showImagePickerModal();
                      },
                      child: Container(
                        width: 85.0,
                        height: 85.0,
                        child: _image == null
                            ? CircleAvatar(
                                backgroundColor: Colors.grey[100],
                                child: Center(
                                  child: Icon(
                                    Icons.add_a_photo,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : CircleAvatar(
                                backgroundColor: Colors.grey[100],
                                backgroundImage: _image.image,
                              ),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                                color: uiProvider.isLightTheme
                                    ? Color(0xffcfcfe8).withOpacity(0.7)
                                    : Colors.black.withOpacity(0.5),
                                offset: Offset(0, 6.0),
                                blurRadius: 15,
                                spreadRadius: 2),
                          ],
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.all(Radius.circular(180.0)),
                          border: Border.all(
                            color: uiProvider.isLightTheme
                                ? Colors.white
                                : Colors.grey[800],
                            width: 5.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 16, top: 22.0),
                    child: Container(
                      child: widget.user.displayName != null
                          ? Text(
                              widget.user.displayName,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: uiProvider.isLightTheme
                                      ? Colors.black
                                      : Colors.white),
                            )
                          : SizedBox.shrink(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 16, top: 4.0, bottom: 26),
                    child: Container(
                      child: widget.user.email != null
                          ? Text(
                              widget.user.email,
                              style: TextStyle(
                                  color: uiProvider.isLightTheme
                                      ? Colors.black
                                      : Colors.white),
                            )
                          : SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.only(left: 4.0, top: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "budgets",
                          style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w600,
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
                                color: uiProvider.isLightTheme
                                    ? Colors.grey[700]
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
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "total spent",
                          style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w600,
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
                                color: uiProvider.isLightTheme
                                    ? Colors.grey[700]
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
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "total left",
                          style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w600,
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
                                color: uiProvider.isLightTheme
                                    ? Colors.grey[700]
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
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "theme",
                          style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w600,
                              color: uiProvider.isLightTheme
                                  ? Colors.black87
                                  : Colors.grey),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
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
                                      backgroundColor: Colors.white,
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
                  )
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: <Widget>[
        Scaffold(
          appBar: AppBar(
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
        _showProfile()
      ],
    );
  }
}
