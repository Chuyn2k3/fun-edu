import 'package:funedu/voice/speaker.dart';

/// Records what would have been spoken.
class FakeSpeaker implements Speaker {
  final spoken = <String>[];
  int stops = 0;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stops++;
}
