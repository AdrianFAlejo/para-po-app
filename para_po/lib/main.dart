import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:para_po/screens/home_page.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Para Po',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue, // Using blue as primary swatch
          accentColor: Colors.white, // White as accent color
          backgroundColor: Colors.grey, // Grey as background color
          cardColor: Colors.white, // White as card color
          errorColor: Colors.red, // Red as error color
          brightness: Brightness.light, // Light theme
          ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
