
import 'package:flutter/material.dart';
import 'package:fun_edu/screen/home_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class MainTabbarScreen extends StatefulWidget {
  const MainTabbarScreen({super.key});

  @override
  State<MainTabbarScreen> createState() => _MainTabbarScreenState();
}

class _MainTabbarScreenState extends State<MainTabbarScreen> {

  bool isDrawerOpen = false;
  final List<Widget> pages = [];
  bool isDrawerOpen1 = false;
  var _indexPages = 0;
  @override
  void initState() {
    super.initState();
    pages.add(HomeScreen(
      onDrawerStateChanged: (isOpen) {
        setState(() {
          isDrawerOpen = isOpen;
        });
      },
    ));
    pages.add(
        Container(color: Colors.green, child: const Center(child: Text('AI'))));
    pages.add(Container(
        color: Colors.red, child: const Center(child: Text('Trò chơi'))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: pages[_indexPages],
      bottomNavigationBar: isDrawerOpen
          ? null
          : CurvedNavigationBar(
              buttonBackgroundColor: Colors.transparent,
              backgroundColor: Colors.white,
              color: const Color(0xFF007AFF).withOpacity(0.1),
              animationCurve: Curves.easeOutSine, //kiểu của tabbar chuyển tabs
              items: <Widget>[
                _buildIconButtonBar("assets/images/numbers_tabbar.png"),
                _buildIconButtonBar("assets/images/ai_1.png"),
                _buildIconButtonBar("assets/images/game-controller.png"),
              ],
              onTap: ((int index) {
                setState(() {
                  _indexPages = index;
                });
              }),
            ),
    );
  }

  Widget _buildIconButtonBar(String image) {
    return SizedBox(
      height: 48,
      width: 48,
      child: Image.asset(
        image,
      ),
    );
  }
}
