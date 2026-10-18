import 'package:flutter_tts/flutter_tts.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';

class TtsScriptBuilder {
  TtsScriptBuilder._();

  static String buildCustomerOrderSpeech(String childName, int quantity, ItemType itemType) {
    return 'Chào bé $childName! Lấy giúp bác $quantity quả ${itemType.vietnameseName} nhé!';
  }

  static String buildCountingSpeech(int count) {
    switch (count) {
      case 1:
        return 'Một!';
      case 2:
        return 'Hai!';
      case 3:
        return 'Ba!';
      case 4:
        return 'Bốn!';
      case 5:
        return 'Năm!';
      default:
        return '$count!';
    }
  }

  static String buildWrongItemSpeech(ItemType neededType) {
    return 'Ồ, bác cần ${neededType.vietnameseName} kìa!';
  }

  static String buildOrderCompleteSpeech() {
    return 'Giỏi lắm! Cảm ơn bé nhé!';
  }

  static String buildLevelCompleteSpeech() {
    return 'Tuyệt vời! Bé đã hoàn thành xuất sắc!';
  }
}

class TtsService {
  final FlutterTts _tts;
  bool _isInitialized = false;

  TtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage('vi-VN');
      await _tts.setSpeechRate(0.45); // Slow for young children
      await _tts.setPitch(1.2);       // Friendly high tone
      await _tts.awaitSpeakCompletion(true);
      _isInitialized = true;
    } catch (_) {
      // Fallback handled in UI
    }
  }

  Future<void> speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
