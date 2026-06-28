import 'package:flutter/material.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'landing.dart';
import 'device_permission.dart';
import 'control_panel.dart';
import 'device_dashboard.dart';
import 'splash.dart';
import 'owner_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Animasi page transition yang smooth
  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;
        var tween = Tween(begin: const Offset(0.05, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        
        var fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: curve));
        var fadeAnimation = animation.drive(fadeTween);
        
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Netherite',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Made',
        scaffoldBackgroundColor: const Color(0xFF120000),
        colorScheme: ColorScheme.dark().copyWith(
          primary: const Color(0xFFE53935),
          secondary: const Color(0xFFFF5252),
          surface: const Color(0xFF2A0000),
        ),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CustomPageTransitionBuilder(),
            TargetPlatform.iOS: CustomPageTransitionBuilder(),
          },
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return _createRoute(const LandingPage());
          
          case '/login':
            return _createRoute(const LoginPage());
          
          case '/dashboard':
            final args = settings.arguments as Map<String, dynamic>;
            return _createRoute(DashboardPage(
              username: args['username'],
              password: args['password'],
              role: ((args['role'] ?? '').toString()),
              sessionKey: args['key'],
              expiredDate: args['expiredDate'],
              listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
              listDoos: List<Map<String, dynamic>>.from(args['listDoos'] ?? []),
              news: List<Map<String, dynamic>>.from(args['news'] ?? []),
            ));

          case '/owner':
            final args = settings.arguments as Map<String, dynamic>;
            return _createRoute(OwnerPage(
              sessionKey: args['sessionKey'] ?? args['keyToken'] ?? '',
              username: args['username'] ?? '',
            ));

          case '/device-permission':
            final args = settings.arguments as Map<String, dynamic>;
            return _createRoute(DevicePermissionManagerPage(
              sessionKey: args['sessionKey'],
              allDevices: args['allDevices'] ?? [],
            ));

          case '/control-center':
            final args = settings.arguments as Map<String, dynamic>;
            return _createRoute(ControlCenterPage(
              targetDevice: args['targetDevice'],
              role: args['role'] ?? 'member',
            ));

          case '/device-dashboard':
            final args = settings.arguments as Map<String, dynamic>;
            return _createRoute(DeviceDashboardPage(
              username: args['username'],
              role: args['role'],
              sessionKey: args['sessionKey'],
            ));

          default:
            return _createRoute(const Scaffold(
              body: Center(child: Text("404 - Page Not Found")),
            ));
        }
      },
    );
  }
}

// Custom page transition builder
class CustomPageTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const curve = Curves.easeOutCubic;
    var tween = Tween(begin: const Offset(0.03, 0.0), end: Offset.zero)
        .chain(CurveTween(curve: curve));
    var offsetAnimation = animation.drive(tween);
    
    var fadeTween = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: curve));
    var fadeAnimation = animation.drive(fadeTween);
    
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: offsetAnimation,
        child: child,
      ),
    );
  }
}