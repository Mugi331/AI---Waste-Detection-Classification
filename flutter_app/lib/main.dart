import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/opening_screen.dart';

void main() {
  runApp(const WasteDetectionApp());
}

class WasteDetectionApp extends StatelessWidget {
  const WasteDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WE Snap',
      theme: AppTheme.light(),
      home: const OpeningScreen(),
    );
  }
}

