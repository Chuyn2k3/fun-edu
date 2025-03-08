import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fun_edu/helper/ad_helper.dart';
import 'package:fun_edu/helper/global.dart';
import 'package:fun_edu/model/home_type.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeCard extends StatelessWidget {
  final HomeType homeType;

  const HomeCard({super.key, required this.homeType});

  @override
  Widget build(BuildContext context) {
    Animate.restartOnHotReload = true;

    return InkWell(
        onTap: ()
            //homeType.onTap,
            =>
            AdHelper.showInterstitialAd(homeType.onTap),
        child: _buildCard());
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildImage(),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(
                  bottom: mq.height * .03, top: mq.height * .02),
              decoration: BoxDecoration(
                  color: const Color(0xFF03F0FF).withOpacity(0.7),
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  )),
              child: InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                onTap: ()
                    //homeType.onTap,
                    =>
                    AdHelper.showInterstitialAd(homeType.onTap),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 6,
                      ),
                      _buildTitle(),
                      SizedBox(
                        height: mq.height * 0.018,
                      ),
                      _buildDesc()
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ).animate().fade(duration: 1.seconds, curve: Curves.easeIn),
    );
  }

  Widget _buildImage() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF03F0FF).withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          height: mq.height * 0.24,
          width: mq.width * 0.4,
        ),
        Image.asset(
          "assets/images/${homeType.image}",
          fit: BoxFit.cover,
          height: mq.height * 0.18,
          width: mq.width * 0.32,
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      homeType.title,
      style: GoogleFonts.fredoka(
        fontSize: 30,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDesc() {
    return Text(
      homeType.desc,
      style: GoogleFonts.fredoka(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }
}
