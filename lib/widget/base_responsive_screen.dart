import 'package:flutter/material.dart';
import 'package:fun_edu/data/term/app_config.dart';
import 'adpaptive_scrollbar.dart';
import 'menu/portal_master_layout.dart';
import 'responsive.dart';

class BaseResponsiveScreen extends StatelessWidget {
  BaseResponsiveScreen(
      {super.key,
      required this.childDesktop,
      required this.height,
      required this.width,
      required this.childMobile,
      required this.heightMobile,
      this.flexHeightResponsive});
  final Widget childDesktop;
  final double height;
  final double width;
  final Widget childMobile;
  final double heightMobile;
  final bool? flexHeightResponsive;
  final _verticalScrollController = ScrollController();
  final _horizontalScrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return _responsiveDesktop(context);
    } else {
      return _responsiveMobile(context);
    }
  }

  Widget _responsiveDesktop(BuildContext context) {
    var size = context.screenSize;
    if (size.width >= width && size.height >= height) {
      return PortalMasterLayout(
          body: SizedBox(
              width: size.width, height: size.height, child: childDesktop));
    } else if (size.width >= width && size.height < height) {
      return PortalMasterLayout(
          body: AdaptiveScrollbarScreen(
        horizontalScrollController: _horizontalScrollController,
        verticalScrollController: _verticalScrollController,
        child: SingleChildScrollView(
          controller: _verticalScrollController,
          scrollDirection: Axis.vertical,
          child: SizedBox(
            width: size.width,
            height: height,
            child: childDesktop,
          ),
        ),
      ));
    } else if (size.width < width && size.height > height) {
      return PortalMasterLayout(
          body: AdaptiveScrollbarScreen(
              horizontalScrollController: _horizontalScrollController,
              verticalScrollController: _verticalScrollController,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _horizontalScrollController,
                child: SizedBox(
                    width: width, height: size.height, child: childDesktop),
              )));
    } else {
      return PortalMasterLayout(
          body: AdaptiveScrollbarScreen(
              horizontalScrollController: _horizontalScrollController,
              verticalScrollController: _verticalScrollController,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                controller: _verticalScrollController,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _horizontalScrollController,
                  child: SizedBox(
                      width: width, height: height, child: childDesktop),
                ),
              )));
    }
  }

  Widget _responsiveMobile(BuildContext context) {
    return PortalMasterLayout(
      body: flexHeightResponsive ?? false
          ? childMobile
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(height: heightMobile, child: childMobile),
            ),
    );
  }
}
