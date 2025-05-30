import 'package:another_flushbar/flushbar.dart';
import 'package:design_system_sl/typography/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fun_edu/data/term/app_colors.dart';
import 'package:fun_edu/service/gen/assets.gen.dart';
import 'package:fun_edu/utils/common_app.dart';

extension Snackbar on BuildContext {
  void showSnackBarFail({required String text, bool? positionTop}) => Flushbar(
        icon: const Icon(
          Icons.error,
          size: 32,
          color: Colors.white,
        ),
        shouldIconPulse: false,
        message: text,
        messageText: Center(
          child: Text(
            text,
            style: PrimaryFont.medium(15).copyWith(color: AppColors.whiteColor),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        backgroundColor: Colors.red.shade300,
        borderRadius: BorderRadius.circular(16),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(8),
        flushbarPosition: positionTop == null
            ? FlushbarPosition.BOTTOM
            : FlushbarPosition.TOP,
      )..show(this);

  Future<void> showSnackBarSuccess(
      {required String text,
      bool? positionTop,
      Function(Flushbar flushbar)? ontap}) async {
    final flushbar = Flushbar(
      icon: Assets.icon.checkMark.image(fit: BoxFit.contain, height: 30),
      shouldIconPulse: false,
      message: text,
      onTap: ontap,
      messageText: Center(
        child: Text(
          text,
          style: PrimaryFont.medium(15).copyWith(color: AppColors.whiteColor),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ),
      backgroundColor: Colors.green,
      borderRadius: BorderRadius.circular(16),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(8),
      flushbarPosition:
          positionTop == null ? FlushbarPosition.BOTTOM : FlushbarPosition.TOP,
    );
    await flushbar.show(this);
  }

  void showSnackBarSuccessCustom(
          {required String text,
          bool? positionTop,
          VoidCallback? goToDetails,
          Function(Flushbar flushbar)? ontap}) =>
      Flushbar(
        icon: SvgPicture.asset(Assets.icon.icSnackbarSuccess),
        shouldIconPulse: false,
        message: text,
        onTap: ontap,
        messageText: Text(
          text,
          style: textTheme.t16R.copyWith(color: Colors.white),
          textAlign: TextAlign.left,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        mainButton: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              width: 103,
              height: 32,
              child: Center(
                child: InkWell(
                  onTap: () {
                    goToDetails?.call();
                  },
                  child: Text(
                    "Xem chi tiết",
                    style: textTheme.t14M.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            Container(
              height: 42,
              width: 1,
              color: Colors.white,
            ),
            const SizedBox(
              width: 8,
            ),
            GestureDetector(
                onTap: () {
                  //  context.pop(context);
                },
                child: SvgPicture.asset(Assets.icon.closeAction,
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn))),
          ],
        ),
        backgroundColor: Colors.green,
        borderRadius: BorderRadius.circular(16),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(8),
        flushbarPosition: FlushbarPosition.TOP,
      )..show(this);
}

// Future<void> showDialogAuthorization() {
//   return showDialog<void>(
//     context: GetIt.instance<NavigationService>().navigatorContext,
//     barrierDismissible: false,
//     builder: (BuildContext _) {
//       return AlertDialog(
//         title: Row(children: [
//           const CircleAvatar(
//             radius: 10,
//             backgroundColor: AppColors.startBtnColor,
//             child: Icon(
//               Icons.question_mark,
//               color: AppColors.whiteColor,
//               size: 15,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Text(
//             S.current.warning_sub_emtyp_vehicle_title,
//             style:
//                 PrimaryFont.medium(15).copyWith(color: AppColors.startBtnColor),
//           ),
//         ]),
//         content: Text(
//           S.current.warning_sub_emtyp_vehicle_content,
//           style: PrimaryFont.medium(15).copyWith(color: AppColors.greyColor),
//         ),
//         actions: <Widget>[
//           Center(
//             child: BaseButton(
//                 ontap: () {
//                   Navigator.of(
//                           GetIt.instance<NavigationService>().navigatorContext)
//                       .pop();
//                   Navigator.of(
//                           GetIt.instance<NavigationService>().navigatorContext)
//                       .pop();
//                 },
//                 text: 'Ok'),
//           )
//         ],
//       );
//     },
//   );
// }
