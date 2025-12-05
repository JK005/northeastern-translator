import 'package:http/http.dart' as http;
import 'dart:convert';

class TranslationResult {
  final String input;
  final String translation;       // คำแปลหลัก (ถ้ามีแค่หนึ่ง)
  final List<String> options;     // ตัวเลือกหลายความหมาย

  TranslationResult({
    required this.input,
    required this.translation,
    required this.options,
  });

  factory TranslationResult.fromJson(Map<String, dynamic> json, {bool isanToThai = true}) {
    final output = json["translated_text"]["output"];
    final input = json["translated_text"]["input"];

    List<String> options = [];
    String translation = "";

    if (isanToThai) {
      if (output["thai_options"] != null) {
        options = List<String>.from(output["thai_options"]);
        translation = options.first;
      } else {
        options = List<String>.from(output["thai"]);
        translation = options.first;
      }
    } else {
      if (output["isan_options"] != null) {
        options = List<String>.from(output["isan_options"]);
        translation = options.first;
      } else {
        options = List<String>.from(output["isan"]);
        translation = options.first;
      }
    }

    return TranslationResult(
      input: input,
      translation: translation,
      options: options,
    );
  }
}

class ApiService {
  // Android Emulator → http://10.0.2.2:8000
  // มือถือจริง      → http://192.168.1.113:8000
  static const String baseUrl = "http://178.128.179.115:8000";

  // ฟังก์ชันแปลจากอีสาน → ไทย
  static Future<TranslationResult> translateIsanToThai(String inputText) async {
    try {
      final url = Uri.parse('$baseUrl/translate/isan-to-thai');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"sentence": inputText}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return TranslationResult.fromJson(data, isanToThai: true);
      } else {
        throw Exception("ไม่สามารถแปลได้: ${response.statusCode}");
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการเชื่อมต่อ API: $e");
      return TranslationResult(input: inputText, translation: "แปลไม่สำเร็จ", options: []);
    }
  }

  // ฟังก์ชันแปลจากไทย → อีสาน
  static Future<TranslationResult> translateThaiToIsan(String inputText) async {
    try {
      final url = Uri.parse('$baseUrl/translate/thai-to-isan');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"sentence": inputText}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return TranslationResult.fromJson(data, isanToThai: false);
      } else {
        throw Exception("ไม่สามารถแปลได้: ${response.statusCode}");
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการเชื่อมต่อ API: $e");
      return TranslationResult(input: inputText, translation: "แปลไม่สำเร็จ", options: []);
    }
  }
}