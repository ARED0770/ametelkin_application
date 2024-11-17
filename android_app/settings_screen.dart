import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _apiSecretController = TextEditingController();
  final _passphraseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApiCredentials();
  }

  Future<void> _loadApiCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('apiKey') ?? '';
      _apiSecretController.text = prefs.getString('apiSecret') ?? '';
      _passphraseController.text = prefs.getString('passphrase') ?? '';
    });
  }

  Future<void> _saveApiCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiKey', _apiKeyController.text);
    await prefs.setString('apiSecret', _apiSecretController.text);
    await prefs.setString('passphrase', _passphraseController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('API credentials saved')),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(labelText: 'OKX API Key'),
              keyboardType: TextInputType.text,
            ),
            TextField(
              controller: _apiSecretController,
              decoration: InputDecoration(labelText: 'OKX API Secret'),
              keyboardType: TextInputType.text,
            ),
            TextField(
              controller: _passphraseController,
              decoration: InputDecoration(labelText: 'OKX Passphrase'),
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveApiCredentials,
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
