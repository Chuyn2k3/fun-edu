import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_edu/router/go_router_name_enum.dart';

void main() {
  test('GoRouterName contains shopGame routes and paths', () {
    expect(GoRouterName.shopGameLevelSelect.routePath, equals('/shop-game'));
    expect(GoRouterName.shopGamePlay.routePath, equals('/shop-game/play/:levelId'));
    expect(GoRouterName.shopGameLevelSelect.routeName, equals('shopGameLevelSelect'));
    expect(GoRouterName.shopGamePlay.routeName, equals('shopGamePlay'));
  });
}
