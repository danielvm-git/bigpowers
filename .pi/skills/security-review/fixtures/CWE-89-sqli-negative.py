# story: e45s26
# fixture: CWE-89 negative — MUST NOT be flagged (parameterized query)
import sqlite3

def get_user(user_id: str) -> dict:
    conn = sqlite3.connect("app.db")
    # SAFE: bound parameter — proven authorship, no attacker-reachable interpolation
    return conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
