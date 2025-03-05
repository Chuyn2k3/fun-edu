import 'package:flutter/material.dart';
//import 'package:fluttertoast/fluttertoast.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
Future showDialogCustomize(
    BuildContext context, AlertType alerType, String desc) {
  return Alert(
    context: context,
    type: alerType,
    desc: desc,
    style: const AlertStyle(descStyle: TextStyle(fontSize: 15)),
    buttons: [
      DialogButton(
        onPressed: () => Navigator.pop(context),
        width: 120,
        child: const Text(
          "Xác nhận",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      )
    ],
  ).show();
}
// Future showToast(String infor) {
//   return Fluttertoast.showToast(
//       msg: infor,
//       toastLength: Toast.LENGTH_SHORT,
//       gravity: ToastGravity.TOP,
//       timeInSecForIosWeb: 1,
//       backgroundColor: Colors.red,
//       textColor: Colors.white,
//       fontSize: 16.0);
// }