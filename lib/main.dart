import 'package:Groovy/screens/create_budget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Groovy/screens/login/email_login.dart';
import 'package:Groovy/services/auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/login/determine_auth_status.dart';
import 'screens/budget_detail.dart';
import 'screens/edit_budget.dart';
import 'providers/auth_provider.dart';
import 'providers/ui_provider.dart';
import 'providers/budget_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    dynamic _buildRoute(RouteSettings settings, Widget builder) {
      return new MaterialPageRoute(
        settings: settings,
        builder: (ctx) => builder,
      );
    }

    Route<dynamic> _getRoute(RouteSettings settings) {
      switch (settings.name) {
        case '/':
          return _buildRoute(
            settings,
            DetermineAuthStatusScreen(
              auth: Auth(),
            ),
          );
          break;
        case '/emailLogin':
          return _buildRoute(
            settings,
            EmailLoginScreen(),
          );
          break;
        case '/budgetDetail':
          return _buildRoute(
            settings,
            BudgetDetailScreen(),
          );
          break;
        case '/createBudget':
          return _buildRoute(
            settings,
            CreateBudgetScreen(),
          );
          break;
        case '/editBudget':
          return _buildRoute(
            settings,
            EditBudgetScreen(
              budget: settings.arguments,
            ),
          );
          break;
        default:
          return null;
      }
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BudgetProvider>(
          builder: (context) => BudgetProvider(),
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
        onGenerateRoute: _getRoute,
        title: 'Groovy',
        theme: ThemeData(
            primaryColor: Colors.black, canvasColor: Colors.transparent),
      ),
    );
  }
}
