import 'package:flutter/material.dart';

class AppColor {
  // Tambahkan 'FF' setelah '0x' pada baris 4, 5, dan 6
  static const Color primary = Color(0xFF0A2947);
  static const Color primaryLight = Color.fromARGB(255, 94, 124, 192);
  static const Color secondary = Color(0xFFF3E4C9);
  
  static const Color textPrimary = Color(0xFF111111);
  static const Color White = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF25A750);
  static const Color error = Color.fromARGB(255, 255, 0, 0);

  static const LinearGradient primarygradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomRight,
  );
  
}