import ccxt
import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import os
import requests

app = Flask(__name__)
CORS(app)

def get_journal_filename(api_key):
    return f'journal_{api_key}.json'

@app.route('/save_user_data', methods=['POST'])
def save_user_data():
    data = request.json
    api_key = data.get('apiKey')
    api_secret = data.get('apiSecret')
    passphrase = data.get('passphrase')

    if not api_key or not api_secret or not passphrase:
        return jsonify({"error": "Missing required parameters"}), 400

    user_data = {
        'api_key': api_key,
        'api_secret': api_secret,
        'passphrase': passphrase
    }

    user_file = f'user_{api_key}.json'
    try:
        with open(user_file, 'w') as f:
            json.dump(user_data, f)
        return jsonify({"message": "User data saved successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

def load_user_data(api_key):
    user_file = f'user_{api_key}.json'
    if os.path.exists(user_file):
        with open(user_file, 'r') as f:
            return json.load(f)
    return None

def load_journal(api_key):
    journal_file = get_journal_filename(api_key)
    if os.path.exists(journal_file):
        with open(journal_file, 'r') as f:
            return json.load(f)
    return []

def save_journal(api_key, journal):
    journal_file = get_journal_filename(api_key)
    with open(journal_file, 'w') as f:
        json.dump(journal, f)

@app.route('/fetch_orders', methods=['POST'])
def fetch_orders():
    data = request.json
    api_key = data.get('apiKey')
    api_secret = data.get('apiSecret')
    passphrase = data.get('passphrase')

    if not api_key or not api_secret or not passphrase:
        return jsonify({"error": "Missing required parameters"}), 400

    exchange = ccxt.okx({
        'apiKey': api_key,
        'secret': api_secret,
        'password': passphrase,
    })

    try:
        orders = exchange.fetch_open_orders()
        return jsonify(orders), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/place_order', methods=['POST'])
def place_order():
    data = request.json
    api_key = data.get('apiKey')
    api_secret = data.get('apiSecret')
    passphrase = data.get('passphrase')
    symbol = data.get('symbol', 'BTC/USDT')
    order_type = data.get('orderType', 'limit')
    side = data.get('side', 'buy')
    price = data.get('price')
    amount = data.get('amount')

    if not api_key or not api_secret or not passphrase or not price or not amount:
        return jsonify({"error": "Missing required parameters"}), 400

    exchange = ccxt.okx({
        'apiKey': api_key,
        'secret': api_secret,
        'password': passphrase,
    })

    try:
        if order_type == 'limit':
            order = exchange.create_limit_order(symbol, side, amount, price)
        else:
            order = exchange.create_market_order(symbol, side, amount)

        journal = load_journal(api_key)
        journal.append({
            'orderId': order['id'],
            'timestamp': datetime.datetime.now().isoformat(),
            'symbol': symbol,
            'side': side,
            'price': price,
            'amount': amount,
            'status': 'open',
            'profit': 0.0,
            'commission': 0.0
        })
        save_journal(api_key, journal)

        return jsonify({"order": order}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/cancel_order', methods=['POST'])
def cancel_order():
    data = request.json
    api_key = data.get('apiKey')
    api_secret = data.get('apiSecret')
    passphrase = data.get('passphrase')
    order_id = data.get('orderId')
    symbol = data.get('symbol', 'BTC/USDT')

    if not api_key or not api_secret or not passphrase or not order_id:
        return jsonify({"error": "Missing required parameters"}), 400

    exchange = ccxt.okx({
        'apiKey': api_key,
        'secret': api_secret,
        'password': passphrase,
    })

    try:
        result = exchange.cancel_order(order_id, symbol)

        journal = load_journal(api_key)
        for entry in journal:
            if entry['orderId'] == order_id:
                entry['status'] = 'cancelled'
        save_journal(api_key, journal)

        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/fetch_completed_orders', methods=['POST'])
def fetch_completed_orders():
    data = request.json
    api_key = data.get('apiKey')
    api_secret = data.get('apiSecret')
    passphrase = data.get('passphrase')

    if not api_key or not api_secret or not passphrase:
        return jsonify({"error": "Missing required parameters"}), 400

    exchange = ccxt.okx({
        'apiKey': api_key,
        'secret': api_secret,
        'password': passphrase,
    })

    try:
        orders = exchange.fetch_closed_orders()
        journal = load_journal(api_key)

        for order in orders:
            for entry in journal:
                if entry['orderId'] == order['id']:
                    entry['status'] = 'closed'
                    entry['profit'] = calculate_profit(journal, entry, order)
                    entry['commission'] = calculate_commission(entry, order)

        save_journal(api_key, journal)
        return jsonify(journal), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/get_balance', methods=['POST'])
def get_balance():
    data = request.json
    api_key = data.get('apiKey')
    api_secret = data.get('apiSecret')
    passphrase = data.get('passphrase')

    if not api_key or not api_secret or not passphrase:
        return jsonify({"error": "Missing required parameters"}), 400

    exchange = ccxt.okx({
        'apiKey': api_key,
        'secret': api_secret,
        'password': passphrase,
    })

    try:
        balance = exchange.fetch_balance()

        formatted_balance = {
            currency: {
                'Total': float(f"{balance['total'][currency]:.8f}"),
                'Free': float(f"{balance['free'][currency]:.8f}"),
                'Used': float(f"{balance['used'][currency]:.8f}"),
            }
            for currency in balance['total'].keys()
        }

        return jsonify(formatted_balance), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

def calculate_profit(journal, entry, order):
    amount = float(entry['amount'])
    buy_price = float(entry['price'])
    sell_price = float(order['price'])

    if entry['side'] == 'buy':
        matching_sells = [e for e in journal if
                          e['symbol'] == entry['symbol'] and e['side'] == 'sell' and e['status'] == 'closed']
        total_sell_amount = sum(float(e['amount']) for e in matching_sells)
        sell_profits = sum((float(e['price']) - buy_price) * float(e['amount']) for e in matching_sells)
        remaining_buy_amount = amount - total_sell_amount

        if remaining_buy_amount > 0:
            return (sell_price - buy_price) * remaining_buy_amount + sell_profits
        else:
            return sell_profits
    elif entry['side'] == 'sell':
        matching_buys = [e for e in journal if
                         e['symbol'] == entry['symbol'] and e['side'] == 'buy' and e['status'] == 'closed']
        total_buy_amount = sum(float(e['amount']) for e in matching_buys)
        buy_profits = sum((sell_price - float(e['price'])) * float(e['amount']) for e in matching_buys)
        remaining_sell_amount = amount - total_buy_amount

        if remaining_sell_amount > 0:
            return (sell_price - buy_price) * remaining_sell_amount + buy_profits
        else:
            return buy_profits
    else:
        return 0.0

@app.route('/get_price', methods=['GET'])
def get_price():
    try:
        exchange = ccxt.okx()
        ticker = exchange.fetch_ticker('BTC/USDT')
        price = ticker['last']
        return jsonify({"price": price}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

def calculate_commission(entry, order):
    commission_rate = 0.001 if order['type'] == 'market' else 0.0008
    return float(order['cost']) * commission_rate

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
