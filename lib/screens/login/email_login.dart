import 'dart:ui';
import 'package:Groovy/providers/auth_provider.dart';
import 'package:Groovy/providers/ui_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../shared/utilities.dart';

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

  @override
  void initState() {
    _errorMessage = "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Access to auth and onSignedIn from ChooseLogin
    var authProvider = Provider.of<AuthProvider>(context);
    var uiProvider = Provider.of<UIProvider>(context);

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
                child: Text(
                  'OK',
                  style: TextStyle(color: Colors.black),
                ),
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

    Widget _showPasswordRecoveryButton() {
      return FlatButton(
        padding: EdgeInsets.only(top: 1.0),
        child: _formMode == FormMode.LOGIN
            ? Text('Trouble signing in?',
                style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w200))
            : SizedBox.shrink(),
        onPressed: _formMode == FormMode.LOGIN
            ? () {
                passwordRecoveryEmailController.text = emailTextController.text;
                showInputDialog(
                    context,
                    Colors.white,
                    Text("Reset Password"),
                    "Get instructions sent to this email that explain how to reset your password",
                    FlatButton(
                      child: Text(
                        'Send',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        setState(() {
                          uiProvider.isLoading = true;
                        });

                        try {
                          if (passwordRecoveryEmailController.text != "" &&
                              passwordRecoveryEmailController.text != null) {
                            setState(() {
                              uiProvider.isLoading = false;
                            });
                            await authProvider.auth.sendPasswordRecoveryEmail(
                                passwordRecoveryEmailController.text);
                            _showDialog("Success",
                                "Check your email to reset your password");
                          } else {
                            setState(() {
                              uiProvider.isLoading = false;
                            });
                          }
                        } catch (e) {
                          setState(() {
                            uiProvider.isLoading = false;
                          });
                          _showDialog("Try again", e.message);
                        }
                      },
                    ),
                    Container(
                      padding: EdgeInsets.only(top: 7.0),
                      child: TextField(
                        controller: passwordRecoveryEmailController,
                        autofocus: true,
                        cursorColor: Colors.black87,
                        keyboardAppearance: Brightness.dark,
                      ),
                    ));
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
        uiProvider.isLoading = true;
      });
      if (_validateAndSave()) {
        String userId = "";
        try {
          if (_formMode == FormMode.LOGIN) {
            userId = await authProvider.auth.signIn(_email, _password);
            print('Signed in: $userId');
            Navigator.of(context)
                .pushNamedAndRemoveUntil("/", (Route<dynamic> route) => false);
          } else {
            userId = await authProvider.auth.signUp(_email, _password);
            authProvider.auth.sendEmailVerification();
            _showVerifyEmailSentDialog();
            print('Signed up user: $userId');
          }
          setState(() {
            uiProvider.isLoading = false;
          });

          if (userId != null &&
              userId.length > 0 &&
              _formMode == FormMode.LOGIN) {
            authProvider.onSignedIn();
          }
        } catch (e) {
          print('Error: $e');
          setState(() {
            uiProvider.isLoading = false;
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
          cursorColor: Colors.black87,
          keyboardAppearance: Brightness.dark,
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
                uiProvider.isLoading = false;
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
          cursorColor: Colors.black87,
          keyboardAppearance: Brightness.dark,
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
                uiProvider.isLoading = false;
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
              elevation: 0.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0)),
              color: Colors.black87,
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
          backgroundColor: Colors.white,
          textTheme: TextTheme(
              title: TextStyle(
                  color: Colors.black87,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w500)),
          iconTheme: IconThemeData(color: Colors.black87),
          brightness: Brightness.light,
          elevation: 0.0,
        ),
        body: Stack(
          children: <Widget>[
            _showBody(),
            showCircularProgress(context),
          ],
        ));
  }
}
