import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class JournalScreen extends StatefulWidget {
  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List _completedOrders = [];
  double _totalProfit = 0.0;
  double _averageBuyPrice = 0.0;
  double _averageSellPrice = 0.0;
  double _totalRealizedAmount = 0.0;
  Map<String, dynamic> _balance = {};

  @override
  void initState() {
    super.initState();
    _loadCachedData(); // Загрузка кешированных данных (баланс и история сделок)
    _fetchCompletedOrders();
    _fetchBalance();
  }

  Future<void> _fetchCompletedOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('apiKey');
    final apiSecret = prefs.getString('apiSecret');
    final passphrase = prefs.getString('passphrase');

    if (apiKey == null || apiSecret == null || passphrase == null) {
      return;
    }

    final url = Uri.parse('http://185.180.231.10:5001/fetch_completed_orders');
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
      setState(() {
        _completedOrders = jsonDecode(response.body);
        _calculateStatistics();
      });
      _cacheCompletedOrders(_completedOrders); // Кеширование данных после успешного запроса
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
      setState(() {
        _balance = {
          'USDT': balanceData['USDT'],
          'BTC': balanceData['BTC'],
        };
      });
      _cacheBalance(balanceData); // Кеширование данных после успешного запроса
    } else {
      print('Failed to fetch balance');
    }
  }

  Future<void> _cacheBalance(Map<String, dynamic> balanceData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cachedBalance', jsonEncode(balanceData));
  }

  Future<void> _cacheCompletedOrders(List completedOrders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cachedCompletedOrders', jsonEncode(completedOrders));
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedBalance = prefs.getString('cachedBalance');
    if (cachedBalance != null) {
      setState(() {
        _balance = jsonDecode(cachedBalance);
      });
    }

    final cachedCompletedOrders = prefs.getString('cachedCompletedOrders');
    if (cachedCompletedOrders != null) {
      setState(() {
        _completedOrders = jsonDecode(cachedCompletedOrders);
        _calculateStatistics(); // Пересчёт статистики на основе кешированных данных
      });
    }
  }

  void _calculateStatistics() {
    double totalBuyAmount = 0.0;
    double totalBuyCost = 0.0;
    double totalSellAmount = 0.0;
    double totalSellRevenue = 0.0;
    double totalProfit = 0.0;
    double totalRealizedAmount = 0.0;

    for (var order in _completedOrders) {
      if (order['status'] == 'closed') {
        double price = double.tryParse(order['price'].toString()) ?? 0.0;
        double amount = double.tryParse(order['amount'].toString()) ?? 0.0;
        double fee = double.tryParse(order['fee'].toString()) ?? 0.0;

        if (order['side'] == 'buy') {
          totalBuyAmount += amount;
          totalBuyCost += price * amount + fee;
        } else if (order['side'] == 'sell') {
          totalSellAmount += amount;
          totalSellRevenue += price * amount - fee;

          double averageBuyPrice = totalBuyAmount > 0 ? totalBuyCost / totalBuyAmount : 0.0;
          totalProfit += (price * amount) - fee - (amount * averageBuyPrice);
          totalRealizedAmount += amount;
        }
      }
    }

    setState(() {
      _totalProfit = totalProfit;
      _averageBuyPrice = totalBuyAmount > 0 ? totalBuyCost / totalBuyAmount : 0.0;
      _averageSellPrice = totalSellAmount > 0 ? totalSellRevenue / totalSellAmount : 0.0;
      _totalRealizedAmount = totalRealizedAmount;
    });
  }

  Future<void> _refreshData() async {
    await _fetchCompletedOrders();
    await _fetchBalance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Journal'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_balance.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
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
                            SizedBox(width: 30), // Пространство между двумя колонками
                            Expanded(child: _buildBalanceColumn('BTC')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: _completedOrders.length,
                  itemBuilder: (context, index) {
                    final order = _completedOrders[_completedOrders.length - 1 - index];
                    return ListTile(
                      title: Text('${order['symbol']} ${order['side']} ${order['amount']} @ ${order['price']}'),
                      subtitle: Text('Status: ${order['status']}\nTime: ${order['timestamp']}'),
                    );
                  },
                ),
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Profit: ${_totalProfit.toStringAsFixed(10)} USDT',
                      style: TextStyle(color: Colors.amber[800], fontSize: 12),
                    ),
                    Text(
                      'Average Buy Price: ${_averageBuyPrice.toStringAsFixed(2)} USDT',
                      style: TextStyle(color: Colors.amber[800], fontSize: 12),
                    ),
                    Text(
                      'Average Sell Price: ${_averageSellPrice.toStringAsFixed(2)} USDT',
                      style: TextStyle(color: Colors.amber[800], fontSize: 12),
                    ),
                    Text(
                      'Total Realized Amount: ${_totalRealizedAmount.toStringAsFixed(10)} BTC',
                      style: TextStyle(color: Colors.amber[800], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
