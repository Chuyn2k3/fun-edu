import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fun_edu/feature/math_feature/home_type.dart';

class MathLearnCard extends StatelessWidget {
  final MathLearnType mathLearnType;
  const MathLearnCard({
    super.key,
    required this.mathLearnType,
  });

  @override
  Widget build(BuildContext context) {
    Animate.restartOnHotReload = true;
    var mq = MediaQuery.sizeOf(context);
    return Card(
        color: Colors.blue.withOpacity(.2),
        elevation: 0,
        margin: EdgeInsets.only(bottom: mq.height * .02),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          //for ads
          // onTap: () => AdHelper.showInterstitialAd(mathLearnType.onTap),
          onTap: mathLearnType.onTap,
          child: mathLearnType.leftAlign
              ? Row(
                  children: [
                    //lottie
                    Container(
                      width: mq.width * .35,
                      padding: mathLearnType.padding,
                      child:
                          Image.asset('assets/images/${mathLearnType.image}'),
                    ),

                    //const Spacer(),

                    //title
                    Expanded(
                      child: Text(
                        mathLearnType.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                        // maxLines: 3,
                      ),
                    ),

                    // const Spacer(flex: 2),
                  ],
                )
              : Row(
                  children: [
                    const Spacer(flex: 2),

                    //title
                    Text(
                      mathLearnType.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),

                    const Spacer(),

                    //lottie
                    Container(
                      width: mq.width * .35,
                      padding: mathLearnType.padding,
                      child:
                          Image.asset('assets/images/${mathLearnType.image}'),
                    ),
                  ],
                ),
        )).animate().fade(duration: 1.seconds, curve: Curves.easeIn);
  }
}
