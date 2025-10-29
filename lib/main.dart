import 'package:flutter/material.dart';
import 'screens/azimuth.dart';

void main() {
  runApp(const SolarPanelApp());
}

class SolarPanelApp extends StatelessWidget {
  const SolarPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Azimuth',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const SolarAngleScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
