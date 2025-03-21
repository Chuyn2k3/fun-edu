import 'package:flutter/material.dart';
import 'package:animator/animator.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:fun_edu/feature/game_feature/enum/game_enum.dart';
import 'package:fun_edu/feature/game_feature/widget/custom_stack.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ListGamePage extends StatelessWidget {
  const ListGamePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: mq.width,
        height: mq.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB2EBF2), Color(0xFFFDE7E7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Các họa tiết nền dễ thương
            Positioned(
              top: 60,
              left: 40,
              child: FaIcon(
                FontAwesomeIcons.star,
                color: Colors.yellowAccent.withOpacity(0.3),
                size: 30,
              ),
            ),
            Positioned(
              bottom: 100,
              right: 50,
              child: FaIcon(
                FontAwesomeIcons.rocket,
                color: Colors.orangeAccent.withOpacity(0.3),
                size: 30,
              ),
            ),
            Positioned(
              top: 200,
              left: 30,
              child: FaIcon(
                FontAwesomeIcons.gamepad,
                color: Colors.blueAccent.withOpacity(0.3),
                size: 30,
              ),
            ),
            Positioned(
              bottom: 200,
              right: 20,
              child: FaIcon(
                FontAwesomeIcons.gem,
                color: Colors.purpleAccent.withOpacity(0.3),
                size: 30,
              ),
            ),

            // Nội dung chính
            ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                const SizedBox(height: 40),

                // Tiêu đề
                Text(
                  'Chọn trò chơi',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),

                // Mũi tên xuống nhấp nháy
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: Animator<double>(
                    duration: const Duration(milliseconds: 800),
                    cycles: 0,
                    curve: Curves.easeInOut,
                    tween: Tween<double>(begin: 0.8, end: 1.2),
                    builder: (context, animatorState, child) => Transform.scale(
                      scale: animatorState.value,
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 40,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Slider hiển thị các game
                CarouselSlider(
                  options: CarouselOptions(
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 4),
                    height: 520,
                    enlargeCenterPage: true,
                    padEnds: true,
                    viewportFraction: .75,
                  ),
                  items: GameEnum.values.map((e) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: e.onTap,
                        child: CustomStack(
                          image: e.getImage,
                          text1: e.getName,
                          color: Colors.blueAccent,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
