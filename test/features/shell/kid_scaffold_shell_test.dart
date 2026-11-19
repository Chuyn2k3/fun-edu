import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:funedu/features/shell/kid_scaffold_shell.dart';

void main() {
  testWidgets('KidScaffoldShell renders navigationShell and preserves branch state in IndexedStack',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              KidScaffoldShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const _TestTab(label: 'HomeTab'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/game',
                  builder: (context, state) => const _TestTab(label: 'GameTab'),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('HomeTab'), findsOneWidget);
    expect(find.text('GameTab'), findsNothing);

    // Navigate to /game
    router.go('/game');
    await tester.pump();

    expect(find.text('HomeTab'), findsNothing);
    expect(find.text('GameTab'), findsOneWidget);

    // Navigate back to /
    router.go('/');
    await tester.pump();

    expect(find.text('HomeTab'), findsOneWidget);
    expect(find.text('GameTab'), findsNothing);
  });
}

class _TestTab extends StatefulWidget {
  const _TestTab({required this.label});
  final String label;

  @override
  State<_TestTab> createState() => _TestTabState();
}

class _TestTabState extends State<_TestTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(widget.label)),
    );
  }
}
