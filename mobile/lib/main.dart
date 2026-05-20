import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const AgroTechApp());
}

class AgroTechApp extends StatelessWidget {
  const AgroTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroTech SMAT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
