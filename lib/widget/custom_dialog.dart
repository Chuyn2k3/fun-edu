import 'package:design_system_sl/design_system_sl.dart';
import 'package:flutter/material.dart';
import 'package:fun_edu/utils/common_app.dart';
import 'package:fun_edu/utils/navigation_service.dart';
import 'package:fun_edu/widget/primary_button.dart';


class CustomDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final String? titleButton;
  final String? titleCancel;
  final VoidCallback? actionCancel;
  final VoidCallback? action;
  final Color? messageColor;
  const CustomDialog({
    super.key,
    this.title,
    this.message,
    this.titleButton,
    this.titleCancel,
    this.action,
    this.actionCancel,
    this.messageColor,
  });

  Widget dialogContent(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (title != null)
            Text(
              title!,
              textAlign: TextAlign.center,
              style: textTheme.t18B.copyWith(
                color: colorApp.labelPrimary,
              ),
            ),
          if (title != null)
            const SizedBox(
              height: 16,
            ),
          if (message != null) ...[
            Text(
              message!,
              textAlign: TextAlign.center,
              style: textTheme.t14R.copyWith(
                color: messageColor ?? colorApp.labelPrimary,
              ),
            ),
            const SizedBox(height: 24.0),
          ],
          _buildActionButton(context),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final numberOfAction = titleButton != null ? 2 : 1;
    if (numberOfAction == 1) {
      return SizedBox(
        width: double.infinity,
        child: PrimaryButton(
          label: titleCancel ?? "Xác nhận",
          onPressed: () {
            Navigator.pop(context);
            actionCancel?.call();
          },
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: PrimaryButton(
            label: titleCancel ?? "Hủy",
            backgroundColor: const Color(0xFF007AFF).withOpacity(0.2),
            textColor: const Color(0xFF007AFF),
            onPressed: () {
              Navigator.pop(context);
              actionCancel?.call();
            },
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          flex: 1,
          child: PrimaryButton(
            onPressed: action,
            label: titleButton!,
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0.0,
      insetPadding: const EdgeInsets.all(32),
      backgroundColor: Colors.transparent,
      child: dialogContent(context),
    );
  }
}

void showDialogCustom({
  String? title,
  Widget? customContent,
  String? message,
  String? titleButton,
  bool? barrierDismissible,
  VoidCallback? action,
  VoidCallback? actionCancel,
  Color? messageColor,
}) {
  showDialog(
    barrierDismissible: barrierDismissible ?? false,
    context: getContext,
    builder: (BuildContext context) {
      return customContent ??
          CustomDialog(
            title: title,
            message: message,
            titleButton: titleButton,
            action: action,
            actionCancel: actionCancel,
            messageColor: messageColor,
          );
    },
  );
}
