import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

/// Short original unlock chime. Played once when an achievement first opens.
class AchievementSound {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> play() async {
    if (_inTest) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/achievement.wav'));
    } catch (_) {}
  }

  static bool get _inTest {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return true;
    }
  }
}
