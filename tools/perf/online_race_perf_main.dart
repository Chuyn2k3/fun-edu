// Device frame-timing run for the online race scene (spec
// docs/superpowers/specs/2026-11-23-dua-ban-be-design.md §9.1). No server,
// no extra package: 4 racers move like a real race (a snapshot every 200 ms),
// stickers fly every 0.8 s, then the run prints build/raster times.
//
//   flutter run --profile -t tools/perf/online_race_perf_main.dart
//
// Read the console (and the screen) after ~25 s. Target: avg >= 58 fps,
// no frame over 32 ms, build and raster <= 8 ms per frame. See docs/perf.md.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:funedu/game/scene/race_scene.dart';
import 'package:funedu/profile/avatars.dart';

const _warmUp = Duration(seconds: 3);
const _measure = Duration(seconds: 20);
const _rockets = ['rocket_orange', 'rocket_blue', 'rocket_green', 'rocket_purple'];
const _names = ['Con', 'Bin', 'Mi', 'Tôm'];
const _stickers = ['bubble', 'tongue', 'rain', 'sleepy', 'turtle', 'smoke', 'byebye', 'cheer'];

void main() => runApp(const MaterialApp(home: _PerfRun()));

class _PerfRun extends StatefulWidget {
  const _PerfRun();

  @override
  State<_PerfRun> createState() => _PerfRunState();
}

class _PerfRunState extends State<_PerfRun> {
  final _scene = GlobalKey<RaceSceneState>();
  final _rng = math.Random(7);
  final _steps = [0, 0, 0, 0];
  final _build = <int>[];
  final _raster = <int>[];
  Timer? _snapshots;
  Timer? _stickerTimer;
  bool _measuring = false;
  String _report = 'Đang khởi động…';
  int _stickerSeq = 0;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    // Snapshots as often as the server sends them while everyone races.
    _snapshots = Timer.periodic(const Duration(milliseconds: 200), (_) {
      setState(() {
        for (var i = 0; i < 4; i++) {
          if (_rng.nextDouble() < 0.18) _steps[i] = (_steps[i] + 1) % 19;
        }
      });
    });
    _stickerTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      final from = _rng.nextInt(4);
      final to = (from + 1 + _rng.nextInt(3)) % 4;
      _scene.currentState?.playSticker(IncomingStickerEvent(
        seq: ++_stickerSeq,
        fromId: 'p$from',
        toId: 'p$to',
        stickerId: _stickers[_stickerSeq % _stickers.length],
      ));
    });
    Future<void>.delayed(_warmUp, () {
      _measuring = true;
      if (mounted) setState(() => _report = 'Đang đo 20 giây…');
      Future<void>.delayed(_measure, _finish);
    });
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!_measuring) return;
    for (final t in timings) {
      _build.add(t.buildDuration.inMicroseconds);
      _raster.add(t.rasterDuration.inMicroseconds);
    }
  }

  String _stats(String name, List<int> us) {
    if (us.isEmpty) return '$name: không có khung nào';
    final s = [...us]..sort();
    double p(double q) => s[((s.length - 1) * q).round()] / 1000;
    final avg = s.reduce((a, b) => a + b) / s.length / 1000;
    return '$name: avg ${avg.toStringAsFixed(2)} ms · p90 ${p(.9).toStringAsFixed(2)}'
        ' · p99 ${p(.99).toStringAsFixed(2)} · max ${p(1).toStringAsFixed(2)}';
  }

  void _finish() {
    _measuring = false;
    _snapshots?.cancel();
    _stickerTimer?.cancel();
    final frames = _build.length;
    var slow = 0, jank = 0;
    for (var i = 0; i < frames; i++) {
      final total = math.max(_build[i], _raster[i]);
      if (total > 16667) slow++;
      if (total > 32000) jank++;
    }
    final fps = frames / _measure.inSeconds;
    final report = [
      'Màn đua online · 4 tên lửa · sticker mỗi 0,8 s · ${_measure.inSeconds} s',
      'Khung: $frames (~${fps.toStringAsFixed(1)} fps)',
      _stats('Build (UI)', _build),
      _stats('Raster (GPU)', _raster),
      'Khung > 16,7 ms: $slow · khung > 32 ms: $jank',
      'Đạt khi: fps ≥ 58, không khung > 32 ms, build và raster avg ≤ 8 ms',
    ].join('\n');
    // ignore: avoid_print
    print('\n===== PERF ONLINE RACE =====\n$report\n============================');
    if (mounted) setState(() => _report = report);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _snapshots?.cancel();
    _stickerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final racers = [
      for (var i = 0; i < 4; i++)
        OnlineRacer(
          id: 'p$i',
          name: _names[i],
          avatar: kidAvatars[i],
          rocket: _rockets[i],
          steps: _steps[i],
          me: i == 0,
        ),
    ];
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: RaceScene(
              key: _scene,
              kidSteps: _steps[0],
              chipSteps: _steps[1],
              kidRocket: _rockets[0],
              kidTrail: 'trail_flame',
              boosting: false,
              won: false,
              onlineRacers: racers,
              raceSteps: 18,
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Text(_report, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
