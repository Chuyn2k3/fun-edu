import 'package:flutter/material.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/tab_bar/tab_bar.dart';
import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

class ChooseAgeWidget extends StatefulWidget {
  const ChooseAgeWidget({super.key});

  static String routeName = 'ChooseAge';
  static String routePath = '/ChooseAge';

  @override
  State<ChooseAgeWidget> createState() => _ChooseAgeWidgetState();
}

class _ChooseAgeWidgetState extends State<ChooseAgeWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorBase.primaryBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage('assets/images/start.png'),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hộp thoại Pippo
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 25),
                  child: Container(
                    width: 224,
                    height: 102,
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/Rectangle_2982.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: const Text(
                      'Rất vui được gặp bạn! \nBạn bao nhiêu tuổi?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Sukhumvit Set',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),

              // Ảnh Pippo
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Image.asset(
                    'assets/images/image_9081.png',
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Các nút chọn độ tuổi
              _buildAgeButton(context, '4-6 tuổi'),
              _buildAgeButton(context, '6-7 tuổi'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgeButton(BuildContext context, String ageText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
      child: InkWell(
        splashColor: Colors.transparent,
        onTap: () async {
          await GetIt.instance
              .get<SharedPreferencesManager>()
              .putBool('isFirstTime', false);
          if (!mounted) return;
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MainTabbarScreen(),
              ));
        },
        child: Container(
          width: double.infinity,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.blue.shade400, // Đổi màu nâu
            boxShadow: const [
              BoxShadow(
                blurRadius: 6,
                color: Colors.black38,
                offset: Offset(3, 3),
              )
            ],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              // color: ColorBase.buttonShadow,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              ageText,
              style: const TextStyle(
                fontFamily: 'Sukhumvit Set',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorBase.primaryBackground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
