from pythainlp.tokenize import word_tokenize
from pythainlp.util import normalize
import mysql.connector
from fuzzywuzzy import fuzz

db = mysql.connector.connect(
    host="178.128.179.115",
    user="appdb",
    password="strongpassword092",
    database="local_translator"
)
cursor = db.cursor(dictionary=True)

# ฟังก์ชันตัดคำภาษาไทย/อีสาน
def tokenize_text(text: str):
    return word_tokenize(text, engine="newmm")

# ฟังก์ชันทำให้ข้อความอยู่ในรูปแบบมาตรฐาน
def normalize_text(text: str):
    return normalize(text)

# ฟังก์ชัน exact search สำหรับคำพิเศษ
def exact_search_isan_to_thai(word: str):
    cursor.execute("SELECT thai_translation FROM isan_thai WHERE isan_word = %s", (word,))
    results = cursor.fetchall()
    return [row["thai_translation"] for row in results] if results else [word]

def exact_search_thai_to_isan(word: str):
    cursor.execute("SELECT isan_translation FROM thai_isan WHERE thai_word = %s", (word,))
    results = cursor.fetchall()
    return [row["isan_translation"] for row in results] if results else [word]

# ฟังก์ชันแปลอีสาน -> ไทย พร้อม Fuzzy Matching
def translate_isan_to_thai(isan_text: str):
    words = word_tokenize(isan_text, engine="newmm")
    translated_words = {}

    for word in words:
        if word == "สี":
            translated_words[word] = exact_search_isan_to_thai(word)
            continue

        # ค้นหาคำแปลจากฐานข้อมูล
        cursor.execute("SELECT thai_translation FROM isan_thai WHERE isan_word = %s", (word,))
        results = cursor.fetchall()

        # ถ้าไม่พบคำที่ตรงกัน ใช้ Fuzzy Matching
        if not results:
            cursor.execute("SELECT isan_word FROM isan_thai")
            all_words = [row["isan_word"] for row in cursor.fetchall()]
            if all_words:
                closest_match = max(all_words, key=lambda x: fuzz.ratio(word, x))
                cursor.execute("SELECT thai_translation FROM isan_thai WHERE isan_word = %s", (closest_match,))
                results = cursor.fetchall()

        translated_words[word] = [row["thai_translation"] for row in results] if results else [word]

    return translated_words

# ฟังก์ชันแปลไทย -> อีสาน พร้อม Fuzzy Matching
def translate_thai_to_isan(thai_text: str):
    words = word_tokenize(thai_text, engine="newmm")
    translated_words = {}

    for word in words:
        if word == "สี":
            translated_words[word] = exact_search_thai_to_isan(word)
            continue

        # ค้นหาคำแปลจากฐานข้อมูล
        cursor.execute("SELECT isan_translation FROM thai_isan WHERE thai_word = %s", (word,))
        results = cursor.fetchall()

        # ถ้าไม่พบคำที่ตรงกัน ใช้ Fuzzy Matching
        if not results:
            cursor.execute("SELECT thai_word FROM thai_isan")
            all_words = [row["thai_word"] for row in cursor.fetchall()]
            if all_words:
                closest_match = max(all_words, key=lambda x: fuzz.ratio(word, x))
                cursor.execute("SELECT isan_translation FROM thai_isan WHERE thai_word = %s", (closest_match,))
                results = cursor.fetchall()

        translated_words[word] = [row["isan_translation"] for row in results] if results else [word]

    return {"translated_text": translated_words}