import 'package:flutter/material.dart';
import 'package:fun_edu/data/term/app_colors.dart';
import 'package:fun_edu/data/term/constants.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:animated_widgets/animated_widgets.dart';
import 'package:fun_edu/feature/number_feature/match_image.dart';
import 'package:fun_edu/feature/number_feature/sort_number.dart';

class CustomCardModel {
  final String title, subImage, image;
  final Color color;
  CustomCardModel({
    required this.title,
    required this.subImage,
    required this.image,
    required this.color,
  });
}

class ModelStyle extends StatefulWidget {
  final CustomCardModel cardModel;
  const ModelStyle({super.key, required this.cardModel});

  @override
  State<ModelStyle> createState() => _ModelStyleState();
}

class _ModelStyleState extends State<ModelStyle> {
  final FlutterTts flutterTts = FlutterTts();
  bool flag = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(left: 20, right: 10),
            height: 230,
            child: Stack(
              children: [
                Positioned(
                  top: 30,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchImage(),
                          ));
                      // Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //       builder: (context) => const SortNumber(),
                      //     ));
                    },
                    child: Container(
                      height: 180,
                      width: ScreenSize(context).width * 0.9,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF03F0FF).withOpacity(0.03),
                            const Color(0xFF007AFF).withOpacity(0.15),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 2,
                  left: 10,
                  child: ShakeAnimatedWidget(
                    enabled: flag,
                    duration: const Duration(milliseconds: 150),
                    shakeAngle: Rotation.deg(z: 10),
                    curve: Curves.linear,
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: InkWell(
                        onTap: () async {
                          //Music().volDown();
                          await flutterTts.setLanguage('vi-VN');
                          await flutterTts.setSpeechRate(0.5);
                          await flutterTts.setVolume(1.0);
                          await flutterTts.setPitch(1.0);

                          flutterTts.speak(widget.cardModel.title);

                          setState(() => flag = true);

                          Future.delayed(const Duration(milliseconds: 650), () {
                            setState(() => flag = false);
                          });

                          // Future.delayed(Duration(milliseconds: 900), () {
                          //   Music().volUp();
                          // });
                        },
                        child: Container(
                          height: 175,
                          width: 135,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: widget.cardModel.color,
                            // boxShadow: [
                            //   BoxShadow(
                            //       color: AppColors.white.withOpacity(0.3),
                            //       spreadRadius: 2.5,
                            //       blurRadius: 4,
                            //       offset: const Offset(0.5, 1.5))
                            // ],
                            image: DecorationImage(
                                image: AssetImage(widget.cardModel.image),
                                fit: BoxFit.fill),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 55,
                  left: 180,
                  child: SizedBox(
                    height: 125,
                    width: 160,
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          PrimaryText(
                            text: widget.cardModel.title,
                            color: AppColors.black,
                            fontWeight: FontWeight.bold,
                            size: 35,
                          ),
                          SizedBox(
                            height: 65,
                            width: 65,
                            child: Image(
                                image: AssetImage(widget.cardModel.subImage),
                                fit: BoxFit.contain),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
