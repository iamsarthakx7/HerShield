import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeService {
  static const double shakeThreshold = 15.0;
  static const int minShakeCount = 2;

  int _shakeCount = 0;
  DateTime _lastShakeTime = DateTime.now();

  StreamSubscription? _subscription;

  void startListening(Function onShake) {
    _subscription = accelerometerEvents.listen((event) {
      double acceleration =
          event.x * event.x + event.y * event.y + event.z * event.z;

      if (acceleration > shakeThreshold * shakeThreshold) {
        final now = DateTime.now();

        if (now.difference(_lastShakeTime).inMilliseconds > 500) {
          _shakeCount++;
          _lastShakeTime = now;

          if (_shakeCount >= minShakeCount) {
            _shakeCount = 0;
            onShake();
          }
        }
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
  }
}
