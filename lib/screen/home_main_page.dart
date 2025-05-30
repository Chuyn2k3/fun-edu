import 'package:flutter/material.dart';
import 'package:fun_edu/tab_bar/tab_bar.dart';

class HomeMainPage extends StatelessWidget {
  const HomeMainPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: MainTabbarScreen(),
      ),
    );
  }
}
