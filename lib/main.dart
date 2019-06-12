import 'package:flutter/material.dart';
import 'package:Groovy/screens/email_login.dart';
import 'package:Groovy/services/auth.dart';
import 'package:provider/provider.dart';
import 'screens/determine_auth_status.dart';
import 'models/budget.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      builder: (context) => BudgetModel(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Groovy',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => DetermineAuthStatusScreen(
                auth: Auth(),
              ),
          '/emailLogin': (context) => EmailLoginScreen()
        },
      ),
    );
  }
}
