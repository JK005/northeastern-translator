import 'package:flutter/material.dart';

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ไม่มีการเชื่อมต่ออินเทอร์เน็ต")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            const Text("กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/loading');
              },
              child: const Text("ลองใหม่"),
            ),
          ],
        ),
      ),
    );
  }
}