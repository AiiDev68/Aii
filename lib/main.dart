// ============================================================
//  ArchiverZ — Application entry point
//  Rebranded from PPL V4 → ArchiverZ v4.0.0
// ============================================================
import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'config/api.dart';
import 'core/design_system.dart';
import 'login_page.dart';
import 'loader_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'admin_page.dart';
import 'buy_account.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.loadGh();
  runApp(const ArchiverZApp());
}

class ArchiverZApp extends StatelessWidget {
  const ArchiverZApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: archiverZTheme(),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const LoginPage());

          case '/buy_account':
            return MaterialPageRoute(builder: (_) => const BuyAccountPage());

          case '/loader':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => DashboardPage(
                username: args['username'],
                password: args['password'],
                role: args['role'],
                sessionKey: args['key'],
                expiredDate: args['expiredDate'],
                listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                listPayload: List<Map<String, dynamic>>.from(args['listPayload'] ?? []),
                listDDoS: List<Map<String, dynamic>>.from(args['listDDoS'] ?? []),
                news: List<Map<String, dynamic>>.from(args['news'] ?? []),
              ),
            );

          case '/attack':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => AttackPage(
                username: args['username'],
                password: args['password'],
                listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                role: args['role'],
                expiredDate: args['expiredDate'],
                sessionKey: args['sessionKey'],
              ),
            );

          case '/seller':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => SellerPage(
                keyToken: args['keyToken'],
              ),
            );

          case '/admin':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => AdminPage(
                sessionKey: args['sessionKey'],
              ),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                backgroundColor: ArchiverZColors.bg,
                body: Center(
                  child: Text(
                    "404 — Not Found",
                    style: TextStyle(
                      color: ArchiverZColors.textDim,
                      fontFamily: AppConfig.fontMono,
                    ),
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}
