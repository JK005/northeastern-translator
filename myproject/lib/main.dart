import 'package:flutter/material.dart';
import 'package:myproject/screens/main_screen.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NortheasternTranslator(), // เรียก UI หลักที่เราสร้าง
    ),
  );
}
