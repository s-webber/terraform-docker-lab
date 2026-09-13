import os

import psycopg
from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/")
def index():
    return "Hello from Flask!"


@app.route("/health")
def health():
    return "heathly"


@app.route("/users")
def users():
    conn = psycopg.connect(
        host=os.environ["DB_HOST"],
        port=os.environ["DB_PORT"],
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
    )

    with conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name FROM users ORDER BY id")
            rows = cur.fetchall()

    return jsonify([
        {"id": row[0], "name": row[1]}
        for row in rows
    ])


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
