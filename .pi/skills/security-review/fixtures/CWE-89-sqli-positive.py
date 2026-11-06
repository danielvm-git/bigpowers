# story: e45s26
# fixture: CWE-89 positive — MUST be flagged as SQL injection
import sqlite3

def get_user(user_id: str) -> dict:
    conn = sqlite3.connect("app.db")
    # VULNERABLE: user-controlled string interpolated into SQL
    query = f"SELECT * FROM users WHERE id = {user_id}"
    return conn.execute(query).fetchone()
