import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fun_edu/core/repositories/question_repository.dart';
import 'package:fun_edu/di/locator.dart';
import 'package:fun_edu/model/question_model.dart';
import 'package:fun_edu/providers/questions.dart';

final offlineProvider = ChangeNotifierProvider<Offline>((ref) {
  return Offline();
});

class Offline extends ChangeNotifier {
  final QuestionRepository _questionRepository = serviceLocator();

  int currentQuestionIndex = 0;
  int? currentQuestionAnswerIndex;
  bool? isUserAnswering;
  bool isFinish = false;
  String userName = "Người chơi thứ nhất";
  String enermyName = "Người chơi thứ hai";
  List<QuestionModel> _questions = [];
  OfflineState state = OfflineState.initial;
  String? errorMessage;

  int userScore = 0;
  int enemyScore = 0;

  List<QuestionModel> get questions => _questions;

  QuestionModel? get currentQuestion =>
      _questions.isNotEmpty ? _questions[currentQuestionIndex] : null;

  List<String> get currentAnswers =>
      currentQuestion?.answers?.map((e) => e.content ?? "").toList() ?? [];

  int get isRightIndex {
    final list = currentQuestion?.answers;
    if (list == null || list.isEmpty) return -1;
    return list.indexWhere((e) => e.isCorrect ?? false);
  }

  bool get isWinner => userScore > enemyScore;

  bool get isChoseAnswer => answersStatus.contains(AnswerCardStatus.right);

  List<AnswerCardStatus> get answersStatus {
    final answers = currentQuestion?.answers;
    if (answers == null) return [];

    return List.generate(answers.length, (index) {
      if (currentQuestionAnswerIndex == null && isUserAnswering != null) {
        return AnswerCardStatus.normal;
      } else if (currentQuestionAnswerIndex == null &&
          isUserAnswering == null) {
        return AnswerCardStatus.disabled;
      } else if (currentQuestionAnswerIndex == isRightIndex) {
        return index == currentQuestionAnswerIndex
            ? AnswerCardStatus.right
            : AnswerCardStatus.disabled;
      } else {
        if (index == currentQuestionAnswerIndex) {
          return AnswerCardStatus.error;
        }
        if (index == isRightIndex) {
          return AnswerCardStatus.right;
        }
        return AnswerCardStatus.disabled;
      }
    });
  }

  Future<void> loadQuestions() async {
    state = OfflineState.loading;
    notifyListeners();

    try {
      final result = await _questionRepository.getQuestion(null, null);
      _questions = result.data?.content ?? [];

      if (_questions.isEmpty) {
        state = OfflineState.empty;
      } else {
        state = OfflineState.loaded;
      }
    } catch (e) {
      errorMessage = e.toString();
      state = OfflineState.error;
    }

    notifyListeners();
  }

  void chooseAnswerer(bool isUser) {
    isUserAnswering = isUser;
    notifyListeners();
  }

  bool isRightAnswer(int index) {
    return isRightIndex == index;
  }

  void answerQuestion(int index) {
    if (currentQuestion == null) return;

    currentQuestionAnswerIndex = index;

    if ((isUserAnswering! && isRightAnswer(index)) ||
        (!isUserAnswering! && !isRightAnswer(index))) {
      userScore++;
    } else {
      enemyScore++;
    }

    notifyListeners();
  }

  void nextQuestion() {
    if (currentQuestionIndex < _questions.length - 1) {
      isUserAnswering = null;
      currentQuestionIndex++;
      currentQuestionAnswerIndex = null;
    } else {
      isFinish = true;
    }
    notifyListeners();
  }

  void reset() {
    currentQuestionAnswerIndex = null;
    isUserAnswering = null;
    isFinish = false;
    currentQuestionIndex = 0;
    userScore = 0;
    enemyScore = 0;
    notifyListeners();
  }
}

enum OfflineState { initial, loading, loaded, empty, error }
