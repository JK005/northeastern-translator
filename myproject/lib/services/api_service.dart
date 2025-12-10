import 'package:http/http.dart' as http;
import 'dart:convert';

/// Model สำหรับแต่ละ Token (คำ + options)
class Token {
  final String word;
  final List<String> options;
  String selected; // ค่า default ที่เลือก (option แรก)

  Token({
    required this.word,
    required this.options,
    required this.selected,
  });

  factory Token.fromJson(Map<String, dynamic> json) {
    List<String> opts = List<String>.from(json['options']);
    return Token(
      word: json['word'],
      options: opts,
      selected: opts.isNotEmpty ? opts.first : json['word'],
    );
  }
}

/// Model สำหรับผลลัพธ์การแปล
class TranslationResult {
  final String input;
  final List<Token> tokens;

  TranslationResult({
    required this.input,
    required this.tokens,
  });

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    final input = json["translated_text"]["input"];
    final output = json["translated_text"]["output"];

    List<Token> tokens = [];
    if (output["tokens"] != null) {
      tokens = (output["tokens"] as List)
          .map((t) => Token.fromJson(t))
          .toList();
    }

    return TranslationResult(
      input: input,
      tokens: tokens,
    );
  }

  /// รวมผลลัพธ์ที่เลือกทั้งหมดกลับเป็นประโยคเดียว
  String get combinedTranslation {
    return tokens.map((t) => t.selected).join("");
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
        return TranslationResult.fromJson(data);
      } else {
        throw Exception("ไม่สามารถแปลได้: ${response.statusCode}");
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการเชื่อมต่อ API: $e");
      return TranslationResult(input: inputText, tokens: []);
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
        return TranslationResult.fromJson(data);
      } else {
        throw Exception("ไม่สามารถแปลได้: ${response.statusCode}");
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการเชื่อมต่อ API: $e");
      return TranslationResult(input: inputText, tokens: []);
    }
  }
}