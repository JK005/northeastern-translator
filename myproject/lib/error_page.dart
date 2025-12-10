import 'package:flutter/material.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เกิดข้อผิดพลาด")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text("มีบางอย่างผิดพลาด กรุณาลองใหม่"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/loading');
              },
              child: const Text("กลับไปหน้าโหลด"),
            ),
          ],
        ),
      ),
    );
  }
}