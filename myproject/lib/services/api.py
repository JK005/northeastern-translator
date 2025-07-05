from fastapi import FastAPI
import mysql.connector
from pydantic import BaseModel
from pythainlp.tokenize import word_tokenize
from services.nlp_service import tokenize_text, normalize_text, translate_isan_to_thai, translate_thai_to_isan

app = FastAPI()

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="0168",
    database="local_translator"
)
cursor = db.cursor(buffered=True)

# โมเดลสำหรับรับคำศัพท์ใหม่
class AddWordRequest(BaseModel):
    isan_word: str
    thai_translation: str

# โมเดลสำหรับรับข้อความจาก Flutter
class SentenceRequest(BaseModel):
    sentence: str

@app.post("/add-word")
def add_word(request: AddWordRequest):
    cursor.execute("INSERT INTO isan_thai (isan_word, thai_translation) VALUES (%s, %s)",
                   (request.isan_word, request.thai_translation))
    db.commit()
    return {"message": "เพิ่มคำศัพท์สำเร็จ!"}

@app.post("/tokenize")
def tokenize(request: SentenceRequest):
    return {"tokens": tokenize_text(request.sentence)}

@app.post("/normalize")
def normalize(request: SentenceRequest):
    return {"normalized_text": normalize_text(request.sentence)}

@app.post("/translate/isan-to-thai")
def translate_isan(request: SentenceRequest):
    sentence = request.sentence.strip()

    # ลองค้นหาทั้งประโยคก่อน
    cursor.execute("SELECT thai_translation FROM isan_thai WHERE isan_word = %s", (sentence,))
    result = cursor.fetchone()

    if result:
        return {
            "translated_text": {
                "input": sentence,
                "output": {
                    "isan": [sentence],
                    "thai": [result[0]]
                }
            }
        }

    # ใช้ greedy matching หลังจาก tokenize
    words = word_tokenize(sentence, engine="newmm")
    n = len(words)
    translated_pairs = []
    i = 0

    while i < n:
        found = False
        for size in range(4, 0, -1):  # ลองรวม 4 คำลงมา
            if i + size <= n:
                combined_word = ''.join(words[i:i+size])
                cursor.execute("SELECT thai_translation FROM isan_thai WHERE isan_word = %s", (combined_word,))
                row = cursor.fetchone()
                if row:
                    translated_pairs.append((combined_word, row[0]))
                    i += size
                    found = True
                    break
        if not found:
            translated_pairs.append((words[i], words[i]))  # คืนค่าเดิมถ้าไม่เจอ
            i += 1

    isan_tokens = [p[0] for p in translated_pairs]
    thai_tokens = [p[1] for p in translated_pairs]
    thai_combined = ''.join(thai_tokens)

    return {
        "translated_text": {
            "input": sentence,
            "output": {
                "isan": isan_tokens,
                "thai": [thai_combined]
            }
        }
    }

@app.post("/translate/thai-to-isan")
def translate_thai(request: SentenceRequest):
    sentence = request.sentence.strip()

    cursor.execute("SELECT isan_translation FROM thai_isan WHERE thai_word = %s", (sentence,))
    result = cursor.fetchone()

    if result:
        return {"translated_text": {"input": sentence, "output": {"thai": [sentence], "isan": [result[0]]}}}

    words = word_tokenize(sentence, engine="newmm")
    n = len(words)
    translated_pairs = []
    i = 0

    while i < n:
        found = False
        for size in range(4, 0, -1):
            if i + size <= n:
                combined_word = ''.join(words[i:i+size])
                cursor.execute("SELECT isan_translation FROM thai_isan WHERE thai_word = %s", (combined_word,))
                row = cursor.fetchone()
                if row:
                    translated_pairs.append((combined_word, row[0]))
                    i += size
                    found = True
                    break
        if not found:
            translated_pairs.append((words[i], words[i]))
            i += 1

    thai_tokens = [p[0] for p in translated_pairs]
    isan_tokens = [p[1] for p in translated_pairs]
    isan_combined = ''.join(isan_tokens)

    return {
        "translated_text": {
            "input": sentence, 
            "output": {
                "thai": thai_tokens, 
                "isan": [isan_combined]
            }
        }
    }

@app.get("/test-db")
def test_db():
    cursor.execute("SELECT isan_word, thai_translation FROM isan_thai LIMIT 30")
    rows = cursor.fetchall()
    data = [{"isan_word": r[0], "thai_translation": r[1]} for r in rows]
    return {"data": data}
