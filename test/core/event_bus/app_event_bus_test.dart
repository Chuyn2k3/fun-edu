import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/core/event_bus/app_event_bus.dart';
import 'package:fun_edu/core/event_bus/app_events.dart';

void main() {
  late AppEventBus eventBus;

  setUp(() {
    eventBus = AppEventBus();
  });

  tearDown(() {
    eventBus.dispose();
  });

  test('fire and listen specific event works properly', () async {
    final receivedEvents = <AppEvent>[];
    final sub = eventBus.on<CoinEarnedEvent>().listen(receivedEvents.add);

    eventBus.fire(const CoinEarnedEvent(amount: 15, reason: 'test'));
    await Future.delayed(const Duration(milliseconds: 10));

    expect(receivedEvents.length, 1);
    expect((receivedEvents.first as CoinEarnedEvent).amount, 15);
    await sub.cancel();
  });

  test('fire different events routes to appropriate subscribers only', () async {
    final coinEvents = <CoinEarnedEvent>[];
    final lessonEvents = <LessonCompletedEvent>[];

    final sub1 = eventBus.on<CoinEarnedEvent>().listen(coinEvents.add);
    final sub2 = eventBus.on<LessonCompletedEvent>().listen(lessonEvents.add);

    eventBus.fire(const CoinEarnedEvent(amount: 10, reason: 'bonus'));
    eventBus.fire(const LessonCompletedEvent(lessonId: 'math_1', stars: 3, coins: 20));
    await Future.delayed(const Duration(milliseconds: 10));

    expect(coinEvents.length, 1);
    expect(lessonEvents.length, 1);
    expect(lessonEvents.first.lessonId, 'math_1');

    await sub1.cancel();
    await sub2.cancel();
  });
}
