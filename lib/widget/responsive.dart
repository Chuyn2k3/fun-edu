import 'package:flutter/material.dart';
import 'package:fun_edu/widget/breakpoint_label.dart';
import 'package:responsive_framework/responsive_framework.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const Responsive({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

// This size work fine on my design, maybe you need some customization depends on your design

  // This isMobile, isTablet, isDesktop helep us later
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 800;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width < 1000 &&
      MediaQuery.of(context).size.width >= 700;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1000;

  static bool isLagerThan(BuildContext context, double value) =>
      MediaQuery.of(context).size.width >= value;

  /// Height of widget
  static double heightOfTable(BuildContext context) {
    final value = ResponsiveValue(
      context,
      defaultValue: 600.0,
      conditionalValues: [
        const Condition.equals(
          name: MOBILE,
          value: 600.0,
        ),
        const Condition.equals(
          name: TABLET,
          value: 600.0,
        ),
        const Condition.equals(
          name: smallDesktop,
          value: 800.0,
        ),
        const Condition.equals(
          name: DESKTOP,
          value: 800.0,
        ),
        const Condition.equals(
          name: tv,
          value: 1200.0,
        ),
      ],
    ).value;

    return value;
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    // If our width is more than 1100 then we consider it a desktop
    if (size.width >= 1000) {
      if (desktop != null) {
        return desktop!;
      }
    }
    // If width it less then 1100 and more then 850 we consider it as tablet
    else if (size.width >= 700 && tablet != null) {
      return tablet ?? desktop ?? mobile;
    }
    // Or less then that we called it mobile

    return mobile;
  }
}
