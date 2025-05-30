import 'package:flutter/widgets.dart';
class BackgroundV2 extends StatelessWidget {
  /// {@macro background_v2}
  const BackgroundV2({
    super.key, // ignore: unused_element
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.fill,
          image: AssetImage('assets/images/Home.png'),
        ),
      ),
    );
  }
}
