import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class OrderScreen extends StatefulWidget {
  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> with WidgetsBindingObserver {
  final _priceController = TextEditingController();
  final _amountController = TextEditingController();
  String _orderType = 'limit';
  String _side = 'buy';
  bool _isLoading = false;
  double _currentPrice = 0.0;
  Timer? _priceTimer;
  Timer? _orderTimer;
  Timer? _balanceTimer;
  List<dynamic> _openOrders = [];
  Map<String, dynamic> _balance = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCachedBalance();
    _startFetchingData();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _amountController.dispose();
    _stopFetchingData();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startFetchingData() {
    _fetchCurrentPrice();
    _fetchOpenOrders();
    _fetchBalance();

    _priceTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchCurrentPrice();
    });

    _orderTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchOpenOrders();
    });

    _balanceTimer = Timer.periodic(Duration(minutes: 60), (timer) {
      _fetchBalance();
    });
  }

  void _stopFetchingData() {
    _priceTimer?.cancel();
    _orderTimer?.cancel();
    _balanceTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startFetchingData();
    } else if (state == AppLifecycleState.paused) {
      _stopFetchingData();
    }
  }

  Future<void> _fetchCurrentPrice() async {
    try {
      final response = await http.get(Uri.parse('http://185.180.231.10:5001/get_price'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _currentPrice = data['price'];
          });
        }
      } else {
        print('Failed to fetch current price from server');
      }
    } catch (e) {
      print('Error fetching current price: $e');
    }
  }

  Future<void> _fetchBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('apiKey');
    final apiSecret = prefs.getString('apiSecret');
    final passphrase = prefs.getString('passphrase');

    if (apiKey == null || apiSecret == null || passphrase == null) {
      return;
    }

    final url = Uri.parse('http://185.180.231.10:5001/get_balance');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'apiKey': apiKey,
        'apiSecret': apiSecret,
        'passphrase': passphrase,
      }),
    );

    if (response.statusCode == 200) {
      final balanceData = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          _balance = {
            'USDT': balanceData['USDT'],
            'BTC': balanceData['BTC'],
          };
        });
        _cacheBalance(balanceData);
      }
    } else {
      print('Failed to fetch balance');
    }
  }

  Future<void> _fetchOpenOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('apiKey');
    final apiSecret = prefs.getString('apiSecret');
    final passphrase = prefs.getString('passphrase');

    if (apiKey == null || apiSecret == null || passphrase == null) {
      return;
    }

    final url = Uri.parse('http://185.180.231.10:5001/fetch_orders');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'apiKey': apiKey,
        'apiSecret': apiSecret,
        'passphrase': passphrase,
      }),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        setState(() {
          _openOrders = jsonDecode(response.body);
        });
      }
    } else {
      print('Failed to fetch open orders');
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('apiKey');
    final apiSecret = prefs.getString('apiSecret');
    final passphrase = prefs.getString('passphrase');

    if (apiKey == null || apiSecret == null || passphrase == null) {
      return;
    }

    final url = Uri.parse('http://185.180.231.10:5001/cancel_order');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'apiKey': apiKey,
        'apiSecret': apiSecret,
        'passphrase': passphrase,
        'orderId': orderId,
      }),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order cancelled successfully')),
        );
        _fetchOpenOrders();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel order')),
      );
    }
  }

  Future<void> _submitOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('apiKey');
    final apiSecret = prefs.getString('apiSecret');
    final passphrase = prefs.getString('passphrase');

    if (apiKey == null || apiSecret == null || passphrase == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API credentials not set')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('http://185.180.231.10:5001/place_order');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'apiKey': apiKey,
        'apiSecret': apiSecret,
        'passphrase': passphrase,
        'symbol': 'BTC/USDT',
        'orderType': _orderType,
        'side': _side,
        'price': _orderType == 'market' ? _currentPrice.toString() : _priceController.text,
        'amount': _amountController.text,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order placed successfully')),
        );
        _fetchOpenOrders();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order')),
      );
    }
  }

  Future<void> _cacheBalance(Map<String, dynamic> balanceData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cachedBalance', jsonEncode(balanceData));
  }

  Future<void> _loadCachedBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedBalance = prefs.getString('cachedBalance');
    if (cachedBalance != null) {
      setState(() {
        _balance = jsonDecode(cachedBalance);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Place Order'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _priceController,
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              enabled: _orderType == 'limit',
            ),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ToggleButtons(
                  isSelected: [_orderType == 'limit', _orderType == 'market'],
                  onPressed: (int index) {
                    setState(() {
                      _orderType = index == 0 ? 'limit' : 'market';
                    });
                  },
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Limit'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Market'),
                    ),
                  ],
                ),
                ToggleButtons(
                  isSelected: [_side == 'buy', _side == 'sell'],
                  onPressed: (int index) {
                    setState(() {
                      _side = index == 0 ? 'buy' : 'sell';
                    });
                  },
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Buy'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Sell'),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _submitOrder,
              child: Text('Submit Order'),
            ),
            SizedBox(height: 20),
            Text('Current Price: \$$_currentPrice'),
            SizedBox(height: 20),
            Text('Open Orders:'),
            Expanded(
              child: ListView.builder(
                itemCount: _openOrders.length,
                itemBuilder: (context, index) {
                  final order = _openOrders[index];
                  return ListTile(
                    title: Text('${order['symbol']} ${order['side']} ${order['amount']} @ ${order['price']}'),
                    subtitle: Text('Order ID: ${order['id']}'),
                    trailing: IconButton(
                      icon: Icon(Icons.cancel),
                      onPressed: () {
                        _cancelOrder(order['id']);
                      },
                    ),
                  );
                },
              ),
            ),
            Divider(),
            if (_balance.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'PORTFOLIO',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(child: _buildBalanceColumn('USDT')),
                          SizedBox(width: 30),
                          Expanded(child: _buildBalanceColumn('BTC')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceColumn(String currency) {
    final balanceInfo = _balance[currency];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$currency:',
          style: TextStyle(color: Colors.amber[800], fontSize: 12),
        ),
        Text(
          '  Total: ${balanceInfo['Total']}',
          style: TextStyle(color: Colors.amber[800], fontSize: 12),
        ),
        Text(
          '  Free: ${balanceInfo['Free']}',
          style: TextStyle(color: Colors.amber[800], fontSize: 12),
        ),
        Text(
          '  Used: ${balanceInfo['Used']}',
          style: TextStyle(color: Colors.amber[800], fontSize: 12),
        ),
      ],
    );
  }
}
