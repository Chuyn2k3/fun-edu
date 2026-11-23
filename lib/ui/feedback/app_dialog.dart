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
Future<bool?> showAppDialog(
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
}) {
  return showDialog<bool>(
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
                    height: isKid ? (isTablet ? 140 : 110) : 84,
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
            if (message != null) ...[
              const SizedBox(height: 10),
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
            ],
            if (body != null) ...[
              const SizedBox(height: 14),
              Flexible(child: SingleChildScrollView(child: body)),
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
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(primaryLabel),
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 8),
              TextButton(
                key: secondaryKey,
                style: TextButton.styleFrom(
                  foregroundColor: tone == AppDialogTone.danger
                      ? AppColors.danger
                      : AppColors.textMuted,
                  minimumSize: Size(double.infinity, btnHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  textStyle: TextStyle(
                    fontSize: isKid ? (isTablet ? 20 : 17) : 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(secondaryLabel),
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
