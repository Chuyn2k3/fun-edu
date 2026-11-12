import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/app.dart';

void main() {
  testWidgets('app khởi động và hiện tên Chíp Chíp', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();
    expect(find.text('Chíp Chíp'), findsOneWidget);
  });
}
