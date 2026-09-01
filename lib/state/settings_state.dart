import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio_controller.dart';
import '../data/persistence.dart';
import '../data/skins_data.dart';

/// User preferences (CLAUDE.md §9: `soundOn`, `themeId`, `hapticsOn`).
class Settings {
  const Settings({
    required this.soundOn,
    required this.hapticsOn,
    required this.skinId,
  });

  final bool soundOn;
  final bool hapticsOn;
  final String skinId;

  Settings copyWith({bool? soundOn, bool? hapticsOn, String? skinId}) =>
      Settings(
        soundOn: soundOn ?? this.soundOn,
        hapticsOn: hapticsOn ?? this.hapticsOn,
        skinId: skinId ?? this.skinId,
      );
}

class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier(this._store, this._audio)
      : super(
          Settings(
            soundOn: _store.soundOn,
            hapticsOn: _store.hapticsOn,
            skinId: _store.skinId ?? kDefaultSkinId,
          ),
        ) {
    _syncAudio();
  }

  final Persistence _store;
  final AudioController _audio;

  void toggleSound() {
    state = state.copyWith(soundOn: !state.soundOn);
    _store.setSoundOn(state.soundOn);
    _syncAudio();
    // Confirm the new setting audibly — silence would be ambiguous.
    if (state.soundOn) _audio.play(Sfx.tap);
  }

  void toggleHaptics() {
    state = state.copyWith(hapticsOn: !state.hapticsOn);
    _store.setHapticsOn(state.hapticsOn);
    _syncAudio();
    if (state.hapticsOn) _audio.haptic(HapticStrength.medium);
  }

  void selectSkin(String skinId) {
    if (state.skinId == skinId) return;
    state = state.copyWith(skinId: skinId);
    _store.setSkinId(skinId);
    _audio.play(Sfx.tap);
  }

  /// Re-reads persisted values after a progress reset.
  void reload() {
    state = Settings(
      soundOn: _store.soundOn,
      hapticsOn: _store.hapticsOn,
      skinId: _store.skinId ?? kDefaultSkinId,
    );
    _syncAudio();
  }

  void _syncAudio() {
    _audio.soundEnabled = state.soundOn;
    _audio.hapticsEnabled = state.hapticsOn;
  }
}
