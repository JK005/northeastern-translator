import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NortheasternTranslator extends StatefulWidget {
  const NortheasternTranslator({super.key});

  @override
  _NortheasternTranslatorState createState() => _NortheasternTranslatorState();
}

class _NortheasternTranslatorState extends State<NortheasternTranslator> {
  final FlutterTts tts = FlutterTts();
  final TextEditingController thaiToIsanController = TextEditingController();
  final TextEditingController isanToThaiController = TextEditingController();
  String translatedText = "";

  void translate() async {
  String inputText = thaiToIsanController.text.isNotEmpty
      ? thaiToIsanController.text
      : isanToThaiController.text;

  String endpoint = thaiToIsanController.text.isNotEmpty
      ? "translate/thai-to-isan"
      : "translate/isan-to-thai";

  try {
    final response = await http.post(
      Uri.parse("http://127.0.0.1:8000/$endpoint?sentence=$inputText"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      setState(() {
        translatedText = result["translated_text"].toString();
      });
    } else {
      setState(() {
        translatedText = "เกิดข้อผิดพลาดในการแปล";
      });
    }
  } catch (e) {
    setState(() {
      translatedText = "ไม่สามารถเชื่อมต่อ API ได้: $e";
    });
  }
}

  Future<void> _speak(String text, String language) async {
    await tts.setLanguage(language);
    await tts.speak(text);
  }

  void _translate() async {
    // ตัวอย่าง mock ข้อมูล
    setState(() {
      translatedText = "ผลลัพธ์การแปลจะแสดงตรงนี้";
    });

    // เชื่อม API ได้ที่นี่ด้วย http.post
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Northeastern\nTranslator',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/Flag_of_Thailand.svg/320px-Flag_of_Thailand.svg.png', height: 40),
            const SizedBox(height: 30),

            _buildInputField("พิมพ์หรือพูด (ไทย → อีสาน)", thaiToIsanController),
            const SizedBox(height: 10),
            _buildInputField("พิมพ์หรือพูด (อีสาน → ไทย)", isanToThaiController),


            const SizedBox(height: 20),
            const Divider(thickness: 1.5),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text("คำศัพท์แปล", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(translatedText, style: const TextStyle(fontSize: 16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.content_copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: translatedText));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up),
                        onPressed: () => _speak(translatedText, "th-TH"),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _translate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 187, 164, 233),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text("TRANSLATE", style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 20),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: () => _speak(translatedText, "lo-LA"), // เสียงอีสานถ้ามีรองรับ
                    ),
                    const Text("ฟังเสียง (อีสาน)", style: TextStyle(fontSize: 12))
                  ],
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: () => _speak(translatedText, "th-TH"),
                    ),
                    const Text("ฟังเสียง (ไทย)", style: TextStyle(fontSize: 12))
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: controller == thaiToIsanController ? "Thai ⇌ Isan" : "Isan ⇌ Thai",
            suffixIcon: const Icon(Icons.mic, color: Colors.deepPurple),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}