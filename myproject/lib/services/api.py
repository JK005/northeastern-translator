from fastapi import FastAPI
import mysql.connector
from pydantic import BaseModel
import unicodedata
from fastapi.middleware.cors import CORSMiddleware
import re
from fuzzywuzzy import fuzz
from pythainlp.tokenize import word_tokenize
from services.nlp_service import tokenize_text, normalize_text, translate_isan_to_thai, translate_thai_to_isan
from mysql.connector.pooling import MySQLConnectionPool

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],      # ควรระบุเฉพาะ production
    allow_methods=["*"],
    allow_headers=["*"],
)

pool = MySQLConnectionPool(
    pool_name="mypool",
    pool_size=10,
    host="178.128.179.115",
    user="appdb",
    password="strongpassword092",
    database="local_translator",
    autocommit=True
)

def get_connection():
    return pool.get_connection()

# ===== ปรับคำว่า "บ่" =====
def adjust_bor(isan_tokens, thai_tokens):
    n = len(isan_tokens)
    for i, tok in enumerate(isan_tokens):
        if tok == "บ่":
            # ถ้ามีคำเดียวทั้งประโยค -> ไม่
            if n == 1:
                thai_tokens[i] = "ไม่"
            # ถ้า "บ่" อยู่ท้ายประโยค -> แปลว่า "ไหม"
            elif i == n - 1:
                thai_tokens[i] = "ไหม"
            # อื่นๆ -> แปลว่า "ไม่"
            else:
                thai_tokens[i] = "ไม่"
    return thai_tokens

def thai_clusters(text: str):
    """
    รวมอักษรฐาน + สระ/วรรณยุกต์ (combining marks) ให้เป็น 'คลัสเตอร์' เดียว
    เพื่อป้องกันการแตกพยางค์ผิด เช่น 'อยู่' ไม่ถูกแยกเป็น 'อยู' + '่'
    """
    clusters = []
    current = ""
    for ch in text:
        # เว้นวรรคเป็นคลัสเตอร์แยก
        if ch.isspace():
            if current:
                clusters.append(current)
                current = ""
            clusters.append(ch)
            continue
        # ถ้าเป็น combining mark ให้ติดกับฐานเดิม
        if not current:
            current = ch
        else:
            if unicodedata.combining(ch) != 0:
                current += ch
            else:
                clusters.append(current)
                current = ch
    if current:
        clusters.append(current)
    return clusters

class AddWordRequest(BaseModel):
    isan_word: str
    thai_translation: str

class SentenceRequest(BaseModel):
    sentence: str

@app.post("/tokenize")
def tokenize(request: SentenceRequest):
    return {"tokens": tokenize_text(request.sentence)}

@app.post("/normalize")
def normalize(request: SentenceRequest):
    return {"normalized_text": normalize_text(request.sentence)}

THAI_NUM_WORDS = {
    "ศูนย์","หนึ่ง","สอง","สาม","สี่","ห้า","หก","เจ็ด","แปด","เก้า","สิบ",
    "ร้อย","พัน","หมื่น","แสน","ล้าน","หลาย","หน่อย","นิดหน่อย","นิด","น้อย",
    "คู่","ใบ","เล่ม","อัน","คน","ผู้","ตัว","คัน","หลัง","ถุง","แก้ว","บาท",
    "มื้อ","เทื่อ","ปี","เดือน","วัน","โมง","นาที","ชั่วโมง"
}
THAI_DIGIT_PATTERN = re.compile(r"^[0-9๐-๙]+$")

def is_quantity_like(word: str) -> bool:
    w = word.strip()
    if not w:
        return False
    if THAI_DIGIT_PATTERN.match(w):
        return True
    # สำนวนบอกปริมาณแบบสั้น
    if w in THAI_NUM_WORDS:
        return True
    # รูปผสมตัวเลข+ลักษณนาม เช่น 2คน, 3บาท
    if re.match(r"^([0-9๐-๙]+)(คน|ผู้|ตัว|คัน|ใบ|เล่ม|อัน|หลัง|ถุง|แก้ว|บาท|มื้อ|เทื่อ)$", w):
        return True
    return False

