import 'dart:ui';
import 'dart:io' show Platform;
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
  var _emailTextController = TextEditingController();
  var _emailFocusNode = FocusNode();
  var _passwordFocusNode = FocusNode();
  var _passwordRecoveryEmailController = TextEditingController();
  var _nameFocusNode = FocusNode();

  String _email;
  String _password;
  String _name;
  String _errorMessage;

  // Initial form is login form
  FormMode _formMode = FormMode.LOGIN;

  @override
  void initState() {
    _errorMessage = "";
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _nameFocusNode.dispose();
    // Clean up the controller when the widget is removed from the
    // widget tree.
    _emailTextController.dispose();
    _passwordRecoveryEmailController.dispose();
    super.dispose();
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

    Widget _showPasswordRecoveryButton() {
      return FlatButton(
        padding: EdgeInsets.only(top: 1.0),
        child: _formMode == FormMode.LOGIN
            ? Text('Trouble signing in?',
                style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w200))
            : SizedBox.shrink(),
        onPressed: _formMode == FormMode.LOGIN
            ? () {
                _passwordRecoveryEmailController.text =
                    _emailTextController.text;
                showInputDialog(
                    context,
                    Colors.white,
                    Text("Reset Password"),
                    "Get instructions sent to this email that explain how to reset your password",
                    [
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
                          style:
                              TextStyle(color: Theme.of(context).primaryColor),
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          setState(() {
                            uiProvider.isLoading = true;
                          });

                          try {
                            if (_passwordRecoveryEmailController.text != "" &&
                                _passwordRecoveryEmailController.text != null) {
                              setState(() {
                                uiProvider.isLoading = false;
                              });
                              await authProvider.auth.sendPasswordRecoveryEmail(
                                  _passwordRecoveryEmailController.text);
                              showAlertDialog(context, "Success",
                                  "Check your email to reset your password", [
                                FlatButton(
                                  child: Text(
                                    'OK',
                                    style: TextStyle(
                                        color: uiProvider.isLightTheme
                                            ? Colors.black
                                            : Colors.white),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                )
                              ]);
                            } else {
                              setState(() {
                                uiProvider.isLoading = false;
                              });
                            }
                          } catch (e) {
                            setState(() {
                              uiProvider.isLoading = false;
                            });
                            showAlertDialog(context, "Try again", e.message, [
                              FlatButton(
                                child: Text(
                                  'OK',
                                  style: TextStyle(
                                      color: uiProvider.isLightTheme
                                          ? Colors.black
                                          : Colors.white),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              )
                            ]);
                          }
                        },
                      ),
                    ],
                    Container(
                      padding: EdgeInsets.only(top: 7.0),
                      child: TextField(
                        controller: _passwordRecoveryEmailController,
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
      showAlertDialog(context, "Verify your account",
          "Link to verify account has been sent to your email", [
        FlatButton(
          child: Text(
            'OK',
            style: TextStyle(
                color: uiProvider.isLightTheme ? Colors.black : Colors.white),
          ),
          onPressed: () {
            _changeFormToLogin();
            Navigator.of(context).pop();
          },
        )
      ]);
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
            userId = await authProvider.auth.signUp(_email, _password, _name);
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
            showAlertDialog(context, "Yo", _errorMessage, [
              FlatButton(
                child: Text('OK',
                    style: TextStyle(
                        color: uiProvider.isLightTheme
                            ? Colors.black
                            : Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ]);
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
          focusNode: _emailFocusNode,
          controller: _emailTextController,
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
            _emailFocusNode.unfocus();

            if (_formMode == FormMode.LOGIN) {
              FocusScope.of(context).requestFocus(_passwordFocusNode);
            } else {
              FocusScope.of(context).requestFocus(_nameFocusNode);
            }
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
          focusNode: _passwordFocusNode,
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

    Widget _showNameInput() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 15.0, 10.0, 0.0),
        child: TextFormField(
          cursorColor: Colors.black87,
          keyboardAppearance: Brightness.dark,
          maxLines: 1,
          autofocus: false,
          decoration: InputDecoration(
              hintText: 'Name',
              icon: Icon(
                Icons.person,
                color: Colors.grey[400],
              )),
          focusNode: _nameFocusNode,
          onFieldSubmitted: (value) {
            _nameFocusNode.unfocus();
            FocusScope.of(context).requestFocus(_passwordFocusNode);
          },
          validator: (value) {
            if (value.isEmpty) {
              setState(() {
                uiProvider.isLoading = false;
              });
              return 'Name can\'t be empty';
            }
          },
          onSaved: (value) => _name = value,
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
                _formMode == FormMode.SIGNUP ? _showNameInput() : Container(),
                _showPasswordInput(),
                _showPasswordRecoveryButton(),
                _showPrimaryButton(),
                _showSecondaryButton(),
              ],
            ),
          ));
    }

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: _formMode == FormMode.LOGIN ? Text("Login") : Text("Sign Up"),
          backgroundColor: Colors.white,
          textTheme: TextTheme(
              title: TextStyle(
                  color: Colors.black87,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w500)),
          iconTheme: IconThemeData(color: Colors.black87),
          brightness: Platform.isAndroid ? Brightness.dark : Brightness.light,
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
