import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/core/services/tts_service.dart';
import 'package:fun_edu/features/shop_game/domain/entities/item_entity.dart';

void main() {
  group('TtsScriptBuilder Tests', () {
    test('buildCustomerOrderSpeech formats correctly', () {
      final speech = TtsScriptBuilder.buildCustomerOrderSpeech('Bé Na', 3, ItemType.redApple);
      expect(speech, 'Chào bé Bé Na! Lấy giúp bác 3 quả Táo đỏ nhé!');
    });

    test('buildCountingSpeech returns Vietnamese numeral words', () {
      expect(TtsScriptBuilder.buildCountingSpeech(1), 'Một!');
      expect(TtsScriptBuilder.buildCountingSpeech(2), 'Hai!');
      expect(TtsScriptBuilder.buildCountingSpeech(3), 'Ba!');
      expect(TtsScriptBuilder.buildCountingSpeech(4), 'Bốn!');
      expect(TtsScriptBuilder.buildCountingSpeech(5), 'Năm!');
    });

    test('buildWrongItemSpeech formats correctly', () {
      final speech = TtsScriptBuilder.buildWrongItemSpeech(ItemType.banana);
      expect(speech, 'Ồ, bác cần Chuối kìa!');
    });

    test('buildOrderCompleteSpeech returns friendly compliment', () {
      expect(TtsScriptBuilder.buildOrderCompleteSpeech(), 'Giỏi lắm! Cảm ơn bé nhé!');
    });

    test('buildLevelCompleteSpeech returns celebration phrase', () {
      expect(TtsScriptBuilder.buildLevelCompleteSpeech(), 'Tuyệt vời! Bé đã hoàn thành xuất sắc!');
    });
  });
}
