import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inventaris_lab/screens/home_screen.dart';
import 'package:inventaris_lab/screens/login_screen.dart';
import 'package:inventaris_lab/utils/app_color.dart';
import 'package:inventaris_lab/utils/app_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState(){
    super.initState();
    _CheckAuthStatus();
  }

  void _CheckAuthStatus() {
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.White, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shelves, 
              color: AppColor.primary,
              size: 100,
            ),
            const SizedBox(height: 20),
            // 3. Matikan AppFonts sementara, gunakan TextStyle biasa
            Text(
              'Labs Inventory', style: AppFonts.header(),
            ),
            const SizedBox(height: 10),
            Text(
              'Kelola inventaris laboratorium dengan satu klik', 
              style: AppFonts.subHeader(
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(
              color: AppColor.primary,
            ),
          ],
        ),
      ),
    );
  }
  
}