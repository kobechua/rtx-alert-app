import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  bool _useEnglishUnits = false;

  bool get useEnglishUnits => _useEnglishUnits;

  void toggleUnitSystem() {
    _useEnglishUnits = !_useEnglishUnits;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useEnglishUnits', _useEnglishUnits);
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _useEnglishUnits = prefs.getBool('useEnglishUnits') ?? false;
    notifyListeners();
  }

  // convert meters to feet
  double convertAltitude(double altitudeInMeters) {
    return _useEnglishUnits ? altitudeInMeters * 3.28084 : altitudeInMeters;
  }
}
