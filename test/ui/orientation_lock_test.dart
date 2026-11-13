import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/ui/layout/orientation_lock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('no decision while the window has no size', () {
    expect(lockPortraitFor(Size.zero), isNull);
    expect(lockPortraitFor(const Size(0, 800)), isNull);
  });

  test('phones lock to portrait, tablets do not', () {
    expect(lockPortraitFor(const Size(390, 844)), isTrue);
    expect(lockPortraitFor(const Size(844, 390)), isTrue);
    expect(lockPortraitFor(const Size(1024, 1366)), isFalse);
    expect(lockPortraitFor(const Size(1133, 744)), isFalse);
  });

  test('PortraitLock waits for a real size, then decides once', () {
    final calls = <Object?>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        calls.add(call.arguments);
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
      PortraitLock.reset();
    });
    PortraitLock.reset();
    PortraitLock.decide(Size.zero);
    expect(PortraitLock.decided, isFalse);
    expect(calls, isEmpty);
    // A tablet: decided, nothing locked, and later sizes change nothing.
    PortraitLock.decide(const Size(1133, 744));
    expect(PortraitLock.decided, isTrue);
    PortraitLock.decide(const Size(390, 844));
    expect(calls, isEmpty);
    PortraitLock.reset();
    PortraitLock.decide(const Size(390, 844));
    expect(calls, hasLength(1));
  });
}
