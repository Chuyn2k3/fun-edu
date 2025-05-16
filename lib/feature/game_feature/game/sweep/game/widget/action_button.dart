
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/helper/colors.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/helper/styles.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    this.ismain = true,
    required this.title,
    required this.onPressed,
    this.customColor,
  });
  final bool ismain;
  final String title;
  final Function() onPressed;
  final Color? customColor;

  @override
  Widget build(BuildContext context) {
    final color =
        customColor ?? (ismain ? AppColors.background : AppColors.primary);
    final borderRadius = BorderRadius.circular(10);
    return Material(
      color: color,
      borderRadius: borderRadius,
      child: InkWell(
        splashColor: AppColors.primaryLight,
        onTap: onPressed,
        borderRadius: borderRadius,
        child: Container(
          width: kIsWeb ? 500 : double.infinity,
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
            border: Border.all(
              color: ismain ? AppColors.white : AppColors.primaryDark,
              width: 2,
            ),
            gradient: (customColor == null && ismain)
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.buttonTop, AppColors.buttonBottom],
                  )
                : null,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                title,
                style: titleTextStyle.copyWith(fontSize: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
