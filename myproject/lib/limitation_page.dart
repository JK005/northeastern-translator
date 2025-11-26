import 'package:flutter/material.dart';

class LimitationPage extends StatelessWidget {
  const LimitationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ข้อจำกัดของแอปพลิเคชัน")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            Text(
              "ข้อจำกัดของแอปพลิเคชัน",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              "แอปนี้ออกแบบมาเพื่อแปลคำศัพท์และประโยคระหว่างภาษาอีสาน(สำเนียงขอนแก่น)กับภาษาไทยกลาง"
              "เพื่อการเรียนรู้และสื่อสารในชีวิตประจำวันเท่านั้น\n\n"
              "ไม่เหมาะสำหรับการใช้งานในบริบทที่ต้องการความแม่นยำสูง เช่น:\n"
              "- การแปลเอกสารทางกฎหมาย\n"
              "- การใช้งานทางการแพทย์\n"
              "- การแปลเอกสารราชการหรือเชิงพาณิชย์\n"
              "- การแปลอาจมีข้อผิดพลาดขึ้นอยู่กับคุณภาพของเสียงพูด หากพิมพ์ผิดหรือใช้ภาษาไทยไม่ถูก อาจทำให้การแปลคลาดเคลื่อนหรือไม่สมบูรณ์\n\n"
              "ผู้ใช้ควรใช้แอปนี้เพื่อการเรียนรู้และสื่อสารทั่วไปเท่านั้น",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
