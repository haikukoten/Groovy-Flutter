import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:groovy/models/budget.dart';

class EmailLoginScreen extends StatefulWidget {
  EmailLoginScreen({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EmailLoginScreen();
}

enum FormMode { LOGIN, SIGNUP }

class _EmailLoginScreen extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  var emailTextController = TextEditingController();
  var passwordFocusNode = FocusNode();
  var passwordRecoveryEmailController = TextEditingController();

  String _email;
  String _password;
  String _errorMessage;

  // Initial form is login form
  FormMode _formMode = FormMode.LOGIN;
  bool _isLoading;

  @override
  void initState() {
    _errorMessage = "";
    _isLoading = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Access to auth and onSignedIn from ChooseLogin
    var budgetModel = Provider.of<BudgetModel>(context);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    void _changeFormToSignUp() {
      _errorMessage = "";
      setState(() {
        _formMode = FormMode.SIGNUP;
      });
    }

    void _changeFormToLogin() {
      _errorMessage = "";
      setState(() {
        _formMode = FormMode.LOGIN;
      });
    }

    Widget _showCircularProgress() {
      if (_isLoading) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.grey[100].withOpacity(0.8),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }
      return Container(
        height: 0.0,
        width: 0.0,
      );
    }

    Future<void> _showDialog(String title, String message,
        [Function func]) async {
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(message),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0))),
            actions: <Widget>[
              FlatButton(
                child: Text('OK'),
                onPressed: () {
                  if (func != null) {
                    func();
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    Future<void> _showInputDialog(String title, String message,
        [Widget input, Function func]) async {
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(message),
                  input != null ? input : null,
                ],
              ),
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0))),
            actions: <Widget>[
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
                  'Send',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  setState(() {
                    _isLoading = true;
                  });

                  if (title == "Reset Password") {
                    try {
                      if (passwordRecoveryEmailController.text != "" &&
                          passwordRecoveryEmailController.text != null) {
                        await func(passwordRecoveryEmailController.text);
                        _isLoading = false;
                        _showDialog("Success",
                            "Check your email to reset your password");
                      } else {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    } catch (e) {
                      setState(() {
                        _isLoading = false;
                        _showDialog("Email cannot send", e.message);
                      });
                    }
                  }
                },
              ),
            ],
          );
        },
      );
    }

    Widget _showPasswordRecoveryButton() {
      return FlatButton(
        padding: EdgeInsets.only(top: 1.0),
        child: _formMode == FormMode.LOGIN &&
                emailTextController.text.isNotEmpty
            ? Text('Trouble signing in?',
                style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w200))
            : SizedBox.shrink(),
        onPressed: _formMode == FormMode.LOGIN
            ? () {
                passwordRecoveryEmailController.text = emailTextController.text;
                _showInputDialog(
                    "Reset Password",
                    "Instructions to reset your password will be sent to:",
                    Container(
                      padding: EdgeInsets.only(top: 7.0),
                      child: TextField(
                        controller: passwordRecoveryEmailController,
                        enabled: false,
                      ),
                    ),
                    budgetModel.auth.sendPasswordRecoveryEmail);
              }
            : null,
      );
    }

    // Check if form is valid before perform login or signup
    bool _validateAndSave() {
      final form = _formKey.currentState;
      if (form.validate()) {
        form.save();
        return true;
      }
      return false;
    }

    void _showVerifyEmailSentDialog() {
      _showDialog(
          "Verify your account",
          "Link to verify account has been sent to your email",
          _changeFormToLogin);
    }

    // Perform login or signup
    void _validateAndSubmit() async {
      setState(() {
        _errorMessage = "";
        _isLoading = true;
      });
      if (_validateAndSave()) {
        String userId = "";
        try {
          if (_formMode == FormMode.LOGIN) {
            userId = await budgetModel.auth.signIn(_email, _password);
            print('Signed in: $userId');
          } else {
            userId = await budgetModel.auth.signUp(_email, _password);
            budgetModel.auth.sendEmailVerification();
            _showVerifyEmailSentDialog();
            print('Signed up user: $userId');
          }
          setState(() {
            _isLoading = false;
          });

          if (userId != null &&
              userId.length > 0 &&
              _formMode == FormMode.LOGIN) {
            budgetModel.onSignedIn();
          }
        } catch (e) {
          print('Error: $e');
          setState(() {
            _isLoading = false;
            _errorMessage = e.message;
            _showDialog("Yo", _errorMessage);
          });
        }
      }
    }

    Widget _showEmailInput() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 25.0, 10.0, 0.0),
        child: TextFormField(
          maxLines: 1,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          controller: emailTextController,
          decoration: InputDecoration(
              hintText: 'Email',
              icon: Icon(
                Icons.mail,
                color: Colors.grey[400],
              )),
          validator: (value) {
            if (value.isEmpty) {
              setState(() {
                _isLoading = false;
              });
              return 'Email can\'t be empty';
            }
          },
          onFieldSubmitted: (value) {
            FocusScope.of(context).requestFocus(passwordFocusNode);
          },
          onSaved: (value) => _email = value,
        ),
      );
    }

    Widget _showPasswordInput() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 15.0, 10.0, 0.0),
        child: TextFormField(
          maxLines: 1,
          obscureText: true,
          autofocus: false,
          decoration: InputDecoration(
              hintText: 'Password',
              icon: Icon(
                Icons.lock,
                color: Colors.grey[400],
              )),
          focusNode: passwordFocusNode,
          onFieldSubmitted: (value) {
            _validateAndSubmit();
          },
          validator: (value) {
            if (value.isEmpty) {
              setState(() {
                _isLoading = false;
              });
              return 'Password can\'t be empty';
            }
          },
          onSaved: (value) => _password = value,
        ),
      );
    }

    Widget _showPrimaryButton() {
      return Padding(
          padding: EdgeInsets.fromLTRB(50.0, 15.0, 50.0, 0.0),
          child: SizedBox(
            height: 55.0,
            child: RaisedButton(
              elevation: 5.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0)),
              color: Theme.of(context).primaryColor,
              child: _formMode == FormMode.LOGIN
                  ? Text('Login',
                      style: TextStyle(fontSize: 20.0, color: Colors.white))
                  : Text('Sign Up',
                      style: TextStyle(fontSize: 20.0, color: Colors.white)),
              onPressed: _validateAndSubmit,
            ),
          ));
    }

    Widget _showSecondaryButton() {
      return FlatButton(
        padding: EdgeInsets.only(top: 12.0),
        child: _formMode == FormMode.LOGIN
            ? Text('Create an account',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300))
            : Text('Have an account? Login',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
        onPressed: _formMode == FormMode.LOGIN
            ? _changeFormToSignUp
            : _changeFormToLogin,
      );
    }

    Widget _showBody() {
      return Container(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                _showEmailInput(),
                _showPasswordInput(),
                _showPasswordRecoveryButton(),
                _showPrimaryButton(),
                _showSecondaryButton(),
              ],
            ),
          ));
    }

    return Scaffold(
        appBar: AppBar(
          title: _formMode == FormMode.LOGIN ? Text("Login") : Text("Sign Up"),
        ),
        body: Stack(
          children: <Widget>[
            _showBody(),
            _showCircularProgress(),
          ],
        ));
  }
}
