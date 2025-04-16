import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fun_edu/utils/game_time_manager.dart';

class GameCountdownTimer extends StatefulWidget {
  final GameTimeManager timeManager;
  final VoidCallback onTimeUp;

  const GameCountdownTimer({
    super.key,
    required this.timeManager,
    required this.onTimeUp,
  });

  @override
  State<GameCountdownTimer> createState() => _GameCountdownTimerState();
}

class _GameCountdownTimerState extends State<GameCountdownTimer> {
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initCountdown();
  }

  Future<void> _initCountdown() async {
    _remainingSeconds = await widget.timeManager.remainingSeconds();

    if (!mounted) return;

    if (_remainingSeconds <= 0) {
      widget.onTimeUp();
    } else {
      setState(() {}); // update lần đầu
      _startTimer(); // bắt đầu đếm ngược
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await widget.timeManager.addPlayTime(const Duration(seconds: 1));
      final seconds = await widget.timeManager.remainingSeconds();

      if (!mounted) return;

      if (seconds <= 0) {
        _timer?.cancel();
        await widget.timeManager.endPlay();
        widget.onTimeUp();
      } else {
        setState(() {
          _remainingSeconds = seconds;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
        horizontal: 4,
      ),
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.2), // Màu nền nhẹ nhàng
        borderRadius: BorderRadius.circular(8), // Bo góc
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer, // Biểu tượng đồng hồ
            color: Colors.blueAccent,
            size: 22,
          ),
          const SizedBox(width: 4), // Khoảng cách giữa icon và text
          Text(
            '${_formatTime(_remainingSeconds)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
}
