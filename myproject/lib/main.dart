import 'package:flutter/material.dart';
import 'package:myproject/screens/main_screen.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
            home: MyApp(), // เรียก UI หลักที่เราสร้าง

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        fontFamily: 'Prompt', // ใช้ฟอนต์ไทยสวย ๆ
      ),
    ),
  );
}