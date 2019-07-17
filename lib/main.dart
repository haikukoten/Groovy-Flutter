import 'package:Groovy/providers/user_provider.dart';
import 'package:Groovy/screens/budget_detail/budget_history.dart';
import 'package:Groovy/screens/budget_detail/edit_history.dart';
import 'package:Groovy/screens/budget_detail/share_budget.dart';
import 'package:Groovy/screens/budget_list/create_budget.dart';
import 'package:Groovy/screens/request_notifications.dart';
import 'package:Groovy/services/budget_service.dart';
import 'package:Groovy/services/user_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Groovy/screens/login/email_login.dart';
import 'package:Groovy/services/auth_service.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/login/determine_auth_status.dart';
import 'screens/budget_detail/budget_detail.dart';
import 'screens/budget_detail/edit_budget.dart';
import 'screens/budget_detail/budget_history.dart';
import 'providers/auth_provider.dart';
import 'providers/ui_provider.dart';
import 'providers/budget_provider.dart';
import 'package:overlay_support/overlay_support.dart';

// TODO: Update Android nav bar colors
// TODO: Adjust detail screen circular progress radius for smaller displays?

void main() {
  kNotificationSlideDuration = const Duration(milliseconds: 500);
  kNotificationDuration = const Duration(milliseconds: 3500);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    dynamic _buildRoute(RouteSettings settings, Widget builder) {
      return MaterialPageRoute(
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
              auth: AuthService(),
              userService: UserService(),
              budgetService: BudgetService(),
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
        case '/budgetHistory':
          return _buildRoute(
            settings,
            BudgetHistoryScreen(
              budget: settings.arguments,
            ),
          );
          break;
        case '/editHistory':
          return _buildRoute(
            settings,
            EditHistoryScreen(
              history: settings.arguments,
            ),
          );
          break;
        case '/shareBudget':
          return _buildRoute(
            settings,
            ShareBudgetScreen(
              budget: settings.arguments,
            ),
          );
          break;
        case '/requestNotifications':
          return _buildRoute(
            settings,
            RequestNotificationsScreen(),
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
        ChangeNotifierProvider<UserProvider>(
          builder: (context) => UserProvider(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          builder: (context) => AuthProvider(),
        ),
        ChangeNotifierProvider<UIProvider>(
          builder: (context) => UIProvider(),
        ),
      ],
      child: OverlaySupport(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateRoute: _getRoute,
          title: 'Groovy',
          theme: ThemeData(
              primaryColor: Colors.black, canvasColor: Colors.transparent),
        ),
      ),
    );
  }
}
