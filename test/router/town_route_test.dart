import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/router/go_router_name_enum.dart';

void main() {
  test('GoRouterName contains town route with valid name and path', () {
    final townRoute = GoRouterName.values.firstWhere(
      (e) => e.routeName == 'town',
      orElse: () => throw Exception('town route not found in GoRouterName'),
    );
    expect(townRoute.routePath, '/town');
  });
}
