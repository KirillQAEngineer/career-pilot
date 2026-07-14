import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) =>
          Scaffold(body: Center(child: Text(context.tr('route_not_found')))),
    );
  }
}
