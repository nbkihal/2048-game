import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over `shared_preferences` (CLAUDE.md §9).
///
/// Only committed values land here — never mid-move animation state — so a
/// force-close always resumes on a consistent snapshot.
class Persistence {
  Persistence(this._prefs);

  static const _keyHighScore = 'highScoreGlobal';
  static const _keyBestScorePrefix = 'bestScore_stage_';
  static const _keyClearedStages = 'clearedStages';
  static const _keySoundOn = 'soundOn';
  static const _keyHapticsOn = 'hapticsOn';
  static const _keySkinId = 'themeId';
  static const _keyIntroSeen = 'introSeen';
  static const _keyMedalsPrefix = 'medals_stage_';
  static const _keySavedRun = 'savedRun';
  static const _keyDailySeed = 'dailySeed';
  static const _keyDailyBest = 'dailyBest';

  final SharedPreferences _prefs;

  static Future<Persistence> open() async =>
      Persistence(await SharedPreferences.getInstance());

  // --- progress ------------------------------------------------------------

  int get highScore => _prefs.getInt(_keyHighScore) ?? 0;

  Future<void> setHighScore(int value) => _prefs.setInt(_keyHighScore, value);

  int bestScoreForStage(int stageId) =>
      _prefs.getInt('$_keyBestScorePrefix$stageId') ?? 0;

  Future<void> setBestScoreForStage(int stageId, int value) =>
      _prefs.setInt('$_keyBestScorePrefix$stageId', value);

  /// Ids of every stage the player has cleared at least once.
  Set<int> get clearedStages =>
      (_prefs.getStringList(_keyClearedStages) ?? const [])
          .map(int.tryParse)
          .whereType<int>()
          .toSet();

  Future<void> setClearedStages(Set<int> ids) => _prefs.setStringList(
    _keyClearedStages,
    ids.map((id) => id.toString()).toList(),
  );

  // --- settings ------------------------------------------------------------

  bool get soundOn => _prefs.getBool(_keySoundOn) ?? true;

  Future<void> setSoundOn(bool value) => _prefs.setBool(_keySoundOn, value);

  bool get hapticsOn => _prefs.getBool(_keyHapticsOn) ?? true;

  Future<void> setHapticsOn(bool value) => _prefs.setBool(_keyHapticsOn, value);

  String? get skinId => _prefs.getString(_keySkinId);

  Future<void> setSkinId(String value) => _prefs.setString(_keySkinId, value);

  /// Whether the player has been through the how-to-play intro once. Survives a
  /// progress reset: it records that the rules were shown, not what was played.
  bool get introSeen => _prefs.getBool(_keyIntroSeen) ?? false;

  Future<void> setIntroSeen(bool value) => _prefs.setBool(_keyIntroSeen, value);

  // --- medals --------------------------------------------------------------

  /// Medals earned on a stage, packed as a bitmask. Medals accumulate: a later
  /// sloppy clear never takes one back.
  int medalsForStage(int stageId) =>
      _prefs.getInt('$_keyMedalsPrefix$stageId') ?? 0;

  Future<void> setMedalsForStage(int stageId, int bits) =>
      _prefs.setInt('$_keyMedalsPrefix$stageId', bits);

  // --- the run in progress -------------------------------------------------

  /// The last committed board, as JSON, or `null` when no run is open.
  ///
  /// Only committed snapshots land here — never mid-animation state — so a
  /// force-close always resumes on a board the player actually saw.
  String? get savedRun => _prefs.getString(_keySavedRun);

  Future<void> setSavedRun(String json) =>
      _prefs.setString(_keySavedRun, json);

  Future<void> clearSavedRun() => _prefs.remove(_keySavedRun);

  // --- daily challenge -----------------------------------------------------

  /// Best score on the daily board identified by [seed]. A new day reports 0
  /// rather than carrying yesterday's number forward.
  int dailyBestFor(int seed) =>
      _prefs.getInt(_keyDailySeed) == seed
      ? (_prefs.getInt(_keyDailyBest) ?? 0)
      : 0;

  Future<void> setDailyBest(int seed, int score) async {
    await _prefs.setInt(_keyDailySeed, seed);
    await _prefs.setInt(_keyDailyBest, score);
  }

  // --- reset ---------------------------------------------------------------

  /// Clears progress and settings. Used by the Settings screen.
  Future<void> resetAll() async {
    final keys = _prefs.getKeys().where(
      (k) =>
          k == _keyHighScore ||
          k == _keyClearedStages ||
          k == _keySoundOn ||
          k == _keyHapticsOn ||
          k == _keySkinId ||
          k == _keySavedRun ||
          k == _keyDailySeed ||
          k == _keyDailyBest ||
          k.startsWith(_keyBestScorePrefix) ||
          k.startsWith(_keyMedalsPrefix),
    );
    for (final key in keys.toList()) {
      await _prefs.remove(key);
    }
  }
}
