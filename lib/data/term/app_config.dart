// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

class AppConfig {
  AppConfig._();
  static const phoneNumber = "0912834422";
  static const emailDefault = "ibme.lab@gmail.com";
  static const linkWebSite = "https://lab.ibme.edu.vn";
  static const SL_USERNAME = "SL_USERNAME";
  static const SL_PASSWORD = "SL_PASSWORD";
  static const SL_REMEMBER_PASSWORD = "SL_REMEMBER_PASSWORD";
  static const isFingerPrint = "isFingerPrint";
  static const fingerPrintEmail = "fingerPrintEmail";
  static const fingerPrintPassword = "fingerPrintPassword";
  static const username = "username";
  static const password = "password";
}

extension GetOrientation on BuildContext {
  Orientation get orientation => MediaQuery.of(this).orientation;
}

extension GetSize on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
}
