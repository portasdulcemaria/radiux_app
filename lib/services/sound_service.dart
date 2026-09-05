import 'package:audioplayers/audioplayers.dart';

/// Feedback auditivo sutil para interacciones clave.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  Future<void> _play(String name) async {
    try {
      final p = AudioPlayer();
      await p.setVolume(0.45);
      await p.play(AssetSource('sounds/$name.wav'));
    } catch (_) {}
  }

  void tick()    => _play('tick');
  void select()  => _play('select');
  void swap()    => _play('swap');
  void copy()    => _play('copy');
  void success() => _play('success');
  void error()   => _play('error');
}
