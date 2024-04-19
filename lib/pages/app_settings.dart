import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proj4dart/proj4dart.dart';
import 'package:mgrs_dart/mgrs_dart.dart';

class AppSettings extends ChangeNotifier {
  bool _useEnglishUnits = false;
  static const int decimalDegrees = 0;
  static const int degreesMinutesSeconds = 1;
  static const int degreesDecimalMinutes = 2;
  static const int utm = 3;
  static const int mgrs = 4;
  int _representationType = decimalDegrees;

  AppSettings() {
    defineProjections();
    checkProjections();
  }

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

  double convertAltitude(double altitudeInMeters) {
    return _useEnglishUnits ? altitudeInMeters * 3.28084 : altitudeInMeters;
  }

  void defineProjections() {
    Projection.add('EPSG:4326', '+proj=longlat +datum=WGS84 +no_defs');
  }

  void checkProjections() {
    var wgs84 = Projection.get('EPSG:4326');
    var utm = Projection.get('EPSG:32617');
    print('WGS84 Projection: $wgs84');
    print('UTM Projection: $utm');
  }

  String formatCoordinate(double latitude, double longitude, bool isLatitude) {
    switch (_representationType) {
      case decimalDegrees:
        return isLatitude ? latitude.toStringAsFixed(5) : longitude.toStringAsFixed(5);
      case degreesMinutesSeconds:
        return _toDMS(isLatitude ? latitude : longitude, isLatitude);
      case degreesDecimalMinutes:
        return _toDDM(isLatitude ? latitude : longitude);
      case utm:
        return _toUTM(latitude, longitude);
      case mgrs:
        return _toMGRS(latitude, longitude);
      default:
        return isLatitude ? latitude.toStringAsFixed(5) : longitude.toStringAsFixed(5);
    }
  }

  String _toDMS(double degrees, bool isLatitude) {
    int d = degrees.abs().floor();
    double min = (degrees.abs() - d) * 60;
    int m = min.floor();
    double s = (min - m) * 60;

    String seconds = s.toStringAsFixed(4);
    String cardinal = degrees >= 0 ? (isLatitude ? "N" : "E") : (isLatitude ? "S" : "W");
    return "$d°$m'$seconds\" $cardinal";
  }

  String _toDDM(double degrees) {
    int d = degrees.truncate();
    double minutes = (degrees - d) * 60;
    return "$d° ${minutes.toStringAsFixed(3)}'";
  }

  String _toUTM(double latitude, double longitude) {
    int zone = ((longitude + 180) / 6).floor() + 1;
    String utmKey = 'EPSG:326${zone < 10 ? '0$zone' : zone.toString()}';
    Projection.add(utmKey, '+proj=utm +zone=$zone +datum=WGS84 +units=m +no_defs');
    
    var wgs84 = Projection.get('EPSG:4326');
    var utm = Projection.get(utmKey);
    if (wgs84 == null || utm == null) {
      return "UTM: Unavailable";
    }
    
    var point = Point(x: longitude, y: latitude);
    var utmPoint = wgs84.transform(utm, point);
    return "UTM Zone $zone\nE: ${utmPoint.x.toStringAsFixed(0)}\nN: ${utmPoint.y.toStringAsFixed(0)}";
  }

  String _toMGRS(double latitude, double longitude) {
    return "MGRS: ${Mgrs.forward([longitude, latitude], 5)}";
  }

  bool shouldShowLatLonLabels() {
    return _representationType == decimalDegrees || _representationType == degreesMinutesSeconds || _representationType == degreesDecimalMinutes;
  }
  
}
