
import 'package:fun_edu/feature/game_feature/game/sweep/game/data/models/score_info_model.dart';


class GameRepository {
  GameRepository();

  Future<String> getNickname() async {
    // final userId = _auth.currentUser?.uid;
    // if (userId != null) {
    //   final doc = await _firestore.collection('highScores').doc(userId).get();
    //   if (doc.exists) {
    //     return doc.data()!['nickname'];
    //   }
    // }
    return '';
  }

  Future<void> saveHighScore(int score, String nickname) async {
    // final userId = _auth.currentUser?.uid;
    // if (userId != null) {
    //   await _firestore.collection('highScores').doc(userId).set({
    //     'score': score,
    //     'nickname': nickname,
    //   });
    // }
  }

  Future<void> saveNickname(String nickname) async {
    // final userId = _auth.currentUser?.uid;
    // if (userId != null) {
    //   await _firestore
    //       .collection('highScores')
    //       .doc(userId)
    //       .set({'nickname': nickname});
    // }
  }

  Future<ScoreInfo?> getHighScore() async {
    return ScoreInfo();
  }

  Future<List<ScoreInfo>> getTopHighScores() async {
    return [];
  }
}
