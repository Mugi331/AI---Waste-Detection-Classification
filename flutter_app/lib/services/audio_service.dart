import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Centralised audio controller for WE Snap.
///
/// Uses:
/// - one player for looping background music
/// - one player for button/UI click sounds
/// - one player for result/error feedback sounds
///
/// Keeping them separate prevents a click sound from interrupting
/// success/error feedback or background music.
class AppAudioService {
  AppAudioService._();

  static final AppAudioService instance = AppAudioService._();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _clickPlayer = AudioPlayer();
  final AudioPlayer _feedbackPlayer = AudioPlayer();

  bool _bgmEnabled = true;
  bool _sfxEnabled = true;
  bool _bgmStarted = false;

  bool get bgmEnabled => _bgmEnabled;
  bool get sfxEnabled => _sfxEnabled;

  // ============================================================
  // BACKGROUND MUSIC
  // ============================================================

  Future<void> startBgm() async {
    if (!_bgmEnabled || _bgmStarted) return;

    try {
      await _bgmPlayer.setReleaseMode(
        ReleaseMode.loop,
      );

      await _bgmPlayer.setVolume(
        0.18,
      );

      await _bgmPlayer.play(
        AssetSource(
          'audio/bgm.mp3',
        ),
      );

      _bgmStarted = true;
    } catch (error) {
      _bgmStarted = false;

      debugPrint(
        'BGM playback failed: $error',
      );
    }
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (error) {
      debugPrint(
        'BGM stop failed: $error',
      );
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

  // ============================================================
  // SOUND EFFECT SETTINGS
  // ============================================================

  void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
  }

  // ============================================================
  // CLICK SOUND
  // ============================================================

  Future<void> playClick() async {
    if (!_sfxEnabled) return;

    try {
      await _clickPlayer.stop();

      await _clickPlayer.setVolume(
        0.55,
      );

      await _clickPlayer.play(
        AssetSource(
          'audio/click.mp3',
        ),
      );
    } catch (error) {
      debugPrint(
        'Click SFX failed: $error',
      );
    }
  }

  // ============================================================
  // SUCCESS SOUND
  // ============================================================

  Future<void> playSuccess() async {
    if (!_sfxEnabled) return;

    try {
      await _feedbackPlayer.stop();

      await _feedbackPlayer.setVolume(
        0.65,
      );

      await _feedbackPlayer.play(
        AssetSource(
          'audio/success.mp3',
        ),
      );
    } catch (error) {
      debugPrint(
        'Success SFX failed: $error',
      );
    }
  }

  // ============================================================
  // ERROR / NO-DETECTION SOUND
  // ============================================================

  Future<void> playError() async {
    if (!_sfxEnabled) return;

    try {
      await _feedbackPlayer.stop();

      await _feedbackPlayer.setVolume(
        0.65,
      );

      await _feedbackPlayer.play(
        AssetSource(
          'audio/error.mp3',
        ),
      );
    } catch (error) {
      debugPrint(
        'Error SFX failed: $error',
      );
    }
  }


  Future<void> dispose() async {
    await _bgmPlayer.dispose();
    await _clickPlayer.dispose();
    await _feedbackPlayer.dispose();
  }
}