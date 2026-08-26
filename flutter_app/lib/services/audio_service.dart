import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Centralised audio controller for WE Snap.
///
/// Uses separate players for:
/// - looping background music
/// - button/UI click sounds
/// - result/error feedback sounds
///
/// The feedback player is race-safe: if success and error are requested
/// very close together, only the newest feedback request is allowed to play.
class AppAudioService {
  AppAudioService._();

  static final AppAudioService instance = AppAudioService._();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _clickPlayer = AudioPlayer();
  final AudioPlayer _feedbackPlayer = AudioPlayer();

  bool _bgmEnabled = true;
  bool _sfxEnabled = true;
  bool _bgmStarted = false;

  int _feedbackRequestId = 0;

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
  // RESULT / ERROR FEEDBACK
  // ============================================================

  Future<void> playSuccess() async {
    await _playFeedback(
      'audio/success.mp3',
      label: 'Success',
    );
  }

  Future<void> playError() async {
    await _playFeedback(
      'audio/error.mp3',
      label: 'Error',
    );
  }

  Future<void> _playFeedback(
    String assetPath, {
    required String label,
  }) async {
    if (!_sfxEnabled) return;

    // Every new request invalidates any older feedback request that
    // might still be waiting on an async audio operation.
    final requestId = ++_feedbackRequestId;

    try {
      await _feedbackPlayer.stop();

      if (requestId != _feedbackRequestId) {
        return;
      }

      await _feedbackPlayer.setVolume(
        0.65,
      );

      if (requestId != _feedbackRequestId) {
        return;
      }

      await _feedbackPlayer.play(
        AssetSource(
          assetPath,
        ),
      );
    } catch (error) {
      debugPrint(
        '$label SFX failed: $error',
      );
    }
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  Future<void> dispose() async {
    await _bgmPlayer.dispose();
    await _clickPlayer.dispose();
    await _feedbackPlayer.dispose();
  }
}
