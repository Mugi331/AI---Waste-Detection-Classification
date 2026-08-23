import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const WasteDetectionApp());
}

class WasteDetectionApp extends StatelessWidget {
  const WasteDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoSort AI',
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}

