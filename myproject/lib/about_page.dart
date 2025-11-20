import 'package:flutter/material.dart';
import 'dart:ui';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เกี่ยวกับแอปพลิเคชัน")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text("ชื่อแอปพลิเคชัน: แปลภาษาอีสานเป็นภาษาไทยกลาง"),
                    subtitle: Text("เวอร์ชัน: 1.0.0"),
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.person),
                    title: Text("นักศึกษาผู้พัฒนาแอปพลิเคชัน"),
                    subtitle: Text("นายจักรกฤษณ์ ทองขาว\nนายกษพัฒน์ กองอาสา"),
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.school_outlined),
                    title: Text("สถานศึกษา"),
                    subtitle: Text("มหาวิทยาลัยเทคโนโลยีพระจอมเกล้าพระนครเหนือ วิทยาเขตปราจีนบุรี"),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text("ติดต่อผู้พัฒนา"),
                    subtitle: const Text("gyurluy@gmail.com"),
                    onTap: () {
                      // เปิดอีเมล
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}