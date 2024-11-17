from flask import Flask, request, jsonify
from flask_bcrypt import Bcrypt
from flask_mail import Mail, Message
import sqlite3
import re

app = Flask(__name__)
bcrypt = Bcrypt(app)
mail = Mail(app)

app.config['MAIL_SERVER'] = 'smtp.example.com'  
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USERNAME'] = 'your_email@example.com'
app.config['MAIL_PASSWORD'] = 'your_email_password'

def create_user_table():
    conn = sqlite3.connect('users.db')
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS users
                 (id INTEGER PRIMARY KEY AUTOINCREMENT,
                  username TEXT UNIQUE NOT NULL,
                  password TEXT NOT NULL,
                  email TEXT UNIQUE NOT NULL,
                  confirmed INTEGER NOT NULL DEFAULT 0)''')
    conn.commit()
    conn.close()

def validate_email(email):
    regex = r'^\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
    return re.match(regex, email) is not None

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    username = data['username']
    password = data['password']
    email = data['email']

    if not validate_email(email):
        return jsonify({'error': 'Invalid email format'}), 400

    if len(password) < 6 or len(password) > 30:
        return jsonify({'error': 'Password must be between 6 and 30 characters'}), 400

    hashed_password = bcrypt.generate_password_hash(password).decode('utf-8')

    conn = sqlite3.connect('users.db')
    c = conn.cursor()
    try:
        c.execute("INSERT INTO users (username, password, email) VALUES (?, ?, ?)",
                  (username, hashed_password, email))
        conn.commit()
        user_id = c.lastrowid
    except sqlite3.IntegrityError:
        return jsonify({'error': 'Username or email already exists'}), 400
    finally:
        conn.close()

    token = bcrypt.generate_password_hash(email).decode('utf-8')

    msg = Message('Confirm Your Email', sender='noreply@demo.com', recipients=[email])
    msg.body = f'''To confirm your email, visit the following link:
    http://127.0.0.1:5000/confirm/{user_id}/{token}
    '''
    mail.send(msg)

    return jsonify({'message': 'User registered successfully. Please check your email to confirm your registration.'}), 201

@app.route('/confirm/<int:user_id>/<token>', methods=['GET'])
def confirm_email(user_id, token):
    conn = sqlite3.connect('users.db')
    c = conn.cursor()
    c.execute("SELECT email FROM users WHERE id = ?", (user_id,))
    user = c.fetchone()
    conn.close()

    if user and bcrypt.check_password_hash(token, user[0]):
        conn = sqlite3.connect('users.db')
        c = conn.cursor()
        c.execute("UPDATE users SET confirmed = 1 WHERE id = ?", (user_id,))
        conn.commit()
        conn.close()
        return jsonify({'message': 'Email confirmed successfully'}), 200
    else:
        return jsonify({'error': 'Invalid or expired token'}), 400

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data['username']
    password = data['password']

    conn = sqlite3.connect('users.db')
    c = conn.cursor()
    c.execute("SELECT id, password, confirmed FROM users WHERE username = ?", (username,))
    user = c.fetchone()
    conn.close()

    if user and bcrypt.check_password_hash(user[1], password):
        if user[2] == 1:
            return jsonify({'message': 'Login successful', 'user_id': user[0]}), 200
        else:
            return jsonify({'error': 'Email not confirmed'}), 400
    else:
        return jsonify({'error': 'Invalid username or password'}), 400

if __name__ == '__main__':
    create_user_table()
    app.run(host='0.0.0.0', port=5000)
