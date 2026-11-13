import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Phones stay portrait (the writing pad is laid out for it); tablets rotate.
  // Not awaited: nothing may delay runApp.
  final view = PlatformDispatcher.instance.views.first;
  if (view.physicalSize.shortestSide / view.devicePixelRatio < 600) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  runApp(const ProviderScope(child: App()));
}
