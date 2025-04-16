import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/feature/game_feature/game/multi_player_quiz/offline_multiplayer_result_screen.dart';
import 'package:fun_edu/providers/offline.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/custom_app_bar.dart';
import 'package:fun_edu/utils/game_time_manager.dart';
import 'package:fun_edu/widget/answer_card.dart';
import 'package:fun_edu/widget/custom_button.dart';
import 'package:fun_edu/widget/game_count_down_time.dart';

class OfflineMultiplayerScreen extends ConsumerStatefulWidget {
  const OfflineMultiplayerScreen(this.user1Name, this.user2Name, {Key? key})
      : super(key: key);

  final String user1Name;
  final String user2Name;

  @override
  _OfflineMultiplayerScreenState createState() =>
      _OfflineMultiplayerScreenState();
}

class _OfflineMultiplayerScreenState
    extends ConsumerState<OfflineMultiplayerScreen> {
  late GameTimeManager _timeManager;


  @override
  void initState() {
    super.initState();
    _timeManager = GameTimeManager("soloQuiz");
    _initGameTime();
  }

  Future<void> _initGameTime() async {
    final canPlay = await _timeManager.canPlay();
    if (!canPlay) {
      _showTimeUpDialog();
      return;
    }

    await _timeManager.startPlay();
    setState(() {}); // để render GameCountdownTimer
  }


  void _showTimeUpDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.access_time_filled,
                color: Colors.redAccent,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                "Hết giờ chơi!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Bé đã sử dụng hết 15 phút chơi hôm nay.\nHẹn gặp lại bé vào ngày mai nhé!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // đóng dialog
                    Navigator.of(context).pop(); // thoát màn game
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Xác nhận",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {

    _timeManager.endPlay(); // Lưu thời gian đã chơi
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offline = ref.watch(offlineProvider);
    offline.userName =
        widget.user1Name.isNotEmpty ? widget.user1Name : offline.userName;
    offline.enermyName =
        widget.user2Name.isNotEmpty ? widget.user2Name : offline.enermyName;
    debugPrint('Current state: ${offline.state}');
    if (offline.state == OfflineState.initial) {
      offline.loadQuestions();
    } // In trạng thái hiện tại
    ref.listen<Offline>(offlineProvider, (previous, next) {
      // if (previous == null ) {
      // Gọi khi lần đầu vào màn hình
      //debugPrint('Current state:hehehehehehe');
      //offline.loadQuestions();
      //}
      if (next.isFinish) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const OfflineMultiplayerResultScreen(),
            ));
      }
    });
    return SafeArea(
      child: BaseScaffold(
        appBar: CustomAppbar.basic(
          onTap: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          title: "Đố vui đọ não",
          actions: [
            GameCountdownTimer(
              timeManager: _timeManager,
              onTimeUp: _showTimeUpDialog,
            ),
          ],
        ),
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SvgPicture.asset(
              'assets/images/circles.svg',
              fit: BoxFit.fitHeight,
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildUserCard(
                        widget.user1Name,
                        "assets/images/warrior.png",
                        offline.userScore,
                        const Color(0xff189AFE),
                      ),
                      const SizedBox(width: 20),
                      // const Text(
                      //   'VS',
                      //   style: TextStyle(
                      //       fontSize: 30, fontWeight: FontWeight.bold),
                      // ),
                      Image.asset(
                        "assets/images/vs.png",
                        height: 96,
                        width: 96,
                      ),
                      const SizedBox(width: 20),
                      _buildUserCard(
                        widget.user2Name,
                        "assets/images/warrior_1.png",
                        offline.enemyScore,
                        const Color(0xff16968B),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (offline.state == OfflineState.loading)
                  Expanded(
                      child: const Center(child: CircularProgressIndicator()))
                else if (offline.state == OfflineState.error)
                  _buildErrorData(offline.errorMessage)
                else if (offline.questions.isEmpty)
                  _buildEmptyData()
                else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    width: double.infinity,
                    child: Text(
                      'Câu hỏi ${offline.currentQuestionIndex + 1}/10',
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                      ),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          Column(
                            children: [
                              Text(
                                offline.currentQuestion?.title ?? "",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                                textAlign: TextAlign.start,
                              ),
                              offline.currentQuestion?.content != null
                                  ? Center(
                                      child: Text(
                                        offline.currentQuestion?.content ?? "",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 26,
                                        ),
                                      ),
                                    )
                                  : Image.network(
                                      offline.currentQuestion?.imageUrl ?? "",
                                      width: 120,
                                      height: 80,
                                    ),
                            ],
                          ),
                          for (int i = 0;
                              i < offline.currentAnswers.length;
                              i++)
                            AnswerCard(
                              answer: offline.currentAnswers[i],
                              answerCardStatus: offline.answersStatus[i],
                              onTap: offline.isUserAnswering == null ||
                                      offline.isChoseAnswer
                                  ? null
                                  : () {
                                      offline.answerQuestion(i);
                                    },
                            ),
                          if (offline.isChoseAnswer) ...[
                            const SizedBox(height: 20),
                            CustomButton(
                              padding: 0,
                              onPressed: offline.nextQuestion,
                              text: 'Câu tiếp theo',
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                HandButton(
                                  color: Color(0xff189AFE),
                                  isUser: true,
                                ),
                                HandButton(
                                  color: Color(0xff16968B),
                                  isUser: false,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Expanded _buildUserCard(
      String userName, String image, int score, Color colorScore) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              child: Column(
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Image.asset(
                    image,
                    fit: BoxFit.fill,
                    width: 64,
                    height: 64,
                  )
                ],
              ),
            ),
            const Divider(
              thickness: 2,
              color: Colors.black54,
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                score.toString(),
                style: TextStyle(
                    color: colorScore,
                    fontSize: 22,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorData(String? error) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(
                'Lỗi ${error ?? "không xác định"}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Image.asset(
              "assets/images/system.png",
              height: 150,
              width: 180,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyData() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Center(
              child: Text(
                'Không có câu hỏi nào',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Image.asset(
              "assets/images/kitten.png",
              height: 150,
              width: 180,
            ),
          ],
        ),
      ),
    );
  }
}

class HandButton extends ConsumerWidget {
  const HandButton({
    required this.color,
    required this.isUser,
    Key? key,
  }) : super(key: key);

  final Color color;
  final bool isUser;

  @override
  Widget build(BuildContext context, ref) {
    final offline = ref.watch(offlineProvider);
    return InkWell(
      onTap: offline.isUserAnswering != null
          ? null
          : () {
              offline.chooseAnswerer(isUser);
            },
      child: CircleAvatar(
        backgroundColor: color.withOpacity((offline.isUserAnswering != null &&
                offline.isUserAnswering != isUser)
            ? .4
            : 1),
        radius: 50,
        child: SvgPicture.asset('assets/images/hand.svg'),
      ),
    );
  }
}
