import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fun_edu/feature/digit_feature/page.dart';
import 'package:fun_edu/feature/game_feature/game_page.dart';
import 'package:fun_edu/screen/home_screen.dart';

class MainTabbarScreen extends StatefulWidget {
  const MainTabbarScreen({super.key});

  @override
  State<MainTabbarScreen> createState() => _MainTabbarScreenState();
}

class _MainTabbarScreenState extends State<MainTabbarScreen> {
  bool isDrawerOpen = false;
  final List<Widget> pages = [];
  var _indexPages = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    Flame.device.setPortrait();
    pages.add(const HomeScreen());
    pages.add(const DigitRecogizePage());
    pages.add(const ListGamePage());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        extendBody: true,
        body: pages[_indexPages],
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: isDrawerOpen ? null : _buildCustomNavBar(),
      ),
    );
  }

  Widget _buildCustomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      margin: const EdgeInsets.only(
        bottom: 12,
        right: 12,
        left: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 0),
          _buildNavItem(Icons.memory, 1),
          _buildNavItem(Icons.sports_esports, 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _indexPages == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _indexPages = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade600 : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.blue.shade200,
          size: 40,
        ),
      ),
    );
  }
}
