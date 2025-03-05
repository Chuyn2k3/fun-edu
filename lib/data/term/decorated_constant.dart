import 'package:flutter/material.dart';
import 'package:fun_edu/data/term/app_colors.dart';


class DecoratedConst {
  DecoratedConst._();
  static const decoratedCircular8White = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(8)),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        offset: Offset(1.0, 2.0),
        blurRadius: 2.0,
        spreadRadius: 2.0,
      ),
    ],
  );

  static const decoratedCircular20White = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(20)),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        offset: Offset(1.0, 2.0),
        blurRadius: 2.0,
        spreadRadius: 2.0,
      ),
    ],
  );

  static var bottomNavigation = BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: AppColors.startBtnColor.withOpacity(.4),
          offset: const Offset(1.0, 2.0),
          blurRadius: 10.0,
          spreadRadius: 10.0,
        ),
      ],
      borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30), topRight: Radius.circular(30)));

  static var blueCircular = (int circular) => BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(circular.toDouble())),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(1.0, 2.0),
            blurRadius: 2.0,
            spreadRadius: 2.0,
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [0.0, 0.5, 1.0],
          colors: [Color(0xFF4CB1F1), Color(0xFF4FC5F3), Color(0xFF53D9F6)],
        ),
      );
  static var greyCircular = (int circular) => BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(circular.toDouble())),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(1.0, 2.0),
            blurRadius: 2.0,
            spreadRadius: 2.0,
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [0.0, 0.5, 1.0],
          colors: [
            Color.fromARGB(255, 123, 128, 131),
            Color.fromARGB(255, 187, 194, 196),
            Color.fromARGB(255, 227, 234, 235)
          ],
        ),
      );
  static var whiteCircular = (int circular) => BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(circular.toDouble())),
        color: AppColors.whiteColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(1.0, 2.0),
            blurRadius: 2.0,
            spreadRadius: 2.0,
          ),
        ],
      );
  static var greyBackgroundCircular = (int circular) => BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(circular.toDouble())),
        color: const Color(0xFFF5F5F5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(1.0, 2.0),
            blurRadius: 2.0,
            spreadRadius: 2.0,
          ),
        ],
      );

  static var redCircular = (int circular) => BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(
          circular.toDouble(),
        )),
        color: AppColors.lightRedColor,
        border: Border.all(color: AppColors.redColor, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(1.0, 2.0),
            blurRadius: 2.0,
            spreadRadius: 2.0,
          ),
        ],
      );

  static var greenCircular = (int circular) => BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(
          circular.toDouble(),
        )),
        color: AppColors.lightGreenColor,
        border: Border.all(color: AppColors.greenColor, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(1.0, 2.0),
            blurRadius: 2.0,
            spreadRadius: 2.0,
          ),
        ],
      );

  static var baseCircular = ({required int circular, required Color color}) =>
      BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(circular.toDouble())),
        color: color,
      );
}
