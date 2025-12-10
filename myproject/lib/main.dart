import 'package:flutter/material.dart';
import 'loading_page.dart';
import 'no_internet_page.dart';
import 'error_page.dart';
import 'screens/main_screen.dart'; // หน้า UI หลัก

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Thai-Isan Translator',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        fontFamily: 'Prompt',
      ),
      // เริ่มต้นที่หน้า Loading ก่อน
      initialRoute: '/loading',
      routes: {
        '/loading': (context) => const LoadingPage(),
        '/main': (context) => const MainScreen(),
        '/noInternet': (context) => const NoInternetPage(),
        '/error': (context) => const ErrorPage(),
      },
    );
  }
}