import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../assets.dart';
import '../layout/form_factor.dart';
import '../theme/tokens.dart';

enum AppDialogTone {
  normal,
  danger,
}

enum AppAudience {
  kid,
  parent,
}

/// Displays a standardized modal dialog adhering to the Chíp Chíp design system.
///
/// Returns `true` if the primary action was tapped, `false` if the secondary
/// action was tapped, or `null` if dismissed via outside tap / back.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required String title,
  String? message,
  Widget? body,
  required String primaryLabel,
  String? secondaryLabel,
  AppDialogTone tone = AppDialogTone.normal,
  String? image = AppImages.chipMain,
  bool dismissible = true,
  AppAudience audience = AppAudience.parent,
  Key? primaryKey,
  Key? secondaryKey,
  VoidCallback? onPrimaryPressed,
  VoidCallback? onSecondaryPressed,
  ValueListenable<bool>? secondaryEnabled,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (dialogContext) {
      final isTablet = dialogContext.isTablet;
      final isKid = audience == AppAudience.kid;

      final btnHeight = isKid
          ? (isTablet ? 80.0 : 64.0)
          : 48.0;

      final dialogCard = Container(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.tile),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF503C28).withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            const BoxShadow(
              color: Color(0x14503C28),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (image != null) ...[
              ExcludeSemantics(
                child: Center(
                  child: Image.asset(
                    image,
                    height: isKid ? (isTablet ? 120 : 96) : 64,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isKid ? (isTablet ? 28 : 24) : 20,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            if (message != null || body != null) ...[
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message != null)
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isKid ? 17 : 15,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                            color: AppColors.textMuted,
                          ),
                        ),
                      if (body != null) ...[
                        if (message != null) const SizedBox(height: 14),
                        body,
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              key: primaryKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, btnHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                elevation: 0,
                textStyle: TextStyle(
                  fontSize: isKid ? (isTablet ? 22 : 19) : 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onPressed: onPrimaryPressed ??
                  () => Navigator.of(dialogContext).pop(true as T?),
              child: Text(primaryLabel),
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 8),
              if (secondaryEnabled != null)
                ValueListenableBuilder<bool>(
                  valueListenable: secondaryEnabled,
                  builder: (_, enabled, __) => _buildSecondaryButton(
                    context: dialogContext,
                    label: secondaryLabel,
                    key: secondaryKey,
                    tone: tone,
                    btnHeight: btnHeight,
                    isKid: isKid,
                    isTablet: isTablet,
                    onPressed: enabled
                        ? (onSecondaryPressed ??
                            () => Navigator.of(dialogContext).pop(false as T?))
                        : null,
                  ),
                )
              else
                _buildSecondaryButton(
                  context: dialogContext,
                  label: secondaryLabel,
                  key: secondaryKey,
                  tone: tone,
                  btnHeight: btnHeight,
                  isKid: isKid,
                  isTablet: isTablet,
                  onPressed: onSecondaryPressed ??
                      () => Navigator.of(dialogContext).pop(false as T?),
                ),
            ],
          ],
        ),
      );

      return PopScope(
        canPop: dismissible,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? TabletSizes.messageMaxWidth : 460,
            ),
            child: dialogCard,
          ),
        ),
      );
    },
  );
}

Widget _buildSecondaryButton({
  required BuildContext context,
  required String label,
  Key? key,
  required AppDialogTone tone,
  required double btnHeight,
  required bool isKid,
  required bool isTablet,
  VoidCallback? onPressed,
}) {
  return TextButton(
    key: key,
    style: TextButton.styleFrom(
      foregroundColor: tone == AppDialogTone.danger
          ? AppColors.danger
          : AppColors.textMuted,
      disabledForegroundColor: tone == AppDialogTone.danger
          ? AppColors.danger.withOpacity(0.38)
          : AppColors.textMuted.withOpacity(0.38),
      minimumSize: Size(double.infinity, btnHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      textStyle: TextStyle(
        fontSize: isKid ? (isTablet ? 20 : 17) : 15,
        fontWeight: FontWeight.w800,
      ),
    ),
    onPressed: onPressed,
    child: Text(label),
  );
}
