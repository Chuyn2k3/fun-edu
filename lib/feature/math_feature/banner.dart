import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fun_edu/data/term/constants.dart';


class BannerCustom extends StatefulWidget {
  const BannerCustom({super.key});

  @override
  State<BannerCustom> createState() => _BannerCustomState();
}

class _BannerCustomState extends State<BannerCustom> {
  PageController? _pageController;
  var selectedIndex = 0;
  Timer? _timer;
  int _currentPage = 0;
  final int _numPages = 4;
  final int _duration = 2;
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(Duration(seconds: _duration), (timer) {
      if (_currentPage < _numPages - 1) {
        _currentPage++;
      } else {
        _currentPage = _currentPage % (_numPages - 1);
      }
      _pageController!.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeIn,
      );
    });
  }

Widget _bannerItem(String desc, Size size) {
  return Container(
    decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: const DecorationImage(
            image: AssetImage('assets/images/top_background.png'),
            fit: BoxFit.cover)),
    width: size.width * 0.6,
    height: size.height * 0.08,

    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      SizedBox(
        width: size.width * 0.01,
      ),
      Image.asset(
        'assets/images/logo.png',
        height: size.height * 0.4,
        width: size.width * 0.4,
      ),
      Expanded(
        child: Text(
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            desc,
            style: TextStyle(
                fontSize: size.width * 0.05,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
      ),
      SizedBox(
        width: size.width * 0.01,
      ),
    ]),
  );
}

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: PageView.builder(
            onPageChanged: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            controller: _pageController,
            itemCount: _numPages,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return _bannerItem(desc[index], size);
            },
          ),
        ),
        const SizedBox(
          height: 2,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...List.generate(4, (index) {
              return Indicator(
                isActive: selectedIndex == index ? true : false,
                size: size,
              );
            })
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer!.cancel();
    _pageController!.dispose();
    super.dispose();
  }

}

class Indicator extends StatelessWidget {
  final bool isActive;
  final Size size;
  const Indicator({super.key, required this.isActive, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isActive ? size.width * 0.3 : size.width * 0.1,
      height: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isActive ? Colors.orange : Colors.grey,
      ),
    );
  }
}
