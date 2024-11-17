import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordCheckScreen extends StatefulWidget {
  final Widget nextScreen;

  PasswordCheckScreen({required this.nextScreen});

  @override
  _PasswordCheckScreenState createState() => _PasswordCheckScreenState();
}

class _PasswordCheckScreenState extends State<PasswordCheckScreen> {
  final _passwordController = TextEditingController();
  bool _error = false;

  Future<void> _checkPassword() async {
    final prefs = await SharedPreferences.getInstance();
    String savedPassword = prefs.getString('user_password') ?? '';
    print('Saved password: $savedPassword'); // Логирование сохраненного пароля
    print('Entered password: ${_passwordController.text.trim()}'); // Логирование введенного пароля

    if (_passwordController.text.trim() == savedPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => widget.nextScreen),
      );
    } else {
      setState(() {
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (_error) Text('Incorrect password', style: TextStyle(color: Colors.red)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkPassword,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
