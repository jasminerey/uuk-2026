import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:inventaris_lab/utils/app_color.dart';
import 'firebase_options.dart';
import 'package:inventaris_lab/screens/splash_screen.dart';
import 'package:inventaris_lab/screens/home_screen.dart';
import 'package:inventaris_lab/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventaris Lab',
      home: const SplashScreen(), // Halaman pertama yang muncul
    );
  }
}