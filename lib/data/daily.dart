import '../models/stage.dart';

/// The daily challenge.
///
/// One board a day, the same for every player and every device: the date is the
/// seed, and `GameNotifier` already takes its random source by injection, so
/// feeding it a seeded generator is all it takes to make the opening tiles and
/// the spawn stream reproducible. Nothing is fetched — the date *is* the
/// shared secret.
const int kDailyStageId = 201;

const Stage kDailyStage = Stage(
  id: kDailyStageId,
  name: 'Daily Challenge',
  subtitle: 'ONE BOARD A DAY, SAME FOR EVERYONE',
  gridSize: 4,
  targetTile: null,
  unlockedByDefault: true,
);

/// The seed for [day], as `yyyymmdd`. Local midnight is the rollover, which is
/// what a player expects from "today".
int dailySeed(DateTime day) => day.year * 10000 + day.month * 100 + day.day;

int todaysSeed() => dailySeed(DateTime.now());

/// `2026-09-01`, for labelling which board a score belongs to.
String dailyLabel(DateTime day) {
  final month = day.month.toString().padLeft(2, '0');
  final dayOfMonth = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$dayOfMonth';
}
