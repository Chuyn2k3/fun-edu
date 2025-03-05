import 'package:flutter/material.dart';
import 'package:fun_edu/feature/math_feature/action_study_widget.dart';
import 'package:fun_edu/feature/math_feature/banner.dart';
import 'package:fun_edu/helper/pref.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/custom_app_bar.dart';
import 'package:fun_edu/utils/extension.dart';
import 'package:get/get.dart';

class MathFeature extends StatelessWidget {
  const MathFeature({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
 final isDarkMode = Get.isDarkMode.obs;
    return
    BaseScaffold(
      appBar: CustomAppbar.basic(
        title: "Toán học",
        styleTitle: TextStyle(color: Theme.of(context).lightTextColor),
        onTap: () => Navigator.pop(context),
        actions: [
          IconButton(
            padding: const EdgeInsets.only(right: 10),
            onPressed: () {
              Get.changeThemeMode(
                  isDarkMode.value ? ThemeMode.light : ThemeMode.dark);

              isDarkMode.value = !isDarkMode.value;
              Pref.isDarkMode = isDarkMode.value;
            },
            icon: Obx(
              () => Icon(
                isDarkMode.value
                    ? Icons.brightness_2_rounded
                    : Icons.brightness_5_rounded,
                size: 26,
                color: isDarkMode.value ? Colors.white : null,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Image.asset(
                    "assets/images/math_screen_logo.jpg",
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.fill,
                  ),
                  const SizedBox(height: 12),
                  const BannerCustom(),
                  const SizedBox(height: 12),
                  const ActionStudyDisplay(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    )
    ;
  }
}
