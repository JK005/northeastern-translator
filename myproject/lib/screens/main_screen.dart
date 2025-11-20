import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:myproject/about_page.dart';
import 'package:myproject/limitation_page.dart';
import 'package:myproject/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import '../favorite_page.dart'; //หน้า Favorite คำที่ชื่นชอบ
import 'dart:ui'; // สำหรับ BackdropFilter

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'แปลภาษาอีสาน-ไทย',
          theme: ThemeData(
            primarySwatch: Colors.green,
            scaffoldBackgroundColor: const Color(0xFFF0F0F0),
          ),
          home: child ?? const SizedBox(), // ป้องกัน null
        );
      },
      child: const TranslatorScreen(),
    );
  }
}

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final TextEditingController inputController = TextEditingController();
  final TextEditingController outputController = TextEditingController();
  final FlutterTts tts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();

  bool isThaiToIsan = true;
  double ttsSpeed = 0.5;
  bool isListening = false;
  String recognizedText = "";
  String listen = 'กำลังรอฟัง...';
  List<Map<String, String>> favoriteWords = [];
  bool isFavorite = false;
  // ignore: unused_field
  String _sttBuffer = '';
  // ignore: unused_field
  final String _lastFinal = '';

  @override
  void initState() {
    super.initState();
    _requestPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSpeech();
    });
    _loadFavorites();
  }

  void _requestPermission() async {
    await Permission.microphone.request();
  }

  void _initSpeech() async {
    bool available = await speech.initialize(
      onStatus: (status) {
        debugPrint('onStatus: $status');
        if (status == "done" || status == "notListening") {
          if (mounted) {
            setState(() {
              isListening = false;
              _sttBuffer = '';
            });
          }
        }
      },
      onError: (error) => debugPrint('onError: $error'),
    );
    debugPrint("Speech available: $available");

    if (available) {
      // ตรวจสอบ locale ที่รองรับ
      var systemLocales = await speech.locales();
      debugPrint("Locales available: $systemLocales");

      // เลือก locale ไทยถ้ามี ไม่งั้น fallback เป็น default
      final thLocale = systemLocales.firstWhere(
        (l) => l.localeId.startsWith("th"),
        orElse: () => systemLocales.first,
      );

      // ถ้าไม่ใช่ th_TH ให้แจ้งผู้ใช้
      if (!thLocale.localeId.startsWith("th")) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "อุปกรณ์นี้ไม่รองรับการฟังเสียงภาษาไทย กำลังใช้ค่าเริ่มต้นแทน",
              ),
            ),
          );
        }
      }

      setState(() {
        isListening = true;
      });

      speech.listen(
        onResult: (result) {
          setState(() {
            listen = result.recognizedWords;
          });
        },
        localeId: thLocale.localeId, // ใช้ locale ที่รองรับจริง
      );
    } else {
      debugPrint("Speech recognition not available");
    }
  }

  void _startListening() async {
  if (!speech.isAvailable) {
    debugPrint("Speech service not available");
    return;
  }

  await speech.stop(); // กัน session ซ้อน
  _sttBuffer = '';     // รีเซ็ต buffer

  bool available = await speech.initialize(
    onStatus: (status) {
      debugPrint("สถานะ: $status");

      // ถ้าไมค์หยุดเอง แต่เรายังต้องการฟัง → restart
      if ((status == "done" || status == "notListening") && isListening) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (isListening) _startListening();
        });
      }
    },
    onError: (error) {
      debugPrint("ข้อผิดพลาด: $error");
      //ถ้า error แล้วเรายังต้องการฟัง → restart
      if (isListening) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (isListening) _startListening();
        });
      }
    },
  );

  if (available) {
    // ตรวจสอบ locale ภาษาไทย
    var systemLocales = await speech.locales();
    final thLocale = systemLocales.firstWhere(
      (l) => l.localeId.startsWith("th"),
      orElse: () => systemLocales.first,
    );

    if (!thLocale.localeId.startsWith("th") && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("อุปกรณ์นี้ไม่รองรับเสียงภาษาไทย กำลังใช้ค่าเริ่มต้นแทน"),
        ),
      );
    }

    setState(() => isListening = true);

    speech.listen(
      onResult: (result) {
        setState(() {
          recognizedText = result.recognizedWords;

          if (result.finalResult) {
            inputController.text += recognizedText;
            inputController.selection = TextSelection.fromPosition(
              TextPosition(offset: inputController.text.length),
            );
            _sttBuffer = '';
          } else {
            _sttBuffer = result.recognizedWords;
          }
        });
      },
      localeId: thLocale.localeId,
      pauseFor: const Duration(seconds: 60),
      listenFor: const Duration(minutes: 10),  // จะไม่หยุด เพราะครบเวลา
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
      ),
    );
  } else {
    debugPrint("Speech recognition initialize failed");
  }
}

  void _stopListening() async {
    await speech.stop();
    setState(() => isListening = false);
  }

  Future<bool> _isFavorite(String isan, String thai) async {
    final prefs = await SharedPreferences.getInstance();
    final favStrings = prefs.getStringList('favorites') ?? [];
    return favStrings.contains('$isan|$thai');
  }

  void _checkFavoriteStatus() async {
    final isan = inputController.text.trim();
    final thai = outputController.text.trim();

    if (isan.isEmpty || thai.isEmpty) {
      setState(() => isFavorite = false); //ถ้าลบข้อความ → รีเซ็ตดาว
      return;
    }

    final exists = await _isFavorite(isan, thai);
    setState(() => isFavorite = exists); //ถ้าเคยบันทึก → ดาวเป็นสีเหลือง
  }

  Future<void> _speak(String text) async {
    await tts.setLanguage("th-TH");
    await tts.setSpeechRate(ttsSpeed);
    await tts.speak(text);
  }

  // โหลดคำโปรด
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];

    if (!mounted) return;
    setState(() {
      favoriteWords =
          favorites.map((entry) {
            final parts = entry.split('|');
            return {'isan': parts[0], 'thai': parts[1]};
          }).toList();
    });
  }

  Future<void> _translateText() async {
  try {
    // เรียกผ่าน ApiService ตามทิศทางการแปล
    final translated = isThaiToIsan
        ? await ApiService.translateThaiToIsan(inputController.text)
        : await ApiService.translateIsanToThai(inputController.text);

    // โหลด favorites จาก SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favorites') ?? [];

    if (!mounted) return;
    setState(() {
      outputController.text = translated;
      isFavorite = favs.contains('${inputController.text}|$translated');
    });
  } on TimeoutException {
    if (!mounted) return;
    setState(() {
      outputController.text = "หมดเวลาเชื่อมต่อ (timeout)";
      isFavorite = false;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      outputController.text = "เกิดข้อผิดพลาด: $e";
      isFavorite = false;
    });
  }
}

  Future<void> _toggleFavorite(String input, String output) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];
    final entry = '$input|$output';

    if (favorites.contains(entry)) {
      favorites.remove(entry);
      await prefs.setStringList('favorites', favorites);
      await _loadFavorites();
      if (!mounted) return;
      setState(() => isFavorite = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ลบออกจากคำโปรดแล้ว")));
    } else {
      favorites.add(entry);
      await prefs.setStringList('favorites', favorites);
      await _loadFavorites();
      if (!mounted) return;
      setState(() => isFavorite = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("บันทึกคำโปรดแล้ว")));
    }
  }

  // Drawer แสดงคำโปรด
  Widget _buildDrawer() {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: Colors.green),
          child: Text(
            "เมนูหลัก",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),

        // หมวด: การตั้งค่า
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text("การตั้งค่า", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          title: const Text("ปรับความเร็วเสียง"),
          subtitle: Slider(
            value: ttsSpeed,
            min: 0.2,
            max: 1.0,
            divisions: 8,
            label: ttsSpeed.toStringAsFixed(2),
            onChanged: (value) {
              setState(() {
                ttsSpeed = value;
              });
            },
          ),
        ),

        const Divider(),

        // หมวด: คำโปรด
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text("คำโปรด", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: const Text("รายการคำโปรด"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FavoritePage()),
              );
            },
          ),
        ),

        const Divider(),

        // หมวด: เกี่ยวกับแอป
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text("เกี่ยวกับแอป", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text("เกี่ยวกับแอป"),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutPage()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.warning_amber_outlined),
          title: const Text("ข้อจำกัดของแอปพลิเคชัน"),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LimitationPage()),
            );
          },
        ),
      ],
    ),
  );
}

  Widget _buildLanguageSwitcher(double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => setState(() => isThaiToIsan = true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isThaiToIsan ? Colors.green : Colors.grey[400],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("ภาษาไทยกลาง", style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.compare_arrows, size: 24),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => setState(() => isThaiToIsan = false),
          style: ElevatedButton.styleFrom(
            backgroundColor: !isThaiToIsan ? Colors.green : Colors.grey[400],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("ภาษาอีสาน", style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildTextBox({
  required String label,
  required TextEditingController controller,
  required bool readOnly,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 16.sp)),
      SizedBox(height: 6.h),
      ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 180.h,
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.black, width: 1.5), // กรอบสีดำ
            ),
            child: Stack(
              children: [
                TextField(
                  controller: controller,
                  readOnly: readOnly,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(16, 20, 48, 60),
                  ),
                  style: TextStyle(
                    fontSize: readOnly ? 16.sp : 18.sp,
                    color: Colors.black,
                  ),
                ),
                Positioned(
                  bottom: 8.h,
                  left: 8.w,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: Colors.black), // ลำโพง
                        onPressed: () => _speak(controller.text),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.star,
                          color: isFavorite ? Colors.amber : Colors.black,
                        ),
                        tooltip: isFavorite
                            ? 'กดอีกครั้งเพื่อลบคำออกจากคำโปรด'
                            : 'บันทึกคำโปรด',
                        onPressed: () async {
                          if (inputController.text.isNotEmpty &&
                              outputController.text.isNotEmpty) {
                            await _toggleFavorite(
                              inputController.text,
                              outputController.text,
                            );
                            _checkFavoriteStatus(); // อัปเดตสถานะดาวหลังบันทึก
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.black), // คัดลอก
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: controller.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("คัดลอกข้อความแล้ว")),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    //final screenHeight = MediaQuery.of(context).size.height;
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("แปลภาษาไทย-อีสาน"),
            leading: Builder(
              builder:
                  (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
            ),
          ),
          drawer: _buildDrawer(),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildLanguageSwitcher(screenWidth),
                  SizedBox(height: 16.h),
                  if (orientation == Orientation.portrait) ...[
                    _buildTextBox(
                      label: "ป้อนข้อความ",
                      controller: inputController,
                      readOnly: false,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextBox(
                      label: "คำแปล",
                      controller: outputController,
                      readOnly: true,
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextBox(
                            label: "ป้อนข้อความ",
                            controller: inputController,
                            readOnly: false,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _buildTextBox(
                            label: "คำแปล",
                            controller: outputController,
                            readOnly: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _translateText,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue[200],
                          padding: EdgeInsets.symmetric(
                            vertical: 16.h,
                            horizontal: 24.w,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                        ),
                        child: Text(
                          "กดเพื่อแปล",
                          style: TextStyle(fontSize: 15.sp),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: ElevatedButton(
                          key: ValueKey(isListening), // สำคัญสำหรับ AnimatedSwitcher
                          onPressed: isListening ? _stopListening : _startListening,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isListening ? Colors.red[400] : Colors.green[400],
                            shape: const CircleBorder(),
                            padding: EdgeInsets.all(19.r), //ขนาดปุ่มไมล์
                            elevation: 6,
                          ),
                          child: Icon(
                            isListening ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 32.r,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}