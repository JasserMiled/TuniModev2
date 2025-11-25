import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const TuniModeApp());
}

class TuniModeApp extends StatelessWidget {
  const TuniModeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TuniMode',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routes: {
        '/': (_) => const HomeScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },
      initialRoute: '/',
    );
  }
}