# --------- ดู pos_tag จากฐานข้อมูล ถ้ามี -----------
def lookup_pos_tag_isan(isan_word: str) -> str | None:
    conn = get_connection()
    cursor = conn.cursor(buffered=True)
    try:
        cursor.execute("SELECT pos_tag FROM isan_thai WHERE isan_word = %s LIMIT 1", (isan_word,))
        row = cursor.fetchone()
        if row and row[0]:
            return row[0].strip().lower()
        return None
    finally:
        cursor.close()
        conn.close()

# --------- ปรับคำว่า "แต่" -> "แค่" เมื่ออยู่หน้า N/จำนวน ----------
def adjust_tae(isan_tokens: list[str], thai_tokens: list[str]) -> list[str]:
    n = len(isan_tokens)
    i = 0
    while i < n:
        if isan_tokens[i] == "แต่":
            # หา token ถัดไป (ข้ามช่องว่าง)
            j = i + 1
            while j < n and isan_tokens[j].strip() == "":
                j += 1

            if j < n:
                next_isan = isan_tokens[j].strip()

                # 1) เช็ค pos_tag จาก DB
                pos = lookup_pos_tag_isan(next_isan)
                is_noun_like = pos in {"noun", "n"} if pos else False

                # 2) ฮิวริสติกคำบอกจำนวน/ปริมาณ
                qty_like = is_quantity_like(next_isan)

                if is_noun_like or qty_like:
                    # บังคับให้คำแปลของ "แต่" เป็น "แค่"
                    thai_tokens[i] = "แค่"
                else:
                    # หาก DB แปล "แต่" เป็นคำอื่นไว้แล้ว ก็ปล่อยไป
                    # ถ้ายังเป็น "แต่" ก็ให้คง "แต่"
                    thai_tokens[i] = thai_tokens[i] if thai_tokens[i] else "แต่"
            else:
                # ไม่มีคำตามหลัง คงเดิม
                thai_tokens[i] = thai_tokens[i] if thai_tokens[i] else "แต่"
        i += 1
    return thai_tokens

def adjust_tae_position(isan_tokens: list[str], thai_tokens: list[str]) -> list[str]:
    """
    ถ้า 'แต่' อยู่หน้าคำที่เป็นตำแหน่ง เช่น 'เฮือน' หรือ 'ที่' → แปลว่า 'จาก'
    """
    n = len(isan_tokens)
    i = 0
    while i < n:
        if isan_tokens[i] == "แต่":
            # หา token ถัดไป (ข้ามช่องว่าง)
            j = i + 1
            while j < n and isan_tokens[j].strip() == "":
                j += 1
            if j < n and isan_tokens[j].strip() in ["เฮือน", "ที่", "บ้าน", "มา"]:  # ตัวอย่างคำที่เกี่ยวกับตำแหน่ง
                thai_tokens[i] = "จาก"
        i += 1
    return thai_tokens

@app.post("/translate/isan-to-thai")
def translate_isan(request: SentenceRequest):
    sentence = request.sentence.strip()
    sentence = sentence.encode("utf-8").decode("utf-8")

    conn = get_connection()
    cursor = conn.cursor(buffered=True)
    try:
        cursor.execute("SELECT thai_translation FROM isan_thai WHERE isan_word = %s", (sentence,))
        rows = cursor.fetchall()
        if rows:
            options = [r[0] for r in rows]
            return {
                "translated_text": {
                    "input": sentence,
                    "output": {
                        "tokens": [
                            {"word": sentence, "options": options}
                        ]
                    }
                }
            }

        # 2) Greedy + tokenize
        words = word_tokenize(sentence, engine="newmm")
        n = len(words)
        tokens_result = []
        i = 0

        while i < n:
            found = False
            if words[i] == "สี":
                cursor.execute("SELECT thai_translation FROM isan_thai WHERE isan_word = %s", ("สี",))
                rows = cursor.fetchall()
                if rows:
                    options = [r[0] for r in rows]
                    tokens_result.append({"word": "สี", "options": options})
                else:
                    tokens_result.append({"word": "สี", "options": ["สี"]})
                i += 1
                continue
            
            for size in range(4, 0, -1):
                if i + size <= n:
                    combined_word = ''.join(words[i:i+size])
                    cursor.execute(
                        "SELECT thai_translation FROM isan_thai WHERE isan_word = %s",
                        (combined_word,)
                    )
                    rows = cursor.fetchall()
                    if rows:
                        options = [r[0] for r in rows]
                        tokens_result.append({"word": combined_word, "options": options})
                        i += size
                        found = True
                        break
            if not found:
                tokens_result.append({"word": words[i], "options": [words[i]]})
                i += 1

        # ปรับแต่ง tokens ด้วยฟังก์ชันเดิม
        isan_tokens = [t["word"] for t in tokens_result]
        thai_tokens = [t["options"][0] for t in tokens_result]  # ใช้ option แรกเป็นค่า default
        thai_tokens = adjust_bor(isan_tokens, thai_tokens)
        thai_tokens = adjust_tae(isan_tokens, thai_tokens)
        thai_tokens = adjust_tae_position(isan_tokens, thai_tokens)

        # อัปเดตค่า default ใน tokens_result หลังปรับแต่ง
        for idx, t in enumerate(tokens_result):
            if t["options"]:
                t["options"][0] = thai_tokens[idx]

        return {
            "translated_text": {
                "input": sentence,
                "output": {
                    "tokens": tokens_result
                }
            }
        }
    finally:
        cursor.close()
        conn.close()

