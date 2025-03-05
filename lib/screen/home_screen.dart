import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fun_edu/screen/custom_drawer/drawScreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../helper/global.dart';
import '../helper/pref.dart';
import '../model/home_type.dart';
import '../widget/home_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onDrawerStateChanged});
  final Function(bool)? onDrawerStateChanged;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _xOffset = 0;
  double _yOffset = 0;
  double _scaleFactor = 1;
  bool isDrawerOpen = false;
  int currentPage = 0;
  int page = 0;
  double value = 0;
  double kPadding = 20.0;
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Pref.showOnboarding = false;
  }

  void toggleDrawer() {
    setState(() {
      isDrawerOpen = !isDrawerOpen;
      if (isDrawerOpen) {
        _xOffset = 230;
        _yOffset = 150;
        _scaleFactor = 0.6;
      } else {
        _xOffset = 0;
        _yOffset = 0;
        _scaleFactor = 1;
      }
    });
    widget.onDrawerStateChanged
        ?.call(isDrawerOpen); // Gửi trạng thái cho MainTabbarScreen
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.sizeOf(context);
    final size = MediaQuery.of(context).size;
    return Stack(
      children: <Widget>[
        const DrawerScreen(),
        AnimatedContainer(
          width: double.maxFinite,
          height: double.maxFinite,
          curve: Curves.decelerate,
          transform: Matrix4.translationValues(_xOffset, _yOffset, 0)
            ..scale(_scaleFactor)
            ..rotateY(isDrawerOpen ? -0.5 : 0),
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isDrawerOpen ? 40.0 : 0),
          ),
          child: Stack(
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(isDrawerOpen ? 32 : 0),
                    topRight: Radius.circular(kPadding * 1.5),
                    topLeft: Radius.circular(kPadding * 1.5),
                  ),
                ),
              ),
              Positioned(
                top: size.height * 0.24,
                left: 0,
                right: 0,
                child: _buildContent(),
              ),
              Positioned(
                top: 0,
                child: Container(
                  width: size.width,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF03F0FF).withOpacity(0.7),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isDrawerOpen ? 32 : 0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                            isDrawerOpen ? Icons.arrow_back_ios : Icons.menu,
                            size: 30),
                        onPressed: toggleDrawer,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: size.height * 0.055,
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildHeader(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.fromLTRB(
        0, 0,
        //mq.height * 0.02,
        0,
        mq.height * 0.54,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF03F0FF).withOpacity(0.7),
            const Color(0xFF007AFF).withOpacity(0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        //color: Colors.red,
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(32),
          bottomLeft: Radius.circular(32),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            "assets/images/hi.png",
            width: mq.width * 0.6,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.start,
                  "HỌC\nVUI\nCHƠI\nHAY!\n🚀",
                  style: GoogleFonts.fredoka(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    const list = HomeType.values;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      //color: Colors.black12,
      height: mq.height * 0.6,
      child: CarouselSlider.builder(
        options: CarouselOptions(
          enableInfiniteScroll: false,
          scrollDirection: Axis.vertical,
          autoPlay: false,
          enlargeCenterPage: true,
          viewportFraction: 0.40,
          initialPage: 0,
        ),
        itemCount: list.length,
        itemBuilder: (context, int index, int pageViewIndex) {
          return GestureDetector(
            onTap: () {
              list[index].onTap();
            },
            child: HomeCard(
              homeType: list[index],
            ),
          );
        },
      ),
    );
  }
}
