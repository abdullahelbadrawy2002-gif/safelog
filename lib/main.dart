import 'package:flutter/material.dart';

import 'data/incident_db.dart';
import 'screens/incident_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SafeLogApp(db: IncidentDb()));
}

class SafeLogApp extends StatelessWidget {
  const SafeLogApp({super.key, required this.db});

  final IncidentDb db;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1F4E79);
    return MaterialApp(
      title: 'SafeLog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: seed,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: IncidentListScreen(db: db),
    );
  }
}
