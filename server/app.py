import os
from flask import Flask, request, jsonify, url_for, send_from_directory
from flask_bcrypt import Bcrypt
from flask_cors import CORS
from flask_mail import Mail, Message
from flask_sqlalchemy import SQLAlchemy
from itsdangerous import URLSafeTimedSerializer, SignatureExpired, BadTimeSignature
import logging
import threading
import time
import ccxt

app = Flask(__name__)
bcrypt = Bcrypt(app)
CORS(app)

app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USE_SSL'] = False
app.config['MAIL_USERNAME'] = 'yourcryptotracker@gmail.com'
app.config['MAIL_PASSWORD'] = 'yvbz qays mayt aysl'
app.config['MAIL_DEFAULT_SENDER'] = 'yourcryptotracker@gmail.com'

app.config['SECRET_KEY'] = 'artem_ivr'  
serializer = URLSafeTimedSerializer(app.config['SECRET_KEY'])

app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///users.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

mail = Mail(app)
db = SQLAlchemy(app)

logging.basicConfig(level=logging.INFO)

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password = db.Column(db.String(200), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    confirmed = db.Column(db.Boolean, default=False)

    def __repr__(self):
        return f'<User {self.username}>'

class PriceAlert(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), nullable=False)
    alert_price = db.Column(db.Float, nullable=False)

with app.app_context():
    db.create_all()

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    email = data.get('email')

    logging.info(f"Register attempt with username: {username}, email: {email}")

    if not username or not password or not email:
        logging.error("Invalid input")
        return jsonify({"error": "Invalid input"}), 400

    existing_user_by_username = User.query.filter_by(username=username).first()
    existing_user_by_email = User.query.filter_by(email=email).first()

    if existing_user_by_username or existing_user_by_email:
        if existing_user_by_username:
            logging.error(f"Username {username} already exists")
        if existing_user_by_email:
            logging.error(f"Email {email} already exists")
        return jsonify({"error": "Username or email already exists"}), 400

    hashed_password = bcrypt.generate_password_hash(password).decode('utf-8')
    new_user = User(username=username, password=hashed_password, email=email)
    db.session.add(new_user)
    db.session.commit()

    token = serializer.dumps(email, salt='email-confirmation-salt')
    confirm_url = url_for('confirm_email', token=token, _external=True)
    msg = Message('Confirm your email', recipients=[email])
    msg.body = f'Thanks for signing up! Please click the link to confirm your email address: {confirm_url}'
    try:
        mail.send(msg)
        logging.info("Confirmation email sent")
    except Exception as e:
        logging.error(f"Error sending email: {e}")
        return jsonify({"error": "Failed to send confirmation email"}), 500

    return jsonify({"message": "Registration successful, please check your email to confirm your address"}), 201

@app.route('/confirm/<token>')
def confirm_email(token):
    try:
        email = serializer.loads(token, salt='email-confirmation-salt', max_age=3600)
        user = User.query.filter_by(email=email).first()
        if user:
            user.confirmed = True
            db.session.commit()
            return jsonify({"message": "Email confirmed"}), 200
        else:
            return jsonify({"error": "User not found"}), 404
    except SignatureExpired:
        return jsonify({"error": "The confirmation link has expired"}), 400
    except BadTimeSignature:
        return jsonify({"error": "Invalid token"}), 400

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    logging.info(f"Login attempt with username: {username}")

    if not username or not password:
        logging.error("Invalid input")
        return jsonify({"error": "Invalid input"}), 400

    user = User.query.filter_by(username=username).first()

    if not user or not bcrypt.check_password_hash(user.password, password):
        logging.error("Invalid username or password")
        return jsonify({"error": "Invalid username or password"}), 401

    if not user.confirmed:
        logging.error("Email not confirmed")
        return jsonify({"error": "Email not confirmed"}), 401

    return jsonify({"message": "Login successful"}), 200

@app.route('/reset_password_request', methods=['POST'])
def reset_password_request():
    data = request.get_json()
    email = data.get('email')
    logging.info(f"Received password reset request for email: {email}")
    user = User.query.filter_by(email=email).first()

    if not user:
        logging.error("Email not found")
        return jsonify({"error": "Email not found"}), 404

    token = serializer.dumps(email, salt='password-reset-salt')
    reset_url = url_for('reset_password', token=token, _external=True)
    msg = Message('Password Reset Request', recipients=[email])
    msg.body = f'To reset your password, click the following link: {reset_url}'
    mail.send(msg)
    logging.info(f"Password reset link sent to email: {email}")
    return jsonify({"message": "Password reset link sent to your email"}), 200

@app.route('/reset_password/<token>', methods=['GET', 'POST'])
def reset_password(token):
    try:
        email = serializer.loads(token, salt='password-reset-salt', max_age=3600)
        user = User.query.filter_by(email=email).first()

        if not user:
            return jsonify({"error": "User not found"}), 404

        if request.method == 'GET':
            return send_from_directory(os.getcwd(), 'reset_password.html')

        data = request.get_json()
        new_password = data.get('new_password')
        confirm_password = data.get('confirm_password')

        if not new_password or not confirm_password:
            return jsonify({"error": "Invalid input"}), 400

        if new_password != confirm_password:
            return jsonify({"error": "Passwords do not match"}), 400

        user.password = bcrypt.generate_password_hash(new_password).decode('utf-8')
        db.session.commit()

        return jsonify({"message": "Password has been reset"}), 200

    except SignatureExpired:
        return jsonify({"error": "The reset link has expired"}), 400
    except BadTimeSignature:
        return jsonify({"error": "Invalid token"}), 400

@app.route('/set_price_alert', methods=['POST'])
def set_price_alert():
    data = request.get_json()
    email = data.get('email')
    alert_price = data.get('alert_price')

    new_alert = PriceAlert(email=email, alert_price=alert_price)
    db.session.add(new_alert)
    db.session.commit()

    threading.Thread(target=monitor_price, args=(new_alert.id, alert_price)).start()

    return jsonify({"message": "Price alert set successfully"}), 200

def get_btc_usdt_price():
    exchange = ccxt.okx()
    ticker = exchange.fetch_ticker('BTC/USDT')
    return ticker['last']

def monitor_price(alert_id, alert_price):
    while True:
        current_price = get_btc_usdt_price()
        if current_price <= alert_price:
            alert = PriceAlert.query.get(alert_id)
            if alert:
                db.session.delete(alert)
                db.session.commit()
            send_notification("Price Alert", f"BTC/USDT has reached your alert price of {alert_price}")
            break
        time.sleep(60)

def send_notification(title, body):
    import requests
    url = "http://localhost:5000/send_notification"
    payload = {"title": title, "body": body}
    headers = {'Content-Type': 'application/json'}
    requests.post(url, json=payload, headers=headers)

@app.route('/send_notification', methods=['POST'])
def send_notification_route():
    data = request.get_json()
    title = data.get('title')
    body = data.get('body')

    return jsonify({"message": "Notification sent"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
