import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The sound effects the game can play. The value is the asset file name.
enum Sfx {
  slide('slide.wav'),
  merge('merge.wav'),
  spawn('spawn.wav'),
  tap('tap.wav'),
  unlock('unlock.wav'),
  win('win.wav'),
  lose('lose.wav');

  const Sfx(this.asset);

  final String asset;
}

/// Plays the short effects generated into `assets/audio/`.
///
/// A move can fire a slide and several merges in the same frame, so a single
/// player would cut itself off. A small round-robin pool keeps the overlaps
/// audible without ever allocating during play.
class AudioController {
  AudioController({int poolSize = 4})
    : _players = List.generate(
        poolSize,
        (_) => AudioPlayer()..setReleaseMode(ReleaseMode.stop),
      );

  /// A controller that owns no players at all. Widget tests run without the
  /// audio plugin, and a game must never depend on sound to make progress.
  AudioController.silent() : _players = const [];

  final List<AudioPlayer> _players;
  var _cursor = 0;

  bool soundEnabled = true;
  bool hapticsEnabled = true;

  /// Merges are the loudest event and can fire several at once; trim them so a
  /// four-way merge does not clip.
  static const _volumes = {
    Sfx.slide: 0.45,
    Sfx.merge: 0.55,
    Sfx.spawn: 0.35,
    Sfx.tap: 0.5,
    Sfx.unlock: 0.7,
    Sfx.win: 0.8,
    Sfx.lose: 0.7,
  };

  Future<void> play(Sfx sfx) async {
    if (!soundEnabled || _players.isEmpty) return;
    final player = _players[_cursor];
    _cursor = (_cursor + 1) % _players.length;
    try {
      await player.stop();
      await player.setVolume(_volumes[sfx] ?? 0.6);
      await player.play(
        AssetSource('audio/${sfx.asset}'),
        mode: PlayerMode.lowLatency,
      );
    } catch (error) {
      // Audio is pure garnish: a device with no audio route, a codec refusal or
      // a headless test environment must never take the game down with it.
      debugPrint('AudioController: could not play ${sfx.asset} ($error)');
    }
  }

  /// One merge sound regardless of how many merged this move, plus the slide
  /// underneath it — playing seven overlapping blips just sounds like noise.
  Future<void> playMove({required bool merged}) async {
    await play(Sfx.slide);
    if (merged) await play(Sfx.merge);
  }

  void haptic(HapticStrength strength) {
    if (!hapticsEnabled) return;
    switch (strength) {
      case HapticStrength.light:
        HapticFeedback.selectionClick();
      case HapticStrength.medium:
        HapticFeedback.lightImpact();
      case HapticStrength.heavy:
        HapticFeedback.mediumImpact();
    }
  }

  void dispose() {
    for (final player in _players) {
      player.dispose();
    }
  }
}

enum HapticStrength { light, medium, heavy }
