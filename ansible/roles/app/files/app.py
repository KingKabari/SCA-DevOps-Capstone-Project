import os
from flask import Flask

app = Flask(__name__)

# Credentials come from environment only
DB_HOST = os.getenv('DB_HOST')
DB_PORT = os.getenv('DB_PORT')
DB_NAME = os.getenv('DB_NAME')
DB_USER = os.getenv('DB_USER')
DB_PASS = os.getenv('DB_PASS')

@app.route('/')
def home():
    return "App Node is Running!", 200

@app.route('/health')
def health():
    return "Healthy", 200

@app.route('/db-check')
def db_check():
    try:
        import psycopg2
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        conn.close()
        return "DB Connection Successful!", 200
    except Exception as e:
        return f"DB Connection Failed: {str(e)}", 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
