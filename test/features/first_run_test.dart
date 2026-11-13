import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/setup/first_run_screen.dart';
import 'package:funedu/profile/kid_repository.dart';
import 'package:funedu/ui/widgets/primary_button.dart';

import 'setup_helpers.dart';

PrimaryButton _button(WidgetTester t, String label) =>
    t.widget<PrimaryButton>(find.widgetWithText(PrimaryButton, label));

Future<void> _toConsent(WidgetTester t) async {
  await t.tap(find.text('Tôi là ba mẹ'));
  await settle(t);
  await passGate(t);
}

void main() {
  for (final size in const [Size(375, 667), Size(1024, 1366)]) {
    testWidgets('fresh install walks gate, consent, profile at $size',
        (t) async {
      final db = await pumpRealApp(t, size: size);
      expect(find.text('Dành cho ba mẹ'), findsOneWidget);
      expect(find.text('Chào ba mẹ!'), findsNothing);
      expect(t.takeException(), isNull);

      await _toConsent(t);
      expect(find.text('Chào ba mẹ!'), findsOneWidget);
      expect(find.textContaining('Chíp Chíp chỉ lưu tên gọi ở nhà'),
          findsOneWidget);
      expect(find.text('Xem chính sách quyền riêng tư'), findsOneWidget);
      expect(_button(t, 'Tiếp tục').onPressed, isNull);
      await t.tap(find.text('Tôi đồng ý'));
      await t.pump();
      expect(_button(t, 'Tiếp tục').onPressed, isNotNull);
      expect(t.takeException(), isNull);
      await t.tap(find.text('Tiếp tục'));
      await t.pumpAndSettle();

      expect(find.text('Tạo hồ sơ cho bé'), findsOneWidget);
      expect(_button(t, 'Xong').onPressed, isNull);
      await t.enterText(find.byType(TextField), '  Na ');
      await t.pump();
      expect(_button(t, 'Xong').onPressed, isNull, reason: 'needs avatar, age');
      await t.tap(find.byKey(const ValueKey('avatar-1')));
      await t.pump();
      await t.ensureVisible(find.text('5'));
      await t.tap(find.text('5'));
      await t.pump();
      expect(_button(t, 'Xong').onPressed, isNotNull);
      expect(t.takeException(), isNull);
      await t.ensureVisible(find.text('Xong'));
      await t.tap(find.text('Xong'));
      await settle(t);

      expect(find.text('Chào bé! Mình là Chíp Chíp'), findsOneWidget);
      final repo = KidRepository(db);
      final kids = await t.runAsync(repo.kids);
      expect(kids!.single.nickname, 'Na');
      expect(kids.single.age, 5);
      expect(await t.runAsync(repo.currentKidId), kids.single.id);
      final consent = await t.runAsync(() => repo.setting(consentAtKey));
      expect(DateTime.tryParse(consent ?? ''), isNotNull);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('closing the gate stays on the parent screen', (t) async {
    await pumpRealApp(t);
    await t.tap(find.text('Tôi là ba mẹ'));
    await settle(t);
    await t.tap(find.text('Đóng'));
    await settle(t);
    expect(find.text('Dành cho ba mẹ'), findsOneWidget);
    expect(find.text('Chào ba mẹ!'), findsNothing);
  });

  testWidgets('nickname must be 1..20 trimmed characters', (t) async {
    await pumpRealApp(t);
    await _toConsent(t);
    await t.tap(find.text('Tôi đồng ý'));
    await t.pump();
    await t.tap(find.text('Tiếp tục'));
    await t.pumpAndSettle();
    const error = 'Nhập tên gọi ở nhà (tối đa 20 ký tự)';
    expect(find.text(error), findsNothing);

    await t.enterText(find.byType(TextField), '   ');
    await t.pump();
    expect(find.text(error), findsOneWidget);

    await t.enterText(find.byType(TextField), 'a' * 21);
    await t.pump();
    expect(find.text(error), findsOneWidget);

    await t.enterText(find.byType(TextField), 'a' * 20);
    await t.pump();
    expect(find.text(error), findsNothing);
  });
}
