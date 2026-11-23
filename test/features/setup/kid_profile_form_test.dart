import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/setup/kid_profile_form.dart';
import 'package:funedu/profile/avatars.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'KidProfileForm displays all 18 avatars in a scrollable view on 320x568 without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? submittedNickname;
    String? submittedAvatar;
    int? submittedAge;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: KidProfileForm(
              onSubmit: (nickname, avatar, age) async {
                submittedNickname = nickname;
                submittedAvatar = avatar;
                submittedAge = age;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify no render flex overflow happened
    expect(tester.takeException(), isNull);

    // Verify all 18 avatars exist in the widget tree
    for (var i = 0; i < 18; i++) {
      expect(find.byKey(ValueKey('avatar-$i')), findsOneWidget);
    }

    // Verify avatar tile dimensions are at least 64
    final firstTileBox = tester.renderObject(find.byKey(const ValueKey('avatar-0'))) as RenderBox;
    expect(firstTileBox.size.width, greaterThanOrEqualTo(64.0));
    expect(firstTileBox.size.height, greaterThanOrEqualTo(64.0));

    // Fill form: enter nickname
    await tester.enterText(find.byType(TextField), 'Bé Bắp');
    await tester.pump();

    // Select the 12th avatar (unicorn) by scrolling to it
    final unicornKey = find.byKey(const ValueKey('avatar-11'));
    await tester.ensureVisible(unicornKey);
    await tester.tap(unicornKey);
    await tester.pump();

    // Select age 5
    final age5 = find.text('5');
    await tester.ensureVisible(age5);
    await tester.tap(age5);
    await tester.pump();

    // Submit form
    final submitButton = find.text('Xong');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(submittedNickname, 'Bé Bắp');
    expect(submittedAvatar, kidAvatars[11]);
    expect(submittedAge, 5);
    expect(tester.takeException(), isNull);
  });
}
