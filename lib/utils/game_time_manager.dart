import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:get_it/get_it.dart';

class GameTimeManager {
  static const _dailyLimitMinutes = 5;

  final String gameId;
  final prefs = GetIt.instance<SharedPreferencesManager>();

  GameTimeManager(this.gameId);

  String get _keyLastPlayedDate => 'last_played_date_$gameId';
  String get _keyPlayedSeconds => 'played_seconds_today_$gameId';
  String get _keyStartPlayMillis => 'start_play_millis_$gameId';

  Future<void> startPlay() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.putInt(_keyStartPlayMillis, now);
  }

  Future<void> endPlay() async {
    final startMillis = prefs.getInt(_keyStartPlayMillis);
    if (startMillis == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final duration = Duration(milliseconds: now - startMillis);
    await addPlayTime(duration);
    await prefs.remove(_keyStartPlayMillis);
  }

  Future<void> resumeSessionIfAny() async {
    final startMillis = prefs.getInt(_keyStartPlayMillis);
    if (startMillis != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final duration = Duration(milliseconds: now - startMillis);
      await addPlayTime(duration);
      await prefs.remove(_keyStartPlayMillis);
    }
  }

  Future<void> addPlayTime(Duration duration) async {
    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";

    final lastPlayed = prefs.getString(_keyLastPlayedDate);
    if (lastPlayed != today) {
      await prefs.putString(_keyLastPlayedDate, today);
      await prefs.putInt(_keyPlayedSeconds, 0);
    }

    final currentSeconds = prefs.getInt(_keyPlayedSeconds) ?? 0;
    final newSeconds = currentSeconds + duration.inSeconds;
    await prefs.putInt(_keyPlayedSeconds, newSeconds);
  }

  Future<bool> canPlay() async {
    await resumeSessionIfAny();

    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";

    final lastPlayed = prefs.getString(_keyLastPlayedDate);
    final playedSeconds = prefs.getInt(_keyPlayedSeconds) ?? 0;

    if (lastPlayed != today) {
      await prefs.putString(_keyLastPlayedDate, today);
      await prefs.putInt(_keyPlayedSeconds, 0);
      return true;
    }

    return playedSeconds < _dailyLimitMinutes * 60;
  }

  Future<int> remainingSeconds() async {
    await resumeSessionIfAny();

    final now = DateTime.now();
    final today = "${now.year}-${now.month}-${now.day}";

    final lastPlayed = prefs.getString(_keyLastPlayedDate);
    final playedSeconds = prefs.getInt(_keyPlayedSeconds) ?? 0;

    if (lastPlayed != today) {
      await prefs.putString(_keyLastPlayedDate, today);
      await prefs.putInt(_keyPlayedSeconds, 0);
      return _dailyLimitMinutes * 60;
    }

    final remaining = _dailyLimitMinutes * 60 - playedSeconds;
    return remaining > 0 ? remaining : 0;
  }
}
