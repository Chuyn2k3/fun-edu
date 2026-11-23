import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/ui/feedback/app_status_banner.dart';
import 'package:funedu/ui/feedback/app_toast.dart';

Widget _harness(Widget child, {Size size = const Size(375, 667)}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('banner calls onTap when tapped', (t) async {
    var tapped = false;
    await t.pumpWidget(
      _harness(
        AppStatusBanner(
          text: 'Tiến độ chưa lưu online',
          kind: AppToastKind.warning,
          onTap: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Tiến độ chưa lưu online'), findsOneWidget);
    await t.tap(find.byType(AppStatusBanner));
    await t.pump();
    expect(tapped, isTrue);
  });

  testWidgets('banner renders without overflow at 320x568 and tablet 1024x768', (t) async {
    const longText =
        'Ba mẹ ơi, tiến độ 3 ngày nay chưa lưu online. Kiểm tra mạng giúp bé nhé để không mất sao bài học.';

    // Phone 320x568
    await t.pumpWidget(
      _harness(
        const AppStatusBanner(
          text: longText,
          kind: AppToastKind.warning,
        ),
        size: const Size(320, 568),
      ),
    );
    expect(find.text(longText), findsOneWidget);
    expect(t.takeException(), isNull);

    // Tablet 1024x768
    await t.pumpWidget(
      _harness(
        const AppStatusBanner(
          text: longText,
          kind: AppToastKind.offline,
        ),
        size: const Size(1024, 768),
      ),
    );
    expect(find.text(longText), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
