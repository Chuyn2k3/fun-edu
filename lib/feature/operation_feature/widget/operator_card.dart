import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fun_edu/feature/operation_feature/operator_type.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class OperatorCard extends StatelessWidget {
  final OperatorType operatorType;

  const OperatorCard({super.key, required this.operatorType});

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
          // onTap: () => AdHelper.showInterstitialAd(OperatorType.onTap),
          onTap: operatorType.onTap,
          child: operatorType.leftAlign
              ? Row(
                  children: [
                    //lottie
                    Container(
                      width: mq.width * .35,
                      padding: operatorType.padding,
                      child: Image.asset('assets/number/${operatorType.image}'),
                    ),

                    //const Spacer(),

                    //title
                    Expanded(
                      child: Text(
                        operatorType.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                        maxLines: 3,
                      ),
                    ),

                    //const Spacer(flex: 2),
                  ],
                )
              : Row(
                  children: [
                    const Spacer(flex: 2),

                    //title
                    Text(
                      operatorType.title,
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
                      padding: operatorType.padding,
                      child: Image.asset('assets/number/${operatorType.image}'),
                    ),
                  ],
                ),
        )).animate().fade(duration: 1.seconds, curve: Curves.easeIn);
  }
}
