import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isSettingEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSettingEnabled = prefs.getBool('settingEnabled') ?? false;
    });
  }

  Future<void> _updateSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settingEnabled', value);
    setState(() {
      _isSettingEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.black87,
      ),
      body: ListTile(
        title: const Text('Enable Feature'),
        trailing: Switch(
          value: _isSettingEnabled,
          onChanged: (bool value) {
            // Update the state and persist the new value
            _updateSetting(value);
          },
        ),
      ),
    );
  }
}
