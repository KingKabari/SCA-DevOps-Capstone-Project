from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    return "App Node is Running!", 200

@app.route('/health')
def health():
    return "Healthy", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)