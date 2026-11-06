import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lenskie_flora/services/location_service.dart';

void main() {
  test('android asks the phone GPS instead of Google services', () {
    final settings = locationFixSettings(android: true) as AndroidSettings;
    expect(settings.forceLocationManager, isTrue);
    expect(settings.accuracy, LocationAccuracy.high);
    expect(settings.timeLimit, const Duration(seconds: 45));
  });

  test('apple devices keep the system location settings', () {
    final settings = locationFixSettings(android: false);
    expect(settings, isNot(isA<AndroidSettings>()));
    expect(settings.accuracy, LocationAccuracy.high);
    expect(settings.timeLimit, const Duration(seconds: 45));
  });
}
