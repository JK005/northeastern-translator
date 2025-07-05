import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static Future<void> addWord(String isanWord, String thaiTranslation) async {
    // เรียกใช้ API ผ่าน Flutter
    await http.post(
      Uri.parse('http://127.0.0.1:8000/add-word'), 
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"isan_word": isanWord, "thai_translation": thaiTranslation}),
    );
  }

  static translateIsanToThai(String inputText) {}
}
