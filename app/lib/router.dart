import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Temporary home screen; replaced by the glyph list in a later task.
class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Chíp Chíp')));
  }
}

/// App-wide router. Later tasks add their routes here.
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePlaceholder()),
  ],
);