@app.post("/translate/thai-to-isan")
def translate_thai(request: SentenceRequest):
    sentence = request.sentence.strip()
    sentence = sentence.encode("utf-8").decode("utf-8")

    conn = get_connection()
    cursor = conn.cursor(buffered=True)
    try:
        cursor.execute("SELECT isan_translation FROM thai_isan WHERE thai_word = %s", (sentence,))
        rows = cursor.fetchall()
        if rows:
            options = [r[0] for r in rows]
            return {
                "translated_text": {
                    "input": sentence,
                    "output": {
                        "tokens": [
                            {"word": sentence, "options": options}
                        ]
                    }
                }
            }

        # 2) Greedy + tokenize
        words = word_tokenize(sentence, engine="newmm")
        n = len(words)
        tokens_result = []
        i = 0

        while i < n:
            found = False
            if words[i] == "สี":
                cursor.execute("SELECT isan_translation FROM thai_isan WHERE thai_word = %s", ("สี",))
                rows = cursor.fetchall()
                if rows:
                    options = [r[0] for r in rows]
                    tokens_result.append({"word": "สี", "options": options})
                else:
                    tokens_result.append({"word": "สี", "options": ["สี"]})
                i += 1
                continue

            for size in range(4, 0, -1):
                if i + size <= n:
                    combined_word = ''.join(words[i:i+size])
                    cursor.execute(
                        "SELECT isan_translation FROM thai_isan WHERE thai_word = %s",
                        (combined_word,)
                    )
                    rows = cursor.fetchall()
                    if rows:
                        options = [r[0] for r in rows]
                        tokens_result.append({"word": combined_word, "options": options})
                        i += size
                        found = True
                        break
            if not found:
                tokens_result.append({"word": words[i], "options": [words[i]]})
                i += 1

        # ปรับแต่ง tokens ด้วยฟังก์ชันเดิม
        thai_tokens = [t["word"] for t in tokens_result]
        isan_tokens = [t["options"][0] for t in tokens_result]  # ใช้ option แรกเป็นค่า default
        isan_combined = "".join(isan_tokens)

        # อัปเดตค่า default ใน tokens_result หลังปรับแต่ง
        for idx, t in enumerate(tokens_result):
            if t["options"]:
                t["options"][0] = isan_tokens[idx]

        return {
            "translated_text": {
                "input": sentence,
                "output": {
                    "tokens": tokens_result,
                    "isan_combined": isan_combined
                }
            }
        }
    finally:
        cursor.close()
        conn.close()

@app.get("/test-db")
def test_db():
    conn = get_connection()
    cursor = conn.cursor(buffered=True)
    try:
        cursor.execute("SELECT isan_word, thai_translation FROM isan_thai LIMIT 30")
        rows = cursor.fetchall()
        data = [{"isan_word": r[0], "thai_translation": r[1]} for r in rows]
        return {"data": data}
    finally:
        cursor.close()
        conn.close()