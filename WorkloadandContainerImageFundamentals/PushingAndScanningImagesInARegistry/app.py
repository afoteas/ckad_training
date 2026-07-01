from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    # A simple Python web app, which is a common use case for a microservice
    return "Hello from the Python Container! My environment is secure... or is it?"

if __name__ == "__main__":
    # Listen on all interfaces on port 8080
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))