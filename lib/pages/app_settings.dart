import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  bool _useEnglishUnits = false;
  // Adding the latitude and longitude representation setting
  static const int decimalDegrees = 0;
  static const int degreesMinutesSeconds = 1;
  static const int degreesDecimalMinutes = 2;
  int _representationType = decimalDegrees;

  bool get useEnglishUnits => _useEnglishUnits;

  int get representationType => _representationType;

  void toggleUnitSystem() {
    _useEnglishUnits = !_useEnglishUnits;
    _saveSettings();
    notifyListeners();
  }

  void setRepresentationType(int type) {
    _representationType = type;
    _saveSettings();
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useEnglishUnits', _useEnglishUnits);
    await prefs.setInt('representationType', _representationType);
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _useEnglishUnits = prefs.getBool('useEnglishUnits') ?? false;
    _representationType = prefs.getInt('representationType') ?? decimalDegrees;
    notifyListeners();
  }

  // convert meters to feet
  double convertAltitude(double altitudeInMeters) {
    return _useEnglishUnits ? altitudeInMeters * 3.28084 : altitudeInMeters;
  }


  String formatLatitude(double latitude) {
    return _formatCoordinate(latitude, true); // true for latitude
  }

  String formatLongitude(double longitude) {
    return _formatCoordinate(longitude, false); // false for longitude
  }

  String _formatCoordinate(double coordinate, bool isLatitude) {
    switch (_representationType) {
      case decimalDegrees:
        return coordinate.toStringAsFixed(5);
      case degreesMinutesSeconds:
        return _toDMS(coordinate, isLatitude);
      case degreesDecimalMinutes:
        return _toDDM(coordinate);
      default:
        return coordinate.toStringAsFixed(5);
    }
  }

  String _toDMS(double degrees, bool isLatitude) {
    // Determine the cardinal direction
    String cardinalDirection = "";
    if (isLatitude) {
      cardinalDirection = degrees >= 0 ? "N" : "S";
    } else {
      cardinalDirection = degrees >= 0 ? "E" : "W";
    }

    // Convert degrees to absolute value for calculation
    degrees = degrees.abs();

    int d = degrees.floor();
    double minFloat = (degrees - d) * 60;
    int m = minFloat.floor();
    double secFloat = (minFloat - m) * 60;
    // Using round() instead of toInt() to properly handle rounding
    int s = secFloat.round();

    return "$d°$m'$s\" $cardinalDirection";
  }



  String _toDDM(double degrees) {
    int d = degrees.truncate();
    double minutes = (degrees - d) * 60;
    return "$d° ${minutes.toStringAsFixed(3)}'";
  }

}
