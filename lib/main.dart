import 'package:flutter/material.dart';
import 'package:Groovy/screens/login/email_login.dart';
import 'package:Groovy/services/auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/login/determine_auth_status.dart';
import 'models/budget.dart';
import 'providers/auth_provider.dart';
import 'providers/ui_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BudgetModel>(
          builder: (context) => BudgetModel(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          builder: (context) => AuthProvider(),
        ),
        ChangeNotifierProvider<UIProvider>(
          builder: (context) => UIProvider(),
        )
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Groovy',
        theme: ThemeData(primaryColor: Colors.black),
        initialRoute: '/',
        routes: {
          '/': (context) => DetermineAuthStatusScreen(
                auth: Auth(),
              ),
          '/emailLogin': (context) => EmailLoginScreen()
        },
      ),
    );
    // return ChangeNotifierProvider(
    //   builder: (context) => BudgetModel(),
    //   child: MaterialApp(
    //     debugShowCheckedModeBanner: false,
    //     title: 'Groovy',
    //     theme: ThemeData(primaryColor: Colors.black),
    //     initialRoute: '/',
    //     routes: {
    //       '/': (context) => DetermineAuthStatusScreen(
    //             auth: Auth(),
    //           ),
    //       '/emailLogin': (context) => EmailLoginScreen()
    //     },
    //   ),
    // );
  }
}
