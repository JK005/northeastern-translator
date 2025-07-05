from pythainlp.tokenize import word_tokenize
from pythainlp.util import normalize
import mysql.connector

# เชื่อมต่อฐานข้อมูล MySQL
db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="0168", 
    database="local_translator"
)
cursor = db.cursor()

# ฟังก์ชันตัดคำภาษาไทย/อีสาน
def tokenize_text(text: str):
    return word_tokenize(text, engine="newmm")

# ฟังก์ชันทำให้ข้อความอยู่ในรูปแบบมาตรฐาน
def normalize_text(text: str):
    return normalize(text)

# ฟังก์ชันแปลอีสาน -> ไทย
def translate_isan_to_thai(isan_text: str):
    words = word_tokenize(isan_text, engine="newmm")
    translated_words = {}

    for word in words:
        cursor.execute("SELECT thai_translation FROM isan_thai WHERE isan_word = %s", (word,))
        results = cursor.fetchall()
        translated_words[word] = [row[0] for row in results] if results else [word]

    return translated_words

# ฟังก์ชันแปลไทย -> อีสาน
def translate_thai_to_isan(thai_text: str):
    words = word_tokenize(thai_text, engine="newmm")
    translated_words = {}

    for word in words:
        cursor.execute("SELECT isan_translation FROM thai_isan WHERE thai_word = %s", (word,))
        results = cursor.fetchall()
        translated_words[word] = [row[0] for row in results] if results else [word]

    return {"translated_text": translated_words}

