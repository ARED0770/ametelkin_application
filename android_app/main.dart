import 'package:flutter/material.dart';
import 'package:crypto_tracker/home_screen.dart';
import 'package:crypto_tracker/login_screen.dart';
import 'package:crypto_tracker/register_screen.dart';
import 'package:crypto_tracker/reset_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Future<bool> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_token') != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Tracker',
      theme: ThemeData.dark(),
      home: FutureBuilder(
        future: _checkLoginStatus(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else {
            return snapshot.data == true ? HomeScreen() : LoginScreen();
          }
        },
      ),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/reset-password': (context) => ResetPasswordScreen(),
      },
    );
  }
}
