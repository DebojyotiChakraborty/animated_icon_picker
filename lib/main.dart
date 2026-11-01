import 'package:flutter/material.dart';

import 'ui/home_screen.dart';

void main() {
  runApp(const AnimatedIconPickerApp());
}

class AnimatedIconPickerApp extends StatelessWidget {
  const AnimatedIconPickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Icon Picker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A84FF)),
        splashFactory: NoSplash.splashFactory,
      ),
      home: const HomeScreen(),
    );
  }
}
