import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto_tracker/settings_screen.dart';
import 'package:crypto_tracker/password_check_screen.dart';
import 'package:crypto_tracker/login_screen.dart';
import 'package:crypto_tracker/order_screen.dart';
import 'package:crypto_tracker/analytics_screen.dart';
import 'package:crypto_tracker/journal_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    WebView(
      initialUrl: Uri.dataFromString(
        '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>TradingView Chart</title>
          <style>
            body, html, #tradingview_6c58c {
              margin: 0;
              padding: 0;
              height: 100%;
              width: 100%;
            }
          </style>
        </head>
        <body>
          <!-- TradingView Widget BEGIN -->
          <div class="tradingview-widget-container">
            <div id="tradingview_6c58c"></div>
            <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
            <script type="text/javascript">
            new TradingView.widget(
            {
              "width": "100%",
              "height": "100%",
              "symbol": "OKX:BTCUSDT",
              "interval": "D",
              "timezone": "Etc/UTC",
              "theme": "dark",
              "style": "1",
              "locale": "en",
              "toolbar_bg": "#f1f3f6",
              "enable_publishing": false,
              "allow_symbol_change": false,
              "container_id": "tradingview_6c58c",
              "studies": [
                "RSI@tv-basicstudies",
                "MACD@tv-basicstudies",
                "MAExp@tv-basicstudies"
              ],
              "overrides": {
                "mainSeriesProperties.style": 1,
                "mainSeriesProperties.showCountdown": true,
                "paneProperties.background": "#131722",
                "paneProperties.vertGridProperties.color": "#363c4e",
                "paneProperties.horzGridProperties.color": "#363c4e",
                "symbolWatermarkProperties.transparency": 90,
                "scalesProperties.textColor": "#AAA",
                "scalesProperties.lineColor": "#555",
                "movingAverage.length": 50
              }
            });
            </script>
          </div>
          <!-- TradingView Widget END -->
        </body>
        </html>
        ''',
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8'),
      ).toString(),
      javascriptMode: JavascriptMode.unrestricted,
    ),
    OrderScreen(),
    AnalyticsScreen(),
    JournalScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cryptotracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PasswordCheckScreen(nextScreen: SettingsScreen())),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_token');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Chart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Journal',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
