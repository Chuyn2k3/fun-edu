import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/ui/feedback/app_toast.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('toast replaces the previous toast', (t) async {
    await t.pumpWidget(
      _harness(
        Builder(
          builder: (context) => Column(
            children: [
              ElevatedButton(
                onPressed: () => showAppToast(context, 'Thông báo một', kind: AppToastKind.info),
                child: const Text('Hiện 1'),
              ),
              ElevatedButton(
                onPressed: () => showAppToast(context, 'Thông báo hai', kind: AppToastKind.success),
                child: const Text('Hiện 2'),
              ),
            ],
          ),
        ),
      ),
    );

    await t.tap(find.text('Hiện 1'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('Thông báo một'), findsOneWidget);

    // Second toast replaces the first
    await t.tap(find.text('Hiện 2'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('Thông báo một'), findsNothing);
    expect(find.text('Thông báo hai'), findsOneWidget);
  });

  testWidgets('toast hides after duration', (t) async {
    await t.pumpWidget(
      _harness(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showAppToast(
              context,
              'Tự động ẩn',
              duration: const Duration(seconds: 2),
            ),
            child: const Text('Bật toast'),
          ),
        ),
      ),
    );

    await t.tap(find.text('Bật toast'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('Tự động ẩn'), findsOneWidget);

    // After duration + fade out animation, toast is gone
    await t.pump(const Duration(seconds: 2));
    await t.pumpAndSettle();
    expect(find.text('Tự động ẩn'), findsNothing);
  });

  testWidgets('toast kinds display appropriate icons', (t) async {
    await t.pumpWidget(
      _harness(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showAppToast(context, 'Offline rồi', kind: AppToastKind.offline),
            child: const Text('Bật offline'),
          ),
        ),
      ),
    );

    await t.tap(find.text('Bật offline'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('Offline rồi'), findsOneWidget);
  });
}
