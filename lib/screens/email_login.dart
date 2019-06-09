import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:groovy/models/budget.dart';

class EmailLoginScreen extends StatefulWidget {
  EmailLoginScreen({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new _EmailLoginScreen();
}

enum FormMode { LOGIN, SIGNUP }

class _EmailLoginScreen extends State<EmailLoginScreen> {
  final _formKey = new GlobalKey<FormState>();

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
      _formKey.currentState.reset();
      _errorMessage = "";
      setState(() {
        _formMode = FormMode.SIGNUP;
      });
    }

    void _changeFormToLogin() {
      _formKey.currentState.reset();
      _errorMessage = "";
      setState(() {
        _formMode = FormMode.LOGIN;
      });
    }

    Widget _showCircularProgress() {
      if (_isLoading) {
        return Center(child: CircularProgressIndicator());
      }
      return Container(
        height: 0.0,
        width: 0.0,
      );
    }

    Widget _showErrorMessage() {
      if (_errorMessage != null && _errorMessage.length > 0) {
        return new Text(
          _errorMessage,
          style: TextStyle(
              fontSize: 13.0,
              color: Colors.red,
              height: 1.0,
              fontWeight: FontWeight.w300),
        );
      } else {
        return new Container(
          height: 0.0,
        );
      }
    }

    Widget _showEmailInput() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 100.0, 0.0, 0.0),
        child: new TextFormField(
          maxLines: 1,
          keyboardType: TextInputType.emailAddress,
          autofocus: false,
          decoration: new InputDecoration(
              hintText: 'Email',
              icon: new Icon(
                Icons.mail,
                color: Colors.grey,
              )),
          validator: (value) {
            if (value.isEmpty) {
              setState(() {
                _isLoading = false;
              });
              return 'Email can\'t be empty';
            }
          },
          onSaved: (value) => _email = value,
        ),
      );
    }

    Widget _showPasswordInput() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
        child: new TextFormField(
          maxLines: 1,
          obscureText: true,
          autofocus: false,
          decoration: new InputDecoration(
              hintText: 'Password',
              icon: new Icon(
                Icons.lock,
                color: Colors.grey,
              )),
          validator: (value) {
            if (value.isEmpty) {
              setState(() {
                _isLoading = false;
              });
              return 'Email can\'t be empty';
            }
          },
          onSaved: (value) => _password = value,
        ),
      );
    }

    Widget _showSecondaryButton() {
      return new FlatButton(
        child: _formMode == FormMode.LOGIN
            ? new Text('Create an account',
                style:
                    new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300))
            : new Text('Have an account? Sign in',
                style:
                    new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
        onPressed: _formMode == FormMode.LOGIN
            ? _changeFormToSignUp
            : _changeFormToLogin,
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
      showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            title: new Text("Verify your account"),
            content:
                new Text("Link to verify account has been sent to your email"),
            actions: <Widget>[
              new FlatButton(
                child: new Text("Dismiss"),
                onPressed: () {
                  _changeFormToLogin();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
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
          });
        }
      }
    }

    Widget _showPrimaryButton() {
      return new Padding(
          padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
          child: SizedBox(
            height: 40.0,
            child: new RaisedButton(
              elevation: 5.0,
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(30.0)),
              color: Colors.blue,
              child: _formMode == FormMode.LOGIN
                  ? new Text('Login',
                      style: new TextStyle(fontSize: 20.0, color: Colors.white))
                  : new Text('Create account',
                      style:
                          new TextStyle(fontSize: 20.0, color: Colors.white)),
              onPressed: _validateAndSubmit,
            ),
          ));
    }

    Widget _showBody() {
      return new Container(
          padding: EdgeInsets.all(16.0),
          child: new Form(
            key: _formKey,
            child: new ListView(
              shrinkWrap: true,
              children: <Widget>[
                _showEmailInput(),
                _showPasswordInput(),
                _showPrimaryButton(),
                _showSecondaryButton(),
                _showErrorMessage(),
              ],
            ),
          ));
    }

    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Flutter login demo'),
        ),
        body: Stack(
          children: <Widget>[
            _showBody(),
            _showCircularProgress(),
          ],
        ));
  }
}
