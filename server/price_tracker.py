import ccxt
import threading
import time
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///alerts.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)
CORS(app)

class PriceAlert(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), nullable=False)
    alert_price = db.Column(db.Float, nullable=False)

db.create_all()

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

@app.route('/send_notification', methods=['POST'])
def send_notification_route():
    data = request.get_json()
    title = data.get('title')
    body = data.get('body')
    return jsonify({"message": "Notification sent"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
