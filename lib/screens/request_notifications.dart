import 'dart:ui';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared/utilities.dart';
import 'package:gradient_widgets/gradient_widgets.dart';

class RequestNotificationsScreen extends StatefulWidget {
  RequestNotificationsScreen({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RequestNotificationsScreen();
}

class _RequestNotificationsScreen extends State<RequestNotificationsScreen> {
  SharedPreferences _preferences;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  @override
  void initState() {
    super.initState();
    _getSavedPreferences();
    _listenToSettings();
  }

  void _getSavedPreferences() async {
    _preferences = await SharedPreferences.getInstance();
    // User has had the option to choose notification settings
    _preferences.setBool("notifications", true);
  }

  void _listenToSettings() {
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      if (settings.alert == true) {
        Navigator.pop(context);
      }
      print("Settings registered: $settings");
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget _showIcon() {
      return Container(
        child: Center(
          child: Icon(
            Icons.message,
            color: Colors.grey[400],
            size: 75,
          ),
        ),
      );
    }

    Widget _showTitleText() {
      return Padding(
        padding: const EdgeInsets.all(18.0),
        child: Container(
          child: Center(
            child: AutoSizeText(
              "Stay in the loop",
              maxLines: 1,
              style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
            ),
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
              "Find out when someone\nshares a budget with you",
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      );
    }

    Widget _showAcceptButton() {
      return GradientButton(
        increaseWidthBy: 100,
        increaseHeightBy: 20,
        elevation: 0.0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
        gradient: Gradients.buildGradient(Alignment.centerLeft,
            Alignment.centerRight, [Color(0xffd57eeb), Color(0xff8ec5fc)]),
        child: AutoSizeText('Sounds good',
            maxLines: 1,
            style: TextStyle(
                fontSize: 20.0,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        callback: () {
          _firebaseMessaging.requestNotificationPermissions(
              IosNotificationSettings(sound: true, badge: true, alert: true));
        },
      );
    }

    Widget _showDeclineButton() {
      return FlatButton(
        padding: EdgeInsets.only(top: 12.0),
        child: AutoSizeText('Not now',
            maxLines: 1,
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
        onPressed: () {
          Navigator.pop(context);
        },
      );
    }

    Widget _showBody() {
      return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
                flex: 7,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _showIcon(),
                    _showTitleText(),
                    _showHelpText()
                  ],
                )),
            Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[_showAcceptButton(), _showDeclineButton()],
                )),
          ]);
    }

    return Scaffold(
        appBar: AppBar(
          brightness: Brightness.light,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        backgroundColor: Colors.white,
        body: Stack(
          children: <Widget>[
            _showBody(),
            showCircularProgress(context),
          ],
        ));
  }
}
