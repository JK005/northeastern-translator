import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  //  กำหนด baseUrl ให้เหมาะกับ environment
  // Android Emulator → http://10.0.2.2:8000
  // มือถือจริง      → http://192.168.1.113:8000  IP Address:8000 สามารถเปลี่ยนได้ตาม wifi ที่เชื่อม
  static const String baseUrl = "http://192.168.1.113:8000";

  // ฟังก์ชันแปลจากอีสาน → ไทย
  static Future<String> translateIsanToThai(String inputText) async {
    try {
      final url = Uri.parse('$baseUrl/translate/isan-to-thai');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"sentence": inputText}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> thaiList = data["translated_text"]["output"]["thai"];
        return thaiList.join(""); // รวมผลแปล
      } else {
        throw Exception("ไม่สามารถแปลได้: ${response.statusCode}");
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการเชื่อมต่อ API: $e");
      return "แปลไม่สำเร็จ";
    }
  }

  // ฟังก์ชันแปลจากไทย → อีสาน
  static Future<String> translateThaiToIsan(String inputText) async {
    try {
      final url = Uri.parse('$baseUrl/translate/thai-to-isan');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"sentence": inputText}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> isanList = data["translated_text"]["output"]["isan"];
        return isanList.join(""); // รวมผลแปล
      } else {
        throw Exception("ไม่สามารถแปลได้: ${response.statusCode}");
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการเชื่อมต่อ API: $e");
      return "แปลไม่สำเร็จ";
    }
  }
}