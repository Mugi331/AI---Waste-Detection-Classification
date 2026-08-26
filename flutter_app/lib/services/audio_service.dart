import 'package:audioplayers/audioplayers.dart';

/// Centralised audio controller for WE Snap.
///
/// BGM and sound effects use separate players so short UI sounds can play
/// without interrupting the background music.
///
/// Audio errors are intentionally caught here. A missing/unsupported audio
/// asset should never block navigation, image picking, or AI analysis.
class AppAudioService {
  AppAudioService._();

  static final AppAudioService instance = AppAudioService._();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _bgmEnabled = true;
  bool _sfxEnabled = true;
  bool _bgmStarted = false;

  bool get bgmEnabled => _bgmEnabled;
  bool get sfxEnabled => _sfxEnabled;

  Future<void> startBgm() async {
    if (!_bgmEnabled || _bgmStarted) return;

    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.18);
      await _bgmPlayer.play(
        AssetSource('audio/bgm.mp3'),
      );

      _bgmStarted = true;
    } catch (error) {
      _bgmStarted = false;
      // Audio must never break the app's core workflow.
      // ignore: avoid_print
      print('BGM playback failed: $error');
    }
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (error) {
      // ignore: avoid_print
      print('BGM stop failed: $error');
    } finally {
      _bgmStarted = false;
    }
  }

  Future<void> toggleBgm() async {
    _bgmEnabled = !_bgmEnabled;

    if (_bgmEnabled) {
      await startBgm();
    } else {
      await stopBgm();
    }
  }

  void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
  }

  Future<void> playClick() async {
    await _playSfx('audio/click.mp3');
  }

  Future<void> playSuccess() async {
    await _playSfx('audio/success.mp3');
  }

  Future<void> playError() async {
    await _playSfx('audio/error.mp3');
  }

  Future<void> _playSfx(String assetPath) async {
    if (!_sfxEnabled) return;

    try {
      // Stop the previous short effect so repeated taps stay crisp instead
      // of stacking several copies of the same sound.
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(0.55);
      await _sfxPlayer.play(
        AssetSource(assetPath),
      );
    } catch (error) {
      // ignore: avoid_print
      print('SFX playback failed ($assetPath): $error');
    }
  }

  Future<void> dispose() async {
    await _bgmPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
